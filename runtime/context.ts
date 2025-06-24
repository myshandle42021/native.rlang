// runtime/context.ts
// CRITICAL FIX #5: Comprehensive context standardization for consistent agent communication
// Handles all variations of context access patterns across the system

import { RLangContext, TraceEntry } from "../schema/types";

export interface CreateContextOptions {
  agentId?: string;
  clientId?: string;
  operation?: string;
  input?: any;
  user?: string;
  channel?: string;
  memory?: Record<string, any>;
  trace?: TraceEntry[];
  metadata?: Record<string, any>;
  context?: any;
}

/**
 * CRITICAL FIX #5: Enhanced context creation with comprehensive fallbacks
 * Handles all variations of context access patterns across the system
 */
export function createContext(
  options: CreateContextOptions | Partial<RLangContext> = {},
): RLangContext {
  // Extract user info from all possible locations
  const user = extractUserInfo(options);
  const channel = extractChannelInfo(options);
  const clientId = extractClientId(options);
  const agentId = extractAgentId(options);
  const operation = extractOperation(options);

  // Create execution metadata
  const now = new Date().toISOString();
  const executionId = generateExecutionId();

  // Create standardized input object that supports all access patterns
  const standardizedInput = {
    // Direct access patterns
    user: user,
    channel: channel,
    client_id: clientId,
    agent_id: agentId,

    // Legacy patterns from options.input
    ...options.input,

    // Override with extracted values if they exist
    ...(user !== "system" && { user }),
    ...(channel && { channel }),
    ...(clientId !== "default" && { client_id: clientId }),
    ...(agentId !== "unknown" && { agent_id: agentId }),
  };

  // Create comprehensive memory object
  const standardizedMemory = {
    // Standard memory slots
    timestamp: now,
    execution_id: executionId,

    // Include all input data in memory for backward compatibility
    ...standardizedInput,

    // Merge in provided memory (takes precedence)
    ...options.memory,
  };

  return {
    // Primary context fields with fallbacks
    user: user,
    channel: channel,
    clientId: clientId,
    agentId: agentId,
    operation: operation,
    timestamp: now,

    // Standardized input that supports both access patterns:
    // - context.input.user (new pattern)
    // - context.user (direct pattern)
    input: standardizedInput,

    // Comprehensive memory with execution context
    memory: standardizedMemory,

    // Tracing and debugging
    trace: options.trace || [],

    // Additional context data
    metadata: {
      execution_id: executionId,
      created_at: now,
      context_version: "2.0",
      ...options.metadata,
    },

    // Support for nested context patterns (some agents expect this)
    context: {
      user: user,
      clientId: clientId,
      agentId: agentId,
      ...options.context,
    },

    // Preserve any additional fields that might be needed
    ...extractAdditionalFields(options),
  };
}

/**
 * Extract user information from various possible locations
 */
function extractUserInfo(options: any): string {
  return (
    options.user ||
    options.input?.user ||
    options.input?.user_id ||
    options.input?.userId ||
    options.context?.user ||
    options.metadata?.user ||
    "system"
  );
}

/**
 * Extract channel information from various possible locations
 */
function extractChannelInfo(options: any): string | undefined {
  return (
    options.channel ||
    options.input?.channel ||
    options.input?.channel_id ||
    options.input?.channelId ||
    options.context?.channel ||
    options.metadata?.channel ||
    undefined
  );
}

/**
 * Extract client ID from various possible locations
 */
function extractClientId(options: any): string {
  return (
    options.clientId ||
    options.input?.client_id ||
    options.input?.clientId ||
    options.context?.client_id ||
    options.context?.clientId ||
    options.metadata?.client_id ||
    "default"
  );
}

/**
 * Extract agent ID from various possible locations
 */
function extractAgentId(options: any): string {
  return (
    options.agentId ||
    options.input?.agent_id ||
    options.input?.agentId ||
    options.context?.agent_id ||
    options.context?.agentId ||
    options.metadata?.agent_id ||
    "unknown"
  );
}

/**
 * Extract operation from various possible locations
 */
function extractOperation(options: any): string {
  return (
    options.operation ||
    options.input?.operation ||
    options.context?.operation ||
    "default"
  );
}

/**
 * Extract additional fields that should be preserved
 */
