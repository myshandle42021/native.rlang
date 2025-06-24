// utils/learning.ts
// Infrastructure-only utilities for Learning Engine - NO business logic

import { db } from "./db";
import { RLangContext } from "../schema/types";
import crypto from "crypto";

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  if (typeof error === "string") {
    return error;
  }
  if (error && typeof error === "object" && "message" in error) {
    return String((error as any).message);
  }
  return String(error);
}

// INFRASTRUCTURE ONLY - Data storage and retrieval

export async function storeLearningEvent(args: any, context: RLangContext) {
  const learningEvent = {
    agent_id: args.agent_id || context.agentId,
    operation_name: args.operation_name,
    input_hash: args.input_hash,
    success: args.success,
    performance_metrics: args.performance_metrics,
    context_data: args.context_data,
    learned_patterns: args.learned_patterns || [],
    execution_duration_ms: args.execution_duration_ms,
    memory_usage_mb: args.memory_usage_mb,
    error_details: args.error_details,
    timestamp: args.timestamp || new Date().toISOString(),
    learning_cycle: args.learning_cycle || 0,
  };

  // CRITICAL FIX: Single database insert with proper return value handling
  const { data, error } = await db
    .from("learning_events")
    .insert(learningEvent);
  if (error)
    throw new Error(`Learning event storage failed: ${getErrorMessage(error)}`);

  // CRITICAL FIX: Access id from returned data array
  return { stored: true, event_id: data?.[0]?.id };
}

export async function queryLearningEvents(args: any, context: RLangContext) {
  let query = db.from("learning_events").select("*");

  if (args.agent_id) query = query.eq("agent_id", args.agent_id);
  if (args.since) query = query.gte("timestamp", args.since);
  if (args.success !== undefined) query = query.eq("success", args.success);
  if (args.operation_name)
    query = query.eq("operation_name", args.operation_name);
  if (args.learning_cycle)
    query = query.eq("learning_cycle", args.learning_cycle);
  if (args.limit) query = query.limit(args.limit);

  query = query.order("timestamp", { ascending: false });

  const { data, error } = await query;
  if (error)
    throw new Error(`Learning events query failed: ${getErrorMessage(error)}`);

  return data || [];
}

export async function storeAgentPattern(args: any, context: RLangContext) {
  const pattern = {
    pattern_type: args.pattern_type,
    pattern_data: args.pattern_data,
    discovered_by: args.discovered_by || context.agentId,
    applicable_to: args.applicable_to || [],
    success_rate: args.success_rate || 0.0,
    usage_count: args.usage_count || 0,
    confidence_score: args.confidence_score || 0.0,
    last_validated: new Date().toISOString(),
    created_at: new Date().toISOString(),
  };

  // CRITICAL FIX: Proper database insert with return value handling
  const { data, error } = await db.from("agent_patterns").insert(pattern);
  if (error)
    throw new Error(`Pattern storage failed: ${getErrorMessage(error)}`);

  // CRITICAL FIX: Access id from returned data array (line 68 issue)
  return { stored: true, pattern_id: data?.[0]?.id };
}

export async function queryAgentPatterns(args: any, context: RLangContext) {
  let query = db.from("agent_patterns").select("*");

  if (args.pattern_type) query = query.eq("pattern_type", args.pattern_type);
  if (args.discovered_by) query = query.eq("discovered_by", args.discovered_by);
  if (args.applicable_to)
    query = query.contains("applicable_to", [args.applicable_to]);
  if (args.min_confidence)
    query = query.gte("confidence_score", args.min_confidence);
  if (args.limit) query = query.limit(args.limit);

  query = query.order("confidence_score", { ascending: false });

  const { data, error } = await query;
  if (error) throw new Error(`Pattern query failed: ${getErrorMessage(error)}`);

  return data || [];
}

export async function storeOptimizationHistory(
  args: any,
  context: RLangContext,
) {
  const optimization = {
    agent_id: args.agent_id,
    optimization_type: args.optimization_type,
    before_metrics: args.before_metrics,
    after_metrics: args.after_metrics,
    improvement_score: args.improvement_score,
    applied_patterns: args.applied_patterns || [],
    rollback_available: args.rollback_available !== false,
    created_at: new Date().toISOString(),
  };

  // CRITICAL FIX: Proper database insert with return value handling
  const { data, error } = await db
    .from("optimization_history")
    .insert(optimization);
  if (error)
    throw new Error(
      `Optimization history storage failed: ${getErrorMessage(error)}`,
    );

  // CRITICAL FIX: Access id from returned data array (line 109 issue)
  return { stored: true, optimization_id: data?.[0]?.id };
}

export async function storeKnowledgeTransfer(args: any, context: RLangContext) {
  const transfer = {
    source_agent: args.source_agent,
    target_agent: args.target_agent,
    pattern_type: args.pattern_type,
    transfer_success: args.transfer_success,
    performance_impact: args.performance_impact,
    confidence_score: args.confidence_score,
    created_at: new Date().toISOString(),
  };

  // CRITICAL FIX: Proper database insert with return value handling
  const { data, error } = await db.from("knowledge_transfers").insert(transfer);
  if (error)
    throw new Error(
      `Knowledge transfer storage failed: ${getErrorMessage(error)}`,
    );

  // CRITICAL FIX: Access id from returned data array (line 127 issue)
  return { stored: true, transfer_id: data?.[0]?.id };
}

