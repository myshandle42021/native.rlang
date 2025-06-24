// utils/rcd.ts - ENHANCED with Parameter Mapping for R-lang Compatibility
// FIXED: Added mapping functions to resolve interface mismatches between R-lang and TypeScript

import { db } from "./db";
import { RLangContext } from "../schema/types";
import * as fs from "fs/promises";
import * as path from "path";
import { createHash } from "crypto";

// Production-ready error type guard
function isError(error: unknown): error is Error {
  return error instanceof Error;
}

function getErrorMessage(error: unknown): string {
  if (isError(error)) return error.message;
  if (typeof error === "string") return error;
  if (error && typeof error === "object" && "message" in error) {
    return String((error as any).message);
  }
  return String(error);
}

// ================================
// CORE DATABASE OPERATIONS (unchanged)
// ================================

export async function query(sql: string, context: RLangContext) {
  const { data, error } = await db.rpc("execute_sql", { sql_query: sql });
  if (error) throw new Error(`SQL query failed: ${getErrorMessage(error)}`);
  return data;
}

export async function execute_sql(sql: string, context: RLangContext) {
  const { data, error } = await db.rpc("execute_sql", { sql_query: sql });
  if (error) throw new Error(`SQL execution failed: ${getErrorMessage(error)}`);
  return { success: true, result: data };
}

export async function executeSQL(args: any, context: RLangContext) {
  const { sql, params = [] } = args;
  const { data, error } = await db.query(sql, params);
  if (error) throw new Error(`SQL execution failed: ${getErrorMessage(error)}`);
  return data;
}

// ================================
// FILE SYSTEM OPERATIONS (what .r cannot do)
// ================================

export async function readFileContent(args: any, context: RLangContext) {
  const { filePath } = args;
  try {
    const content = await fs.readFile(filePath, "utf-8");
    const hash = createHash("sha256").update(content).digest("hex");
    return { content, hash };
  } catch (error) {
    throw new Error(
      `Failed to read file ${filePath}: ${getErrorMessage(error)}`,
    );
  }
}

export async function scanFiles(args: any, context: RLangContext) {
  const { directory = "./", extensions = [".ts", ".r", ".js", ".json"] } = args;

  try {
    const files: any[] = [];

    async function scan(dir: string) {
      const entries = await fs.readdir(dir, { withFileTypes: true });

      for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);

        if (
          entry.isDirectory() &&
          !fullPath.includes("node_modules") &&
          !fullPath.includes(".git")
        ) {
          await scan(fullPath);
        } else if (entry.isFile()) {
          const ext = path.extname(entry.name);
          if (extensions.includes(ext)) {
            files.push({
              path: fullPath,
              name: entry.name,
              extension: ext,
            });
          }
        }
      }
    }

    await scan(directory);
    return files;
  } catch (error) {
    throw new Error(`Directory scan failed: ${getErrorMessage(error)}`);
  }
}

// ================================
// EXISTING CORE RCD FUNCTIONS (unchanged)
// ================================

export async function storeFileMetadata(args: any, context: RLangContext) {
  const { data, error } = await db
    .from("rcd_files")
    .insert(args)
    .on("conflict", "file_path")
    .update({
      ...args,
      updated_at: new Date(),
    });

  if (error)
    throw new Error(`Metadata storage failed: ${getErrorMessage(error)}`);
  return { stored: true, data };
}

export async function queryFileMetadata(args: any, context: RLangContext) {
  let query = db.from("rcd_files").select("*");

  if (args.file_path) query = query.eq("file_path", args.file_path);
  if (args.capability)
    query = query.contains("capabilities", [args.capability]);
  if (args.file_type) query = query.eq("file_type", args.file_type);
  if (args.limit) query = query.limit(args.limit);

  const { data, error } = await query;
  if (error)
    throw new Error(`Metadata query failed: ${getErrorMessage(error)}`);
  return data || [];
}

export async function storePattern(args: any, context: RLangContext) {
  const { data, error } = await db.from("rcd_patterns").insert(args);
  if (error)
    throw new Error(`Pattern storage failed: ${getErrorMessage(error)}`);
  return { stored: true, pattern_id: data?.[0]?.id };
}

