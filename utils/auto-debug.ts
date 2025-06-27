// utils/auto-debug.ts
// Main orchestration logic for ROL3 Auto-Debug System
// Zero-change integration - only adds new functionality

import {
  getRecentErrors,
  getSystemMetrics,
  getFailurePatterns,
  getErrorDetails,
  checkTableHealth,
  type ErrorPattern,
  type SystemMetrics,
  type FailurePattern,
} from "./debug-queries";

import {
  analyzeErrors,
  generateFixes,
  prioritizeIssues,
  assessSystemHealth,
  type Analysis,
  type Fix,
  type Priority,
} from "./claude-debug";

import { createFixFiles, validateFix, applyFix } from "./fix-generator";

import {
  sendDebugReport,
  formatConsoleReport,
  saveReportFile,
} from "./debug-reporter";

export interface DiagnosticReport {
  timestamp: Date;
  system_health: {
    overall_score: number;
    status: "healthy" | "degraded" | "critical";
    key_metrics: SystemMetrics;
  };
  errors_found: ErrorPattern[];
  failure_patterns: FailurePattern[];
  ai_analysis: Analysis;
  generated_fixes: Fix[];
  priority_order: Priority[];
  recommendations: string[];
  execution_time_ms: number;
}

export interface AutoDebugConfig {
  hours_to_analyze: number;
  min_error_frequency: number;
  claude_analysis: boolean;
  generate_fixes: boolean;
  send_reports: boolean;
  auto_apply_safe_fixes: boolean;
  output_directory: string;
}

const DEFAULT_CONFIG: AutoDebugConfig = {
  hours_to_analyze: 24,
  min_error_frequency: 1,
  claude_analysis: true,
  generate_fixes: true,
  send_reports: true,
  auto_apply_safe_fixes: false,
  output_directory: "./generated-fixes",
};

/**
 * Main diagnostic function - analyzes system and generates report
 */
