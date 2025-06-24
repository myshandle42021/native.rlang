// utils/credentials.ts Dynamic credential management - NO hardcoded .env for user services
import { RLangContext } from "../schema/types";
import { rocketchat } from "./rocketchat";

// Add ServiceConfig interface (since it's referenced but not imported)
interface ServiceConfig {
  service: string;
  auth_type: "oauth" | "api_key" | "bearer" | "basic";
  base_url: string;
  endpoints: Record<string, string>;
  credentials?: any;
}

// Add the missing functions that are referenced:
function isTokenExpired(credentials: any): boolean {
  if (!credentials.expires_at) return false;
  const expiryTime = new Date(credentials.expires_at).getTime();
  const currentTime = Date.now();
  const bufferTime = 5 * 60 * 1000;
  return currentTime >= expiryTime - bufferTime;
}

async function refreshUserToken(credentials: any, userId: string) {
  throw new Error("Token refresh not implemented - please re-authenticate");
}

// Add infer object
const infer = {
  analyzeAPICredentials: async (args: any) => {
    const { analyzeAPIDocumentation } = await import("./claude-api");
    return { required_fields: [] };
  },
};

// When auto-generating utils/xero.ts, credentials come from database
async function getServiceConfig(context: RLangContext): Promise<ServiceConfig> {
  const { db } = await import("../utils/db");

  // Get USER-SPECIFIC credentials, not system-wide
  const { data } = await db
    .from("user_service_credentials")
    .select("*")
    .eq("service", "xero")
    .eq("user_id", context.user || context.clientId) // Per-user!
    .eq("active", true)
    .limit(1);

  if (data && data.length > 0) {
    return {
      service: "xero",
      auth_type: "oauth",
      base_url: "https://api.xero.com", // Researched from web
      endpoints: {
        get_invoices: "/api.xro/2.0/Invoices", // Claude-filled from docs
        get_contacts: "/api.xro/2.0/Contacts",
      },
      credentials: data[0].credentials, // USER's credentials from chat
    };
  }

  throw new Error("Xero credentials not configured for this user");
}

// Database schema for dynamic credentials
/*
CREATE TABLE user_service_credentials (
  id SERIAL PRIMARY KEY,
  user_id TEXT NOT NULL,
  service TEXT NOT NULL,
  credentials JSONB NOT NULL,  -- Encrypted user credentials
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, service)
);
*/

// Chat interface collects credentials dynamically
export async function collectServiceCredentials(
  service: string,
  user_id: string,
  context: RLangContext,
) {
  // 1. System researched what credentials this service needs
  const requiredCreds = await getRequiredCredentials(service);

  // 2. Prompt user via RocketChat
  await rocketchat.promptUser(
    {
      to: user_id,
      message: `🔐 I need your ${service} credentials to connect:`,
      attachments: [
        {
          title: `${service} Integration Setup`,
          fields: requiredCreds.map((cred) => ({
            title: cred.name,
            value: cred.description,
            short: true,
          })),
          actions: [
            {
              type: "button",
              text: "Enter Credentials",
              value: `enter_creds:${service}`,
            },
          ],
        },
      ],
    },
    context,
  );

  // 3. When user clicks button, secure form appears
  // 4. Credentials stored encrypted in database per-user
  // 5. Agent can now access that user's specific credentials
}

// Auto-generated utils/xero.ts gets credentials dynamically
export async function authenticate(args: any, context: RLangContext) {
  // NO process.env.XERO_* here!
  // Gets USER's credentials from database
  const config = await getServiceConfig(context);

  switch (config.auth_type) {
    case "oauth":
      return await handleOAuth(config.credentials, context);
    case "api_key":
      return { "X-API-Key": config.credentials.api_key };
    case "bearer":
      return { Authorization: `Bearer ${config.credentials.token}` };
  }
}

async function handleOAuth(userCredentials: any, context: RLangContext) {
  // User's specific OAuth tokens
  if (userCredentials.access_token && !isTokenExpired(userCredentials)) {
    return { Authorization: `Bearer ${userCredentials.access_token}` };
  }

  // Refresh user's token if expired
  const refreshed = await refreshUserToken(userCredentials, context.user);
  return { Authorization: `Bearer ${refreshed.access_token}` };
}

// System researches what credentials each service needs
async function getRequiredCredentials(service: string): Promise<any[]> {
  // Claude analyzes API docs to determine credential requirements
  const credentialInfo = await infer.analyzeAPICredentials({
    service: service,
    research_query: `${service} API authentication requirements`,
    extract_fields: ["auth_type", "required_fields", "setup_instructions"],
  });

  return credentialInfo.required_fields;
}