function extractAdditionalFields(options: any): Record<string, any> {
  const standardFields = new Set([
    "user",
    "channel",
    "clientId",
    "agentId",
    "input",
    "memory",
    "operation",
    "timestamp",
    "trace",
    "metadata",
    "context",
  ]);

  const additionalFields: Record<string, any> = {};

  for (const [key, value] of Object.entries(options)) {
    if (!standardFields.has(key) && value !== undefined) {
      additionalFields[key] = value;
    }
  }

  return additionalFields;
}

/**
 * Enhanced context creation for specific use cases
 */
export function createAgentContext(
  agentId: string,
  operation: string,
  input: any = {},
  baseContext?: Partial<RLangContext>,
): RLangContext {
  return createContext({
    ...baseContext,
    agentId,
    operation,
    input: {
      ...baseContext?.input,
      ...input,
      agent_id: agentId,
    },
  });
}

/**
 * Create context for system operations
 */
export function createSystemContext(
  operation: string,
  input: any = {},
  clientId?: string,
): RLangContext {
  return createContext({
    agentId: "rol3-main-system",
    user: "system",
    clientId: clientId || "system",
    operation,
    input: {
      ...input,
      user: "system",
      client_id: clientId || "system",
    },
  });
}

/**
 * Create context for user interactions
 */
export function createUserContext(
  user: string,
  channel: string,
  operation: string = "default",
  input: any = {},
  clientId?: string,
): RLangContext {
  return createContext({
    user,
    channel,
    clientId: clientId || "default",
    agentId: "user-interaction",
    operation,
    input: {
      ...input,
      user,
      channel,
      client_id: clientId || "default",
    },
  });
}

/**
 * Create context for RocketChat interactions
 */
export function createRocketChatContext(
  agentId: string,
  operation: string,
  rocketChatData: {
    userId: string;
    username?: string;
    channel: string;
    messageId?: string;
    text?: string;
    button?: string;
    context?: any;
  },
): RLangContext {
  return createContext({
    agentId,
    operation,
    user: rocketChatData.userId,
    channel: rocketChatData.channel,
    input: {
      type: rocketChatData.button ? "button_response" : "message",
      userId: rocketChatData.userId,
      username: rocketChatData.username,
      channel: rocketChatData.channel,
      messageId: rocketChatData.messageId,
      text: rocketChatData.text,
      button: rocketChatData.button,
      context: rocketChatData.context,
    },
  });
}

/**
 * Merge contexts while preserving data integrity
 */
export function mergeContexts(
  base: RLangContext,
  updates: Partial<RLangContext>,
): RLangContext {
  return createContext({
    ...base,
    ...updates,
    input: {
      ...base.input,
      ...updates.input,
    },
    memory: {
      ...base.memory,
      ...updates.memory,
    },
    metadata: {
      ...base.metadata,
      ...updates.metadata,
    },
  });
}

/**
 * Extend context with new data (legacy compatibility)
 */
export function extendContext(
  baseContext: RLangContext,
  updates: Partial<RLangContext>,
): RLangContext {
  return mergeContexts(baseContext, {
    ...updates,
    trace: [...baseContext.trace, ...(updates.trace || [])],
  });
}

/**
 * Add entry to execution trace
 */
export function addToTrace(
  context: RLangContext,
  entry: Omit<TraceEntry, "timestamp">,
): RLangContext {
  const traceEntry: TraceEntry = {
    ...entry,
    timestamp: new Date().toISOString(),
  };

  return {
    ...context,
    trace: [...context.trace, traceEntry],
  };
}

/**
 * Update memory with new value
 */
export function updateMemory(
  context: RLangContext,
  key: string,
  value: any,
): RLangContext {
  return {
    ...context,
    memory: {
      ...context.memory,
      [key]: value,
    },
    // Also update input for dual access compatibility
    input: {
      ...context.input,
      [key]: value,
    },
  };
}

/**
 * Get value from memory with fallback
 */
export function getFromMemory(
  context: RLangContext,
  key: string,
  defaultValue?: any,
): any {
  return context.memory[key] ?? defaultValue;
}

/**
 * Validate context has required fields for operation
 */