export async function runDiagnostics(
  config: Partial<AutoDebugConfig> = {},
): Promise<DiagnosticReport> {
  const startTime = Date.now();
  const finalConfig = { ...DEFAULT_CONFIG, ...config };

  console.log("🔍 Starting ROL3 Auto-Debug System...");
  console.log(`📊 Analyzing last ${finalConfig.hours_to_analyze} hours`);

  try {
    // Step 1: Collect raw data from database
    console.log("📥 Collecting error data...");
    const [errors, metrics, patterns, tableHealth] = await Promise.all([
      getRecentErrors(finalConfig.hours_to_analyze),
      getSystemMetrics(),
      getFailurePatterns(),
      checkTableHealth(),
    ]);

    console.log(
      `📋 Found ${errors.length} error patterns, ${patterns.length} failure patterns`,
    );

    // Step 2: AI Analysis (if enabled)
    let analysis: Analysis;
    let systemHealthAssessment;

    if (finalConfig.claude_analysis && errors.length > 0) {
      console.log("🤖 Running AI analysis...");
      try {
        [analysis, systemHealthAssessment] = await Promise.all([
          analyzeErrors(errors),
          assessSystemHealth(metrics),
        ]);
        console.log(
          `💡 AI identified ${analysis.root_causes.length} root causes`,
        );
      } catch (error) {
        console.warn("⚠️ AI analysis failed, using fallback:", error);
        analysis = createFallbackAnalysis(errors, patterns);
        systemHealthAssessment = {
          health_score: 50,
          status: "degraded" as const,
          key_concerns: [],
          recommendations: [],
        };
      }
    } else {
      console.log("📊 Using rule-based analysis (Claude disabled)");
      analysis = createFallbackAnalysis(errors, patterns);
      systemHealthAssessment = {
        health_score: 75,
        status: "healthy" as const,
        key_concerns: [],
        recommendations: [],
      };
    }

    // Step 3: Generate fixes (if enabled)
    let fixes: Fix[] = [];
    if (finalConfig.generate_fixes && analysis.recommended_actions.length > 0) {
      console.log("🔧 Generating fixes...");
      try {
        fixes = await generateFixes(analysis);
        console.log(`🛠️ Generated ${fixes.length} potential fixes`);
      } catch (error) {
        console.warn("⚠️ Fix generation failed:", error);
        fixes = [];
      }
    }

    // Step 4: Prioritize issues
    let priorities: Priority[] = [];
    if (errors.length > 0) {
      try {
        priorities = await prioritizeIssues(errors);
      } catch (error) {
        console.warn("⚠️ Priority analysis failed:", error);
        priorities = createDefaultPriorities(errors);
      }
    }

    // Step 5: Create comprehensive report
    const report: DiagnosticReport = {
      timestamp: new Date(),
      system_health: {
        overall_score: systemHealthAssessment.health_score,
        status: systemHealthAssessment.status,
        key_metrics: metrics,
      },
      errors_found: errors,
      failure_patterns: patterns,
      ai_analysis: analysis,
      generated_fixes: fixes,
      priority_order: priorities,
      recommendations: [
        ...analysis.recommended_actions.map((a) => a.action),
        ...systemHealthAssessment.recommendations,
      ],
      execution_time_ms: Date.now() - startTime,
    };

    console.log(`✅ Diagnostic complete in ${report.execution_time_ms}ms`);
    return report;
  } catch (error) {
    console.error("💥 Diagnostic failed:", error);

    // Return minimal error report
    return {
      timestamp: new Date(),
      system_health: {
        overall_score: 0,
        status: "critical",
        key_metrics: {
          total_events: 0,
          success_rate: 0,
          avg_response_time: 0,
          error_frequency: 1,
          agent_performance: [],
          top_errors: [],
        },
      },
      errors_found: [],
      failure_patterns: [],
      ai_analysis: {
        summary: "Diagnostic system failed",
        root_causes: [
          {
            cause: "Auto-debug system error",
            confidence: 1.0,
            evidence: [String(error)],
          },
        ],
        impact_assessment: {
          severity: "critical",
          affected_components: ["auto-debug"],
          user_impact: "No diagnostics available",
        },
        recommended_actions: [
          {
            action: "Manual system review required",
            priority: 1,
            effort: "high",
            risk: "low",
          },
        ],
        patterns_identified: ["system_failure"],
      },
      generated_fixes: [],
      priority_order: [],
      recommendations: ["Manual intervention required"],
      execution_time_ms: Date.now() - startTime,
    };
  }
}

/**
 * Complete auto-debug workflow with reporting
 */
export async function autoDebugSystem(
  config: Partial<AutoDebugConfig> = {},
): Promise<void> {
  const finalConfig = { ...DEFAULT_CONFIG, ...config };

  try {
    // Run full diagnostics
    const report = await runDiagnostics(finalConfig);

    // Generate fix files if requested
    if (finalConfig.generate_fixes && report.generated_fixes.length > 0) {
      console.log("📝 Creating fix files...");
      await createFixFiles(
        report.generated_fixes,
        finalConfig.output_directory,
      );
    }

    // Save detailed report
    const reportPath = await saveReportFile(report);
    console.log(`💾 Report saved: ${reportPath}`);

    // Send RocketChat report if enabled
    if (finalConfig.send_reports) {
      console.log("📨 Sending RocketChat report...");
      try {
        await sendDebugReport(report);
        console.log("✅ RocketChat report sent");
      } catch (error) {
        console.warn("⚠️ Failed to send RocketChat report:", error);
      }
    }

    // Console summary
    console.log("\n" + (await formatConsoleReport(report)));

    // Auto-apply safe fixes if enabled
    if (finalConfig.auto_apply_safe_fixes) {
      const safeFixes = report.generated_fixes.filter(
        (fix) =>
          fix.confidence > 0.8 &&
          fix.priority <= 2 &&
          ["config_change", "documentation"].includes(fix.fix_type),
      );

      if (safeFixes.length > 0) {
        console.log(`🔄 Auto-applying ${safeFixes.length} safe fixes...`);
        for (const fix of safeFixes) {
          try {
            const isValid = await validateFix(fix);
            if (isValid) {
              await applyFix(fix, true);
              console.log(`✅ Applied: ${fix.title}`);
            }
          } catch (error) {
            console.warn(`⚠️ Failed to apply fix ${fix.id}:`, error);
          }
        }
      }
    }
  } catch (error) {
    console.error("💥 Auto-debug system failed:", error);
    throw error;
  }
}