export async function queryPatterns(args: any, context: RLangContext) {
  let query = db.from("rcd_patterns").select("*");

  if (args.pattern_type) query = query.eq("pattern_type", args.pattern_type);
  if (args.min_confidence)
    query = query.gte("confidence_score", args.min_confidence);
  if (args.domain) query = query.eq("domain", args.domain);
  if (args.limit) query = query.limit(args.limit);

  query = query.order("confidence_score", { ascending: false });

  const { data, error } = await query;
  if (error) throw new Error(`Pattern query failed: ${getErrorMessage(error)}`);
  return data || [];
}

export async function storeCapability(args: any, context: RLangContext) {
  const { data, error } = await db
    .from("rcd_capabilities")
    .insert(args)
    .on("conflict", "capability_name")
    .update({
      provider_files: args.provider_files,
      usage_frequency: db.raw("usage_frequency + 1"),
      updated_at: new Date(),
    });

  if (error)
    throw new Error(`Capability storage failed: ${getErrorMessage(error)}`);
  return { stored: true, data };
}

export async function queryCapabilities(args: any, context: RLangContext) {
  let query = db.from("rcd_capabilities").select("*");

  if (args.capability_name)
    query = query.eq("capability_name", args.capability_name);
  if (args.category) query = query.eq("category", args.category);
  if (args.min_stability)
    query = query.gte("stability_rating", args.min_stability);
  if (args.status) query = query.eq("status", args.status);
  if (args.compatible_with)
    query = query.contains("compatible_with", [args.compatible_with]);

  const { data, error } = await query;
  if (error)
    throw new Error(`Capability query failed: ${getErrorMessage(error)}`);
  return data || [];
}

export async function storeLearningEvent(args: any, context: RLangContext) {
  const event = {
    agent_id: args.agent_id || context.agentId,
    timestamp: new Date(),
    ...args,
  };

  const { data, error } = await db.from("rcd_learning_events").insert(event);
  if (error)
    throw new Error(`Learning event storage failed: ${getErrorMessage(error)}`);
  return { stored: true, event_id: data?.[0]?.id };
}

// ================================
// ENHANCED AGENT OPERATIONS
// ================================

export async function registerAgent(args: any, context: RLangContext) {
  const { data, error } = await db.from("rcd_agents").insert({
    agent_id: args.agent_id,
    capabilities: args.capabilities,
    relationships: args.relationships,
    performance_baseline: args.performance_baseline,
    learning_focus: args.learning_focus,
    signal_schemas: args.signal_schemas,
    routing_intelligence: args.routing_intelligence,
    registered_at: new Date(),
    status: "active",
  });

  if (error)
    throw new Error(`Agent registration failed: ${getErrorMessage(error)}`);
  return { registered: true, data };
}

export async function queryAgentCapabilities(args: any, context: RLangContext) {
  let query = db.from("rcd_agents").select("*");

  if (args.active_only) query = query.eq("status", "active");
  if (args.capability)
    query = query.contains("capabilities", [args.capability]);

  const { data, error } = await query;
  if (error)
    throw new Error(`Agent capability query failed: ${getErrorMessage(error)}`);
  return data || [];
}

export async function logPerformance(args: any, context: RLangContext) {
  const { data, error } = await db.from("rcd_performance_logs").insert({
    agent_id: args.agent_id || context.agentId,
    operation: args.operation,
    metrics: args.metrics,
    success: args.success,
    timestamp: new Date(),
    context_data: args.context || {},
  });

  if (error)
    throw new Error(`Performance logging failed: ${getErrorMessage(error)}`);
  return { logged: true, log_id: data?.[0]?.id };
}

export async function initializeLearningTracking(
  args: any,
  context: RLangContext,
) {
  const { data, error } = await db.from("rcd_learning_tracking").insert({
    agent_id: args.agent_id,
    learning_patterns: args.learning_patterns,
    tracking_metrics: args.tracking_metrics,
    initialized_at: new Date(),
    active: true,
  });

  if (error)
    throw new Error(
      `Learning tracking initialization failed: ${getErrorMessage(error)}`,
    );
  return { initialized: true, tracking_id: data?.[0]?.id };
}