export function validateContext(
  context: RLangContext,
  requiredFields: string[] = [],
): { valid: boolean; missing: string[]; errors: string[] } {
  const missing: string[] = [];
  const errors: string[] = [];

  // Check required fields
  for (const field of requiredFields) {
    // Check both direct access and input access patterns
    const hasDirectAccess = context[field as keyof RLangContext] !== undefined;
    const hasInputAccess = context.input?.[field] !== undefined;
    const hasMemoryAccess = context.memory?.[field] !== undefined;

    if (!hasDirectAccess && !hasInputAccess && !hasMemoryAccess) {
      missing.push(field);
    }
  }

  // Basic context validation
  if (!context.agentId || typeof context.agentId !== "string") {
    errors.push("agentId must be a non-empty string");
  }

  if (!context.operation || typeof context.operation !== "string") {
    errors.push("operation must be a non-empty string");
  }

  if (!context.timestamp || typeof context.timestamp !== "string") {
    errors.push("timestamp must be a valid ISO string");
  }

  if (!context.memory || typeof context.memory !== "object") {
    errors.push("memory must be an object");
  }

  if (!Array.isArray(context.trace)) {
    errors.push("trace must be an array");
  }

  return {
    valid: missing.length === 0 && errors.length === 0,
    missing,
    errors,
  };
}

/**
 * Extract value from context supporting all access patterns
 */
export function getContextValue(
  context: RLangContext,
  key: string,
  defaultValue?: any,
): any {
  // Try direct access first
  const directValue = context[key as keyof RLangContext];
  if (directValue !== undefined) {
    return directValue;
  }

  // Try input access
  const inputValue = context.input?.[key];
  if (inputValue !== undefined) {
    return inputValue;
  }

  // Try memory access
  const memoryValue = context.memory?.[key];
  if (memoryValue !== undefined) {
    return memoryValue;
  }

  // Try nested access patterns
  const metadataValue = context.metadata?.[key];
  if (metadataValue !== undefined) {
    return metadataValue;
  }

  const nestedContextValue = context.context?.[key];
  if (nestedContextValue !== undefined) {
    return nestedContextValue;
  }

  return defaultValue;
}

/**
 * Set value in context ensuring all access patterns work
 */
export function setContextValue(
  context: RLangContext,
  key: string,
  value: any,
): RLangContext {
  return {
    ...context,
    [key]: value,
    input: {
      ...context.input,
      [key]: value,
    },
    memory: {
      ...context.memory,
      [key]: value,
    },
  };
}

/**
 * Context utilities for specific data types
 */
export function getRequestData(context: RLangContext) {
  return {
    type: getContextValue(context, "type", "unknown"),
    user: getContextValue(context, "user"),
    channel: getContextValue(context, "channel"),
    text:
      getContextValue(context, "text") || getContextValue(context, "message"),
    button: getContextValue(context, "button"),
    context: getContextValue(context, "context"),
  };
}

export function getRocketChatContext(context: RLangContext) {
  return {
    userId:
      getContextValue(context, "user") || getContextValue(context, "userId"),
    username: getContextValue(context, "username"),
    channel: getContextValue(context, "channel"),
    messageId: getContextValue(context, "messageId"),
    threadId: getContextValue(context, "threadId"),
  };
}

export function getXeroContext(context: RLangContext) {
  return {
    tenantId: context.clientId,
    accessToken: getContextValue(context, "xero_token"),
    refreshToken: getContextValue(context, "xero_refresh_token"),
    connectionId: getContextValue(context, "xero_connection_id"),
  };
}

/**
 * Context serialization for persistence
 */
export function serializeContext(context: RLangContext): string {
  return JSON.stringify({
    agentId: context.agentId,
    clientId: context.clientId,
    operation: context.operation,
    input: context.input,
    memory: context.memory,
    timestamp: context.timestamp,
    user: context.user,
    channel: context.channel,
    metadata: context.metadata,
    // Don't serialize trace - it can be large and is usually logged separately
    traceLength: context.trace.length,
  });
}

export function deserializeContext(serialized: string): RLangContext {
  const data = JSON.parse(serialized);
  return createContext({
    agentId: data.agentId,
    clientId: data.clientId,
    operation: data.operation,
    input: data.input,
    memory: data.memory,
    user: data.user,
    channel: data.channel,
    metadata: data.metadata,
  });
}

// Generate unique execution ID
function generateExecutionId(): string {
  const timestamp = Date.now().toString(36);
  const randomPart = Math.random().toString(36).substring(2, 8);
  return `exec_${timestamp}_${randomPart}`;
}