/**
 * Generate system health report only
 */
export async function generateSystemReport(): Promise<DiagnosticReport> {
  console.log("📊 Generating system health report...");

  const report = await runDiagnostics({
    claude_analysis: false,
    generate_fixes: false,
    hours_to_analyze: 6,
  });

  console.log(await formatConsoleReport(report));
  return report;
}

/**
 * Quick error check - returns true if critical issues found
 */
export async function quickHealthCheck(): Promise<{
  healthy: boolean;
  critical_issues: number;
  warning_issues: number;
  summary: string;
}> {
  try {
    const errors = await getRecentErrors(1); // Last hour only
    const critical = errors.filter((e) => e.severity === "critical").length;
    const warnings = errors.filter((e) => e.severity === "warning").length;

    return {
      healthy: critical === 0 && warnings < 3,
      critical_issues: critical,
      warning_issues: warnings,
      summary:
        critical > 0
          ? `${critical} critical issues require immediate attention`
          : warnings > 2
            ? `${warnings} warnings detected`
            : "System appears healthy",
    };
  } catch (error) {
    return {
      healthy: false,
      critical_issues: 1,
      warning_issues: 0,
      summary: "Health check failed - manual review needed",
    };
  }
}

/**
 * Fallback analysis when AI is unavailable
 */
function createFallbackAnalysis(
  errors: ErrorPattern[],
  patterns: FailurePattern[],
): Analysis {
  const totalErrors = errors.reduce((sum, e) => sum + e.frequency, 0);
  const criticalCount = errors.filter((e) => e.severity === "critical").length;

  const topPatterns = patterns.slice(0, 3);
  const affectedAgents = [...new Set(errors.flatMap((e) => e.affected_agents))];

  return {
    summary: `Found ${errors.length} error patterns (${totalErrors} total occurrences)`,
    root_causes: [
      ...topPatterns.map((p) => ({
        cause: p.description,
        confidence: p.confidence,
        evidence: [`${p.occurrences} occurrences`],
      })),
      {
        cause: "Multiple system component failures",
        confidence: 0.7,
        evidence: [`${affectedAgents.length} agents affected`],
      },
    ],
    impact_assessment: {
      severity:
        criticalCount > 0 ? "critical" : totalErrors > 10 ? "high" : "medium",
      affected_components: affectedAgents,
      user_impact:
        criticalCount > 0
          ? "Critical system functionality impaired"
          : "Some operations may be slower or unreliable",
    },
    recommended_actions: [
      {
        action: "Address highest frequency errors first",
        priority: 1,
        effort: "medium",
        risk: "low",
      },
      {
        action: "Review agent performance metrics",
        priority: 2,
        effort: "low",
        risk: "low",
      },
      ...topPatterns.map((p, i) => ({
        action: p.suggested_fix,
        priority: i + 3,
        effort: "medium" as const,
        risk: "low" as const,
      })),
    ],
    patterns_identified: [
      ...errors.map((e) => e.error_type),
      ...patterns.map((p) => p.pattern_type),
    ],
  };
}

/**
 * Create basic priorities when AI fails
 */
function createDefaultPriorities(errors: ErrorPattern[]): Priority[] {
  return errors
    .sort((a, b) => {
      // Sort by severity first, then frequency
      const severityWeight = { critical: 100, warning: 50, info: 10 };
      const aScore = severityWeight[a.severity] + a.frequency;
      const bScore = severityWeight[b.severity] + b.frequency;
      return bScore - aScore;
    })
    .map((error, index) => ({
      issue: `${error.error_type} (${error.frequency} occurrences)`,
      priority_score: Math.max(100 - index * 10, 10),
      reasoning: `Severity: ${error.severity}, Frequency: ${error.frequency}`,
      urgency:
        error.severity === "critical"
          ? "immediate"
          : error.frequency > 5
            ? "urgent"
            : "normal",
      estimated_fix_time:
        error.severity === "critical" ? "15 minutes" : "30 minutes",
    }));
}