export async function initializeRoutingSystem(
  args: any,
  context: RLangContext,
) {
  const { data, error } = await db.from("rcd_routing_systems").insert({
    agent_id: args.agent_id,
    learning_patterns: args.learning_patterns,
    routing_algorithms: args.routing_algorithms,
    intelligence_focus: args.intelligence_focus,
    initialized_at: new Date(),
    active: true,
  });

  if (error)
    throw new Error(
      `Routing system initialization failed: ${getErrorMessage(error)}`,
    );
  return { initialized: true, routing_id: data?.[0]?.id };
}

// ================================
// CRITICAL FIX #2: PARAMETER MAPPING FUNCTIONS FOR R-LANG COMPATIBILITY
// ================================

/**
 * CRITICAL FIX #2: Parameter mapping for R-lang capability queries
 * Maps R-lang parameter names to TypeScript expectations
 */
export async function queryCapabilityProviders(
  args: any,
  context: RLangContext,
) {
  // Map R-lang parameters to TypeScript expectations
  const mappedArgs = {
    capability_name: args.capability, // R-lang uses 'capability', TS expects 'capability_name'
    category: args.category,
    min_stability: args.min_performance_score || args.min_stability, // Handle both parameter names
    status: args.status,
    compatible_with: args.compatible_with,
  };

  // Call the existing function with mapped parameters
  return queryCapabilities(mappedArgs, context);
}

/**
 * CRITICAL FIX #2: Parameter mapping for R-lang capability storage
 */
export async function storeCapabilityProvider(
  args: any,
  context: RLangContext,
) {
  // Map R-lang store requests to TypeScript format
  const mappedArgs = {
    capability_name: args.capability, // R-lang uses 'capability'
    provider_files: args.provider_files || [args.provider], // Handle single or array
    category: args.category,
    stability_rating: args.stability_rating || 0.8,
    performance_score: args.performance_score || 0.7,
    interface_spec: args.interface_spec || {},
    description: args.description,
    status: args.status || "active",
    compatible_with: args.compatible_with || [],
    ...args, // Pass through any other args
  };

  return storeCapability(mappedArgs, context);
}

/**
 * CRITICAL FIX #2: Parameter mapping for R-lang learning events
 */
export async function logLearningEvent(args: any, context: RLangContext) {
  // Map learning event parameters
  const mappedArgs = {
    agent_id: args.agent_id || context.agentId,
    event_type: args.event_type,
    context_data: args.context_data,
    outcome: args.outcome || "success",
    impact_score: args.impact_score || 0.0,
    confidence: args.confidence || 0.5,
    patterns_involved: args.patterns_involved || [],
    files_involved: args.files_involved || [],
    duration_ms: args.duration_ms || args.execution_duration_ms,
    error_message: args.error_message || args.error_details,
    operation_name: args.operation_name,
    success: args.success !== undefined ? args.success : true,
    performance_metrics: args.performance_metrics || {},
    learned_patterns: args.learned_patterns || {},
    ...args,
  };

  return storeLearningEvent(mappedArgs, context);
}

/**
 * CRITICAL FIX #2: Parameter mapping for R-lang pattern queries
 */
export async function queryAgentPatterns(args: any, context: RLangContext) {
  // Map R-lang pattern queries
  const mappedArgs = {
    pattern_type: args.pattern_type,
    min_confidence: args.min_confidence_score || args.min_confidence,
    domain: args.domain,
    limit: args.limit || 10,
    discovered_by: args.discovered_by,
    applicable_to: args.applicable_to,
  };

  return queryPatterns(mappedArgs, context);
}

/**
 * CRITICAL FIX #2: Parameter mapping for R-lang file queries
 */
export async function queryRcdFiles(args: any, context: RLangContext) {
  // Map R-lang file query parameters
  const mappedArgs = {
    file_type: args.file_type,
    capabilities: args.capabilities,
    file_path: args.file_pattern || args.file_path, // R-lang may use 'file_pattern'
    client_id: args.client_id,
    min_performance: args.min_performance_score,
  };

  return queryFileMetadata(mappedArgs, context);
}

/**
 * CRITICAL FIX #2: Enhanced file query with pattern support
 */
