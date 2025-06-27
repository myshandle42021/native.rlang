// utils/debug-queries.ts
// Database query layer for auto-debug system
// Extracts error patterns and system health metrics from existing RCD tables

import { db } from "./db";

export interface ErrorPattern {
  id: string;
  error_type: string;
  frequency: number;
  first_seen: Date;
  last_seen: Date;
  affected_agents: string[];
  error_details: any;
  context_patterns: any;
  severity: "critical" | "warning" | "info";
}

export interface SystemMetrics {
  total_events: number;
  success_rate: number;
  avg_response_time: number;
  error_frequency: number;
  agent_performance: Array<{
    agent_id: string;
    success_rate: number;
    avg_response_time: number;
    error_count: number;
  }>;
  top_errors: ErrorPattern[];
}

export interface FailurePattern {
  pattern_type: string;
  description: string;
  occurrences: number;
  impact_score: number;
  suggested_fix: string;
  confidence: number;
}

/**
 * Get recent errors from the agent logs table (where real errors are stored)
 */
export async function getRecentErrors(
  hours: number = 24,
): Promise<ErrorPattern[]> {
  const { data, error } = await db.query(`
    SELECT
      agent_id,
      event as event_type,
      'failure' as outcome,
      data as context_data,
      COUNT(*) as frequency,
      MIN(timestamp) as first_seen,
      MAX(timestamp) as last_seen
    FROM agent_logs
    WHERE
      timestamp >= NOW() - INTERVAL '${hours} hours'
      AND (
        event LIKE '%error%'
        OR event LIKE '%fail%'
        OR event LIKE '%unhealthy%'
        OR event LIKE '%missing%'
        OR data::text LIKE '%error%'
        OR success = false
      )
    GROUP BY agent_id, event, data
    ORDER BY frequency DESC, last_seen DESC
  `);

  if (error) {
    console.error("Failed to fetch recent errors:", error);
    return [];
  }

  return (data || []).map((row: any, index: number) => ({
    id: `error_${index}_${Date.now()}`,
    error_type: row.event_type || "unknown",
    frequency: parseInt(row.frequency) || 1,
    first_seen: new Date(row.first_seen),
    last_seen: new Date(row.last_seen),
    affected_agents: [row.agent_id].filter(Boolean),
    error_details: row.context_data || {},
    context_patterns: row.context_data || {},
    severity: determineSeverity(parseInt(row.frequency), row.event_type),
  }));
}

/**
 * Get comprehensive system health metrics from agent logs
 */
export async function getSystemMetrics(): Promise<SystemMetrics> {
  // Get overall event statistics from agent_logs
  const { data: overallStats, error: statsError } = await db.query(`
    SELECT
      COUNT(*) as total_events,
      AVG(CASE WHEN success = true THEN 1.0 ELSE 0.0 END) as success_rate,
      COUNT(CASE WHEN success = false OR event LIKE '%error%' OR event LIKE '%fail%' THEN 1 END) as error_count
    FROM agent_logs
    WHERE timestamp >= NOW() - INTERVAL '24 hours'
  `);

  // Get agent-specific performance from agent_logs
  const { data: agentStats, error: agentError } = await db.query(`
    SELECT
      agent_id,
      COUNT(*) as total_operations,
      AVG(CASE WHEN success = true THEN 1.0 ELSE 0.0 END) as success_rate,
      COUNT(CASE WHEN success = false OR event LIKE '%error%' OR event LIKE '%fail%' THEN 1 END) as error_count
    FROM agent_logs
    WHERE
      timestamp >= NOW() - INTERVAL '24 hours'
      AND agent_id IS NOT NULL
    GROUP BY agent_id
    ORDER BY error_count DESC, total_operations DESC
  `);

  // Get recent top errors
  const topErrors = await getRecentErrors(24);

  const overall = overallStats?.[0] || {};
  const errorFreq =
    parseFloat(overall.error_count || 0) /
    parseFloat(overall.total_events || 1);

  return {
    total_events: parseInt(overall.total_events) || 0,
    success_rate: parseFloat(overall.success_rate) || 0,
    avg_response_time: 0, // Would need performance_logs table data
    error_frequency: errorFreq,
    agent_performance: (agentStats || []).map((agent: any) => ({
      agent_id: agent.agent_id,
      success_rate: parseFloat(agent.success_rate) || 0,
      avg_response_time: 0, // Would need performance timing data
      error_count: parseInt(agent.error_count) || 0,
    })),
    top_errors: topErrors.slice(0, 10),
  };
}

/**
 * Detect common failure patterns in the agent logs
 */
