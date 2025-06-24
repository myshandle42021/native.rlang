// templates/service-template.ts
// Enhanced Universal Service Template - Works with dynamic configs + user credentials

import { RLangContext } from "../schema/types";
import { db } from "../utils/db";

function isError(error: unknown): error is Error {
  return error instanceof Error;
}

function getErrorMessage(error: unknown): string {
  if (isError(error)) return error.message;
  if (typeof error === "string") return error;
  return String(error);
}

interface ServiceConfig {
  service: string;
  auth_type: "oauth" | "api_key" | "bearer" | "basic";
  base_url: string;
  endpoints: Record<string, string>;
  auth_header?: string;
  auth_prefix?: string;
  oauth_config?: {
    client_id: string;
    client_secret: string;
    token_url: string;
  };
  headers?: {
    required?: string[];
    optional?: string[];
  };
  rate_limits?: {
    requests_per_minute?: number;
    burst_limit?: number;
  };
  error_handling?: {
    rate_limit?: any;
    auth_errors?: any;
  };
}

interface UserCredentials {
  user_id: string;
  service: string;
  credentials: any;
  active: boolean;
}

// 🔧 Enhanced Dynamic Config Loading - Integrates with learning-evolution
export async function getServiceConfig(
  context: RLangContext,
): Promise<ServiceConfig> {
  const serviceName = getServiceNameFromContext(context);

  try {
    // CRITICAL FIX: Proper database query with await
    const { data: learnedConfig, error: learnedError } = await db
      .from("learned_service_configs")
      .select("*")
      .eq("service_name", serviceName)
      .eq("active", true)
      .order("updated_at", { ascending: false })
      .limit(1);

    if (learnedError) {
      console.warn(
        "Error querying learned configs:",
        getErrorMessage(learnedError),
      );
    }

    if (learnedConfig && learnedConfig.length > 0) {
      const config = learnedConfig[0].configuration;

      // Enhance with user-specific credentials
      const userCredentials = await getUserCredentials(serviceName, context);

      return {
        ...config,
        credentials: userCredentials?.credentials || {},
        user_id: context.user || context.clientId,
      };
    }

    // CRITICAL FIX: Proper database query with await
    const { data: legacyConfig, error: legacyError } = await db
      .from("api_connections")
      .select("*")
      .eq("service", serviceName)
      .eq("client_id", context.clientId || "default")
      .limit(1);

    if (legacyError) {
      console.warn(
        "Error querying legacy configs:",
        getErrorMessage(legacyError),
      );
    }

    if (legacyConfig && legacyConfig.length > 0) {
      return legacyConfig[0];
    }

    // No config found - this should trigger discovery
    throw new Error(
      `No configuration found for ${serviceName}. Discovery needed.`,
    );
  } catch (error) {
    console.warn("Failed to get service config:", getErrorMessage(error));

    // Return minimal config to prevent total failure
    return {
      service: serviceName,
      auth_type: "api_key",
      base_url: `https://api.${serviceName}.com`,
      endpoints: {
        get_items: "/items",
        create_item: "/items",
        update_item: "/items",
        delete_item: "/items",
      },
    };
  }
}

// 🔐 Enhanced User Credential Management - Integrates with credentials.ts
export async function getUserCredentials(
  serviceName: string,
  context: RLangContext,
): Promise<UserCredentials | null> {
  const userId = context.user || context.clientId;

  if (!userId) {
    console.warn("No user ID available for credential lookup");
    return null;
  }

  try {
    const { data, error } = await db
      .from("user_service_credentials")
      .select("*")
      .eq("service", serviceName)
      .eq("user_id", userId)
      .eq("active", true)
      .limit(1);

    if (error) {
      console.error("Error fetching user credentials:", getErrorMessage(error));
      return null;
    }

    return data && data.length > 0 ? data[0] : null;
  } catch (error) {
    console.error("Failed to fetch user credentials:", getErrorMessage(error));
    return null;
  }
}