// INFRASTRUCTURE ONLY - Hash generation for input patterns
export async function generateInputHash(args: any, context: RLangContext) {
  const input = args.input || args;
  const normalizedInput = JSON.stringify(input, Object.keys(input).sort());
  const hash = crypto
    .createHash("sha256")
    .update(normalizedInput)
    .digest("hex");

  return { hash, input_size: normalizedInput.length };
}

// INFRASTRUCTURE ONLY - Performance measurement utilities
export async function calculatePerformanceMetrics(
  args: any,
  context: RLangContext,
) {
  const startTime = args.start_time;
  const endTime = args.end_time || Date.now();
  const memoryBefore = args.memory_before || 0;
  const memoryAfter = args.memory_after || process.memoryUsage().heapUsed;

  return {
    duration_ms: endTime - startTime,
    memory_mb:
      Math.round(((memoryAfter - memoryBefore) / 1024 / 1024) * 100) / 100,
    timestamp: new Date(endTime).toISOString(),
  };
}

// INFRASTRUCTURE ONLY - Database aggregation helpers
export async function aggregatePerformanceByAgent(
  args: any,
  context: RLangContext,
) {
  const since =
    args.since || new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

  try {
    const { data, error } = await db.query(
      `
      SELECT
        agent_id,
        COUNT(*) as total_operations,
        AVG(CASE WHEN success THEN 1.0 ELSE 0.0 END) as success_rate,
        AVG((performance_metrics->>'duration_ms')::numeric) as avg_duration_ms,
        AVG((performance_metrics->>'memory_mb')::numeric) as avg_memory_mb,
        COUNT(CASE WHEN NOT success THEN 1 END) as error_count
      FROM learning_events
      WHERE timestamp >= $1
      GROUP BY agent_id
      ORDER BY success_rate DESC, avg_duration_ms ASC
    `,
      [since],
    );

    if (error) {
      throw new Error(
        `Performance aggregation failed: ${getErrorMessage(error)}`,
      );
    }
    return data || [];
  } catch (error) {
    // CRITICAL FIX: Handle the catch block error properly (line 186 issue)
    throw new Error(
      `Performance aggregation failed: ${getErrorMessage(error)}`,
    );
  }
}

// INFRASTRUCTURE ONLY - Simple data filtering
export async function filterEventsByPattern(args: any, context: RLangContext) {
  const events = args.events || [];
  const pattern = args.pattern || {};

  return events.filter((event: any) => {
    if (pattern.success !== undefined && event.success !== pattern.success)
      return false;
    if (
      pattern.operation_name &&
      event.operation_name !== pattern.operation_name
    )
      return false;
    if (pattern.agent_id && event.agent_id !== pattern.agent_id) return false;
    if (
      pattern.min_duration &&
      (event.performance_metrics?.duration_ms || 0) < pattern.min_duration
    )
      return false;
    if (
      pattern.max_duration &&
      (event.performance_metrics?.duration_ms || 0) > pattern.max_duration
    )
      return false;
    return true;
  });
}

// INFRASTRUCTURE ONLY - Database cleanup utilities
export async function cleanupOldLearningData(args: any, context: RLangContext) {
  const retentionDays = args.retention_days || 90;
  const cutoffDate = new Date(
    Date.now() - retentionDays * 24 * 60 * 60 * 1000,
  ).toISOString();

  // CRITICAL FIX: Proper database query with await - this was line 270 error
  const { data: deleted, error } = await db
    .from("learning_events")
    .select("*")
    .delete()
    .lt("timestamp", cutoffDate);
  const { data: deleted, error } = await deleteQuery;

  if (error)
    throw new Error(`Learning data cleanup failed: ${getErrorMessage(error)}`);

  return {
    cleaned: true,
    deleted_count: deleted?.length || 0,
    cutoff_date: cutoffDate,
  };
}

// INFRASTRUCTURE ONLY - Database schema validation
export async function validateLearningTables(args: any, context: RLangContext) {
  const requiredTables = [
    "learning_events",
    "agent_patterns",
    "optimization_history",
    "knowledge_transfers",
  ];

  // CRITICAL FIX: Proper typing for results object (line 261, 263 issues)
  const results: Record<string, boolean> = {};

  for (const table of requiredTables) {
    try {
      const { data, error } = await db.query(
        `
        SELECT EXISTS (
          SELECT FROM information_schema.tables
          WHERE table_name = $1
        );
      `,
        [table],
      );

      // CRITICAL FIX: Proper index access with typing
      results[table] = !error && data?.[0]?.exists === true;
    } catch (err) {
      // CRITICAL FIX: Proper index access with typing
      results[table] = false;
    }
  }

  return {
    all_tables_exist: Object.values(results).every((exists) => exists),
    table_status: results,
  };
}