export async function getFailurePatterns(): Promise<FailurePattern[]> {
  const patterns: FailurePattern[] = [];

  // Pattern 1: Validation errors (your biggest issue!)
  const { data: validationErrors } = await db.query(`
    SELECT COUNT(*) as count, data
    FROM agent_logs
    WHERE
      timestamp >= NOW() - INTERVAL '48 hours'
      AND event = 'validation_error_added'
    GROUP BY data
    ORDER BY count DESC
    LIMIT 10
  `);

  if (validationErrors && validationErrors.length > 0) {
    const totalValidationErrors = validationErrors.reduce(
      (sum: number, row: any) => sum + parseInt(row.count),
      0,
    );
    if (totalValidationErrors > 10) {
      patterns.push({
        pattern_type: "validation_error_spike",
        description: `Massive validation error spike: ${totalValidationErrors} errors in 48h`,
        occurrences: totalValidationErrors,
        impact_score: 0.95,
        suggested_fix:
          "Review bootstrap policies and validation rules - this is critical",
        confidence: 0.98,
      });
    }
  }

  // Pattern 2: Missing modules
  const { data: moduleErrors } = await db.query(`
    SELECT COUNT(*) as count
    FROM agent_logs
    WHERE
      timestamp >= NOW() - INTERVAL '24 hours'
      AND event = 'optional_module_missing'
  `);

  const moduleErrorCount = parseInt(moduleErrors?.[0]?.count) || 0;
  if (moduleErrorCount > 10) {
    patterns.push({
      pattern_type: "missing_module_configuration",
      description: "Multiple optional modules missing",
      occurrences: moduleErrorCount,
      impact_score: 0.6,
      suggested_fix: "Check module dependencies and configuration files",
      confidence: 0.9,
    });
  }

  // Pattern 3: Database health issues
  const { data: dbErrors } = await db.query(`
    SELECT COUNT(*) as count
    FROM agent_logs
    WHERE
      timestamp >= NOW() - INTERVAL '24 hours'
      AND event = 'database_unhealthy'
  `);

  const dbErrorCount = parseInt(dbErrors?.[0]?.count) || 0;
  if (dbErrorCount > 1) {
    patterns.push({
      pattern_type: "database_health_degradation",
      description: "Database health check failures detected",
      occurrences: dbErrorCount,
      impact_score: 0.9,
      suggested_fix: "Check database connection pool and query performance",
      confidence: 0.95,
    });
  }

  // Pattern 4: Agent performance issues
  const { data: agentIssues } = await db.query(`
    SELECT agent_id, COUNT(*) as error_count
    FROM agent_logs
    WHERE
      timestamp >= NOW() - INTERVAL '12 hours'
      AND (success = false OR event LIKE '%error%')
      AND agent_id IS NOT NULL
    GROUP BY agent_id
    HAVING COUNT(*) > 5
    ORDER BY COUNT(*) DESC
  `);

  if (agentIssues && agentIssues.length > 0) {
    const totalAgentErrors = agentIssues.reduce(
      (sum: number, row: any) => sum + parseInt(row.error_count),
      0,
    );
    patterns.push({
      pattern_type: "agent_error_clustering",
      description: `Error clustering in ${agentIssues.length} agents`,
      occurrences: totalAgentErrors,
      impact_score: 0.7,
      suggested_fix: "Review agent configurations and error handling",
      confidence: 0.85,
    });
  }

  return patterns.sort((a, b) => b.impact_score - a.impact_score);
}

/**
 * Get error details for specific time period
 */
export async function getErrorDetails(hours: number = 6): Promise<
  Array<{
    timestamp: Date;
    agent_id: string;
    event_type: string;
    outcome: string;
    context_data: any;
    error_message: string;
  }>
> {
  const { data, error } = await db.query(`
    SELECT
      timestamp,
      agent_id,
      event_type,
      outcome,
      context_data
    FROM rcd_learning_events
    WHERE
      timestamp >= NOW() - INTERVAL '${hours} hours'
      AND outcome != 'success'
    ORDER BY timestamp DESC
    LIMIT 50
  `);

  if (error) {
    console.error("Failed to fetch error details:", error);
    return [];
  }

  return (data || []).map((row: any) => ({
    timestamp: new Date(row.timestamp),
    agent_id: row.agent_id || "unknown",
    event_type: row.event_type || "unknown",
    outcome: row.outcome || "unknown",
    context_data: row.context_data || {},
    error_message: extractErrorMessage(row.context_data),
  }));
}

/**
 * Check database table health
 */
export async function checkTableHealth(): Promise<{
  healthy: boolean;
  tables: Array<{ name: string; exists: boolean; row_count: number }>;
  missing_tables: string[];
}> {
  const expectedTables = [
    "rcd_learning_events",
    "rcd_performance_logs",
    "rcd_agents",
    "rcd_files",
    "rcd_patterns",
    "rcd_capabilities",
  ];

  const results = [];
  const missing = [];

  for (const table of expectedTables) {
    try {
      const { data, error } = await db.query(`
        SELECT COUNT(*) as count
        FROM ${table}
        WHERE timestamp >= NOW() - INTERVAL '24 hours'
      `);

      if (error) {
        missing.push(table);
        results.push({ name: table, exists: false, row_count: 0 });
      } else {
        const count = parseInt(data?.[0]?.count) || 0;
        results.push({ name: table, exists: true, row_count: count });
      }
    } catch (e) {
      missing.push(table);
      results.push({ name: table, exists: false, row_count: 0 });
    }
  }

  return {
    healthy: missing.length === 0,
    tables: results,
    missing_tables: missing,
  };
}

/**
 * Helper function to determine error severity
 */
function determineSeverity(
  frequency: number,
  errorType: string,
): "critical" | "warning" | "info" {
  if (
    frequency > 10 ||
    errorType?.includes("critical") ||
    errorType?.includes("database")
  ) {
    return "critical";
  }
  if (
    frequency > 3 ||
    errorType?.includes("validation") ||
    errorType?.includes("intent")
  ) {
    return "warning";
  }
  return "info";
}

/**
 * Extract human-readable error message from context data
 */
function extractErrorMessage(contextData: any): string {
  if (!contextData) return "No error details available";

  if (typeof contextData === "string") return contextData;

  if (contextData.error) return String(contextData.error);
  if (contextData.message) return String(contextData.message);
  if (contextData.details) return String(contextData.details);

  return JSON.stringify(contextData).slice(0, 200) + "...";
}