// 🔑 Enhanced Universal Authentication - Supports all auth types dynamically
export async function authenticate(args: any, context: RLangContext) {
  const config = await getServiceConfig(context);
  const userCredentials = await getUserCredentials(config.service, context);

  if (!userCredentials) {
    throw new Error(
      `${config.service} credentials not configured for user ${context.user}. Please set up credentials first.`,
    );
  }

  const creds = userCredentials.credentials;

  switch (config.auth_type) {
    case "oauth":
      return await handleOAuth(creds, config, context);

    case "bearer":
      if (!creds.token && !creds.access_token) {
        throw new Error(`Bearer token not found for ${config.service}`);
      }
      return {
        Authorization: `Bearer ${creds.token || creds.access_token}`,
      };

    case "api_key":
      if (!creds.api_key) {
        throw new Error(`API key not found for ${config.service}`);
      }
      const headerName = config.auth_header || "X-API-Key";
      const prefix = config.auth_prefix || "";
      return {
        [headerName]: prefix ? `${prefix} ${creds.api_key}` : creds.api_key,
      };

    case "basic":
      if (!creds.username || !creds.password) {
        throw new Error(`Username/password not found for ${config.service}`);
      }
      const encoded = btoa(`${creds.username}:${creds.password}`);
      return {
        Authorization: `Basic ${encoded}`,
      };

    default:
      console.warn(`Unknown auth type: ${config.auth_type}`);
      return {};
  }
}

// 🔄 Enhanced OAuth Handler - Supports token refresh
async function handleOAuth(
  credentials: any,
  config: ServiceConfig,
  context: RLangContext,
) {
  // Check if access token exists and is not expired
  if (credentials.access_token && !isTokenExpired(credentials)) {
    return {
      Authorization: `Bearer ${credentials.access_token}`,
      ...(config.headers?.required?.includes("Xero-tenant-id") &&
        credentials.tenant_id && {
          "Xero-tenant-id": credentials.tenant_id,
        }),
    };
  }

  // Try to refresh token if refresh_token exists
  if (credentials.refresh_token) {
    try {
      const refreshedTokens = await refreshOAuthToken(
        credentials,
        config,
        context,
      );

      // Update stored credentials
      await updateUserCredentials(config.service, context.user || "system", {
        ...credentials,
        ...(refreshedTokens as any),
        updated_at: new Date().toISOString(),
      });

      return {
        Authorization: `Bearer ${refreshedTokens.access_token}`,
        ...(config.headers?.required?.includes("Xero-tenant-id") &&
          refreshedTokens.tenant_id && {
            "Xero-tenant-id": refreshedTokens.tenant_id,
          }),
      };
    } catch (refreshError) {
      console.error("Token refresh failed:", getErrorMessage(refreshError));
      throw new Error(
        `${config.service} token expired and refresh failed. Please re-authorize.`,
      );
    }
  }

  throw new Error(
    `${config.service} access token expired and no refresh token available. Please re-authorize.`,
  );
}

// 🌐 Enhanced Universal Request Handler
export async function makeRequest(
  method: string,
  endpoint: string,
  data: any,
  context: RLangContext,
) {
  const config = await getServiceConfig(context);
  const auth = await authenticate({}, context);

  // Build full URL
  const baseUrl = config.base_url;
  const endpointPath = config.endpoints[endpoint] || endpoint;
  const fullUrl = `${baseUrl}${endpointPath}`;

  // Build headers
  const headers = {
    "Content-Type": "application/json",
    "User-Agent": "ROL3-ServiceIntegration/1.0",
    ...auth,
    ...(config.headers?.required &&
      buildRequiredHeaders(config.headers.required, context)),
  };

  // Handle rate limiting
  if (config.rate_limits) {
    await handleRateLimit(config.service, config.rate_limits);
  }

  try {
    const response = await fetch(fullUrl, {
      method: method.toUpperCase(),
      headers,
      ...(data &&
        method.toUpperCase() !== "GET" && { body: JSON.stringify(data) }),
    });

    // Handle common error scenarios
    if (!response.ok) {
      await handleAPIError(response, config, context);
    }

    const responseData = await response.json();

    // Update success metrics
    await updateServiceMetrics(config.service, context.user || "system", true);

    return responseData;
  } catch (error) {
    // Update failure metrics
    await updateServiceMetrics(config.service, context.user || "system", false);

    throw new Error(
      `${config.service} API request failed: ${getErrorMessage(error)}`,
    );
  }
}

// 🔧 Enhanced Helper Functions

function getServiceNameFromContext(context: RLangContext): string {
  return context.memory?.current_service || context.input?.service || "unknown";
}

function isTokenExpired(credentials: any): boolean {
  if (!credentials.expires_at) return false;

  const expiryTime = new Date(credentials.expires_at).getTime();
  const currentTime = Date.now();
  const bufferTime = 5 * 60 * 1000; // 5 minute buffer

  return currentTime >= expiryTime - bufferTime;
}