export async function query_files(args: any, context: RLangContext) {
  let query = db.from("rcd_files").select("*");

  if (args.file_pattern) {
    query = query.ilike("file_path", `%${args.file_pattern}%`);
  }
  if (args.client_id) {
    query = query.ilike("file_path", `%/${args.client_id}/%`);
  }
  if (args.file_type) {
    query = query.eq("file_type", args.file_type);
  }

  const { data, error } = await query.limit(20);
  if (error) throw new Error(`File query failed: ${getErrorMessage(error)}`);

  // Return resolved path for first match if looking for specific file
  if (args.file_pattern && data && data.length > 0) {
    return { resolved_path: data[0].file_path, files: data };
  }

  return { files: data || [] };
}

/**
 * CRITICAL FIX #2: Unified interface for cache operations
 */
export async function logCachePerformance(args: any, context: RLangContext) {
  const event = {
    event_type: `cache_${args.type}`, // cache_hit, cache_miss
    context_data: {
      cache_type: args.type,
      capability: args.capability,
      provider: args.provider,
      response_time: args.response_time,
    },
    impact_score: args.type === "hit" ? 0.1 : -0.1, // Cache hits are good
    outcome: "success",
  };

  return storeLearningEvent(event, context);
}

/**
 * CRITICAL FIX #2: Unified interface for resolution logging
 */
export async function logResolution(args: any, context: RLangContext) {
  const event = {
    event_type: "capability_resolved",
    context_data: {
      capability: args.capability,
      provider: args.provider,
      resolution_time: args.resolution_time,
      cache_status: args.cache_miss ? "miss" : "hit",
    },
    impact_score: args.resolution_time < 100 ? 0.2 : 0.0, // Fast resolution is good
    duration_ms: args.resolution_time,
    outcome: "success",
  };

  return storeLearningEvent(event, context);
}

/**
 * CRITICAL FIX #2: Database table creation/verification
 */
export async function createTables(args: any, context: RLangContext) {
  // Verify all expected RCD tables exist
  const { data, error } = await db.query(`
    SELECT table_name
    FROM information_schema.tables
    WHERE table_name LIKE 'rcd_%'
  `);

  if (error) throw new Error(`Table check failed: ${getErrorMessage(error)}`);

  const expectedTables = [
    "rcd_files",
    "rcd_patterns",
    "rcd_capabilities",
    "rcd_learning_events",
    "rcd_agents",
    "rcd_performance_logs",
    "rcd_agent_patterns",
    "rcd_optimization_history",
    "rcd_knowledge_transfers",
  ];

  const existingTables = data?.map((row: any) => row.table_name) || [];
  const missingTables = expectedTables.filter(
    (table) => !existingTables.includes(table),
  );

  if (missingTables.length > 0) {
    throw new Error(
      `Missing RCD tables: ${missingTables.join(", ")}. Please run migrations.`,
    );
  }

  return { tables_ready: true, existing_tables: existingTables };
}

// ================================
// UTILITY HELPER FUNCTIONS
// ================================

function parseTimeWindow(timeWindow: string): number {
  const units = { h: 3600000, d: 86400000, m: 60000, s: 1000 };
  const match = timeWindow.match(/^-?(\d+)([hdms])$/);

  if (!match) throw new Error(`Invalid time window format: ${timeWindow}`);

  const [, value, unit] = match;
  return parseInt(value) * units[unit as keyof typeof units];
}

// ================================
// ALIAS FUNCTIONS FOR BACKWARDS COMPATIBILITY
// ================================

// Critical aliases to maintain compatibility with R-lang calls
export const write = storeFileMetadata;
export const read = queryFileMetadata;
export const log_learning_event = logLearningEvent;
export const query_capability_providers = queryCapabilityProviders;
export const store_capability = storeCapabilityProvider;
export const log_cache_performance = logCachePerformance;
export const log_resolution = logResolution;
export const query_agent_patterns = queryAgentPatterns;
export const query_rcd_files = queryRcdFiles;

// Additional compatibility aliases
export const store_capability_provider = storeCapabilityProvider;
export const store_file_metadata = storeFileMetadata;
export const query_file_metadata = queryFileMetadata;
export const store_learning_event = storeLearningEvent;
export const register_agent = registerAgent;
export const log_performance = logPerformance;
export const initialize_learning_tracking = initializeLearningTracking;
export const initialize_routing_system = initializeRoutingSystem;