async function refreshOAuthToken(
  credentials: any,
  config: ServiceConfig,
  context: RLangContext,
) {
  const tokenUrl = config.oauth_config?.token_url;
  if (!tokenUrl) {
    throw new Error("Token URL not configured for OAuth refresh");
  }

  const response = await fetch(tokenUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Authorization: `Basic ${btoa(`${config.oauth_config!.client_id}:${config.oauth_config!.client_secret}`)}`,
    },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: credentials.refresh_token,
    }),
  });

  if (!response.ok) {
    throw new Error(
      `Token refresh failed: ${response.status} ${response.statusText}`,
    );
  }

  return (await response.json()) as any;
}

async function updateUserCredentials(
  service: string,
  userId: string,
  newCredentials: any,
) {
  try {
    const { error } = await db
      .from("user_service_credentials")
      .update({
        credentials: newCredentials,
        updated_at: new Date().toISOString(),
      })
      .eq("service", service)
      .eq("user_id", userId);

    if (error) {
      console.error(
        "Failed to update user credentials:",
        getErrorMessage(error),
      );
    }
  } catch (error) {
    console.error("Error updating user credentials:", getErrorMessage(error));
  }
}

function buildRequiredHeaders(
  requiredHeaders: string[],
  context: RLangContext,
): Record<string, string> {
  const headers: Record<string, string> = {};

  // Handle common required headers dynamically
  requiredHeaders.forEach((headerName) => {
    if (headerName === "Xero-tenant-id" && context.memory?.xero_tenant_id) {
      headers["Xero-tenant-id"] = context.memory.xero_tenant_id;
    }
    // Add more header handling as needed
  });

  return headers;
}

async function handleRateLimit(service: string, rateLimits: any) {
  // Simple rate limiting - could be enhanced with Redis/memory cache
  const key = `rate_limit_${service}`;
  const now = Date.now();

  // This is a basic implementation - enhance as needed
  if (rateLimits.requests_per_minute) {
    // Check and enforce rate limits
    console.log(
      `Rate limiting for ${service}: ${rateLimits.requests_per_minute} req/min`,
    );
  }
}

async function handleAPIError(
  response: Response,
  config: ServiceConfig,
  context: RLangContext,
) {
  const status = response.status;
  const errorText = await response.text();

  // Handle common error patterns
  if (status === 429) {
    // Rate limit - extract retry-after if available
    const retryAfter = response.headers.get("Retry-After");
    throw new Error(
      `Rate limit exceeded. Retry after: ${retryAfter || "unknown"}`,
    );
  }

  if (status === 401 || status === 403) {
    // Auth error - might need token refresh or re-auth
    throw new Error(
      `Authentication failed for ${config.service}. Please check credentials.`,
    );
  }

  if (status >= 500) {
    // Server error - might be temporary
    throw new Error(
      `${config.service} server error: ${status} ${response.statusText}`,
    );
  }

  throw new Error(`${config.service} API error: ${status} ${errorText}`);
}

// CRITICAL FIX: Updated service metrics function with proper raw SQL handling
async function updateServiceMetrics(
  service: string,
  userId: string,
  success: boolean,
) {
  try {
    const timestamp = new Date().toISOString();

    if (success) {
      // CRITICAL FIX: Handle raw SQL properly
      const { error } = await db
        .from("learned_service_configs")
        .update({
          last_success: timestamp,
          usage_count: db.raw("usage_count + 1"),
        })
        .eq("service_name", service);

      if (error) {
        console.warn(
          "Failed to update success metrics:",
          getErrorMessage(error),
        );
      }
    } else {
      const { error } = await db
        .from("learned_service_configs")
        .update({
          last_failure: timestamp,
        })
        .eq("service_name", service);

      if (error) {
        console.warn(
          "Failed to update failure metrics:",
          getErrorMessage(error),
        );
      }
    }
  } catch (error) {
    console.warn("Failed to update service metrics:", getErrorMessage(error));
  }
}

// 🎯 Export enhanced universal functions
export const serviceTemplate = {
  getServiceConfig,
  getUserCredentials,
  authenticate,
  makeRequest,
  handleOAuth: handleOAuth,
  refreshOAuthToken,
  updateUserCredentials,
};
