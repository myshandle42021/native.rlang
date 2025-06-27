// utils/debug-reporter.ts
// Reporting system for auto-debug results - RocketChat integration and console output

import * as fs from "fs/promises";
import * as path from "path";
import { DiagnosticReport } from "./auto-debug";

// Import RocketChat service if available
let rocketchatService: any = null;
try {
  rocketchatService = require("../services/rocketchat");
} catch (error) {
  console.warn("RocketChat service not available for reporting");
}

/**
 * Send diagnostic report to RocketChat
 */
export async function sendDebugReport(report: DiagnosticReport): Promise<void> {
  if (!rocketchatService) {
    console.warn("⚠️ RocketChat service unavailable - skipping report");
    return;
  }

  try {
    const message = formatRocketChatMessage(report);

    // Send to system monitoring channel
    await rocketchatService.sendMessage({
      channel: "#system-monitoring", // Adjust channel as needed
      message: message.text,
      attachments: message.attachments,
    });

    console.log("✅ Debug report sent to RocketChat");
  } catch (error) {
    console.error("💥 Failed to send RocketChat report:", error);
    throw error;
  }
}

interface RocketChatAttachment {
  color: string;
  title: string;
  text: string;
  fields?: Array<{ title: string; value: string; short: boolean }>;
  actions?: Array<{ type: string; text: string; value: string }>;
}

/**
 * Format diagnostic report for RocketChat
 */
function formatRocketChatMessage(report: DiagnosticReport): {
  text: string;
  attachments: RocketChatAttachment[];
} {
  const healthColor = getHealthColor(report.system_health.status);
  const timestamp = report.timestamp.toISOString();

  const mainText = `🛠️ **ROL3 Auto-Debug Report** - ${timestamp}`;

  const attachments: RocketChatAttachment[] = [
    {
      color: healthColor,
      title: `System Health: ${report.system_health.status.toUpperCase()}`,
      text: `Overall Score: ${report.system_health.overall_score}/100`,
      fields: [
        {
          title: "Success Rate",
          value: `${(report.system_health.key_metrics.success_rate * 100).toFixed(1)}%`,
          short: true,
        },
        {
          title: "Total Events",
          value: report.system_health.key_metrics.total_events.toString(),
          short: true,
        },
        {
          title: "Error Frequency",
          value: `${(report.system_health.key_metrics.error_frequency * 100).toFixed(1)}%`,
          short: true,
        },
        {
          title: "Analysis Time",
          value: `${report.execution_time_ms}ms`,
          short: true,
        },
      ],
    },
  ];

  // Add error patterns if found
  if (report.errors_found.length > 0) {
    const topErrors = report.errors_found.slice(0, 5);
    attachments.push({
      color: "danger",
      title: `🚨 ${report.errors_found.length} Error Patterns Found`,
      text: topErrors
        .map(
          (error) =>
            `• **${error.error_type}**: ${error.frequency} occurrences (${error.severity})`,
        )
        .join("\n"),
      fields: [
        {
          title: "Most Affected Agent",
          value: getMostAffectedAgent(report.errors_found),
          short: true,
        },
        {
          title: "Critical Issues",
          value: report.errors_found
            .filter((e) => e.severity === "critical")
            .length.toString(),
          short: true,
        },
      ],
    });
  }

  // Add AI analysis summary
  if (report.ai_analysis.summary) {
    attachments.push({
      color: "warning",
      title: "🤖 AI Analysis",
      text: report.ai_analysis.summary,
      fields: [
        {
          title: "Root Causes",
          value: report.ai_analysis.root_causes
            .slice(0, 3)
            .map((c) => `• ${c.cause} (${(c.confidence * 100).toFixed(0)}%)`)
            .join("\n"),
          short: false,
        },
      ],
    });
  }

  // Add generated fixes
  if (report.generated_fixes.length > 0) {
    const highPriorityFixes = report.generated_fixes.filter(
      (f) => f.priority <= 2,
    );
    attachments.push({
      color: "good",
      title: `🔧 ${report.generated_fixes.length} Fixes Generated`,
      text: `${highPriorityFixes.length} high priority fixes ready for review`,
      fields: [
        {
          title: "Top Fix",
          value: report.generated_fixes[0]?.title || "None",
          short: true,
        },
        {
          title: "Auto-Applicable",
          value: report.generated_fixes
            .filter(
              (f) =>
                f.confidence > 0.8 &&
                ["config_change", "documentation"].includes(f.fix_type),
            )
            .length.toString(),
          short: true,
        },
      ],
      actions: [
        {
          type: "button",
          text: "Review Fixes",
          value: "review_debug_fixes",
        },
        {
          type: "button",
          text: "Apply Safe Fixes",
          value: "apply_safe_fixes",
        },
      ],
    });
  }

  // Add recommendations
  if (report.recommendations.length > 0) {
    attachments.push({
      color: "#439FE0",
      title: "💡 Recommendations",
      text: report.recommendations
        .slice(0, 5)
        .map((rec) => `• ${rec}`)
        .join("\n"),
      fields: [],
    });
  }

  return {
    text: mainText,
    attachments: attachments,
  };
}

/**
 * Format diagnostic report for console output
 */
export async function formatConsoleReport(
  report: DiagnosticReport,
): Promise<string> {
  const lines = [];

  lines.push("");
  lines.push(
    "╔══════════════════════════════════════════════════════════════╗",
  );
  lines.push(
    "║                    🛠️  ROL3 AUTO-DEBUG REPORT                 ║",
  );
  lines.push(
    "╚══════════════════════════════════════════════════════════════╝",
  );
  lines.push("");

  // System Health Summary
  const healthEmoji = getHealthEmoji(report.system_health.status);
  lines.push(
    `${healthEmoji} System Health: ${report.system_health.status.toUpperCase()} (${report.system_health.overall_score}/100)`,
  );
  lines.push(
    `📊 Success Rate: ${(report.system_health.key_metrics.success_rate * 100).toFixed(1)}%`,
  );
  lines.push(
    `📈 Total Events: ${report.system_health.key_metrics.total_events}`,
  );
  lines.push(
    `⚠️  Error Rate: ${(report.system_health.key_metrics.error_frequency * 100).toFixed(1)}%`,
  );
  lines.push(`⏱️  Analysis Time: ${report.execution_time_ms}ms`);
  lines.push("");

  // Error Patterns
  if (report.errors_found.length > 0) {
    lines.push("🚨 ERROR PATTERNS DETECTED:");
    lines.push("─".repeat(50));

    const sortedErrors = report.errors_found
      .sort((a, b) => b.frequency - a.frequency)
      .slice(0, 10);

    sortedErrors.forEach((error, i) => {
      const severityIcon =
        error.severity === "critical"
          ? "🔴"
          : error.severity === "warning"
            ? "🟡"
            : "🔵";
      lines.push(`${i + 1}. ${severityIcon} ${error.error_type}`);
      lines.push(
        `   Frequency: ${error.frequency} | Severity: ${error.severity}`,
      );
      lines.push(
        `   Affected: ${error.affected_agents.join(", ") || "Unknown"}`,
      );
      lines.push(`   Last seen: ${error.last_seen.toLocaleString()}`);
      lines.push("");
    });
  } else {
    lines.push("✅ No error patterns detected");
    lines.push("");
  }

  // Failure Patterns
  if (report.failure_patterns.length > 0) {
    lines.push("🔍 FAILURE PATTERNS:");
    lines.push("─".repeat(50));

    report.failure_patterns.slice(0, 5).forEach((pattern, i) => {
      lines.push(`${i + 1}. ${pattern.description}`);
      lines.push(
        `   Occurrences: ${pattern.occurrences} | Impact: ${pattern.impact_score}`,
      );
      lines.push(`   Suggested Fix: ${pattern.suggested_fix}`);
      lines.push("");
    });
  }

  // AI Analysis
  if (report.ai_analysis.summary) {
    lines.push("🤖 AI ANALYSIS:");
    lines.push("─".repeat(50));
    lines.push(report.ai_analysis.summary);
    lines.push("");

    if (report.ai_analysis.root_causes.length > 0) {
      lines.push("Root Causes:");
      report.ai_analysis.root_causes.slice(0, 3).forEach((cause) => {
        lines.push(
          `  • ${cause.cause} (${(cause.confidence * 100).toFixed(0)}% confidence)`,
        );
      });
      lines.push("");
    }
  }

  // Generated Fixes
  if (report.generated_fixes.length > 0) {
    lines.push("🔧 GENERATED FIXES:");
    lines.push("─".repeat(50));

    const sortedFixes = report.generated_fixes.sort(
      (a, b) => a.priority - b.priority,
    );

    sortedFixes.slice(0, 8).forEach((fix, i) => {
      const confidenceBar = "█".repeat(Math.floor(fix.confidence * 10));
      const priorityIcon =
        fix.priority <= 2 ? "🔴" : fix.priority <= 4 ? "🟡" : "🟢";

      lines.push(`${i + 1}. ${priorityIcon} ${fix.title}`);
      lines.push(`   File: ${fix.file_path}`);
      lines.push(`   Type: ${fix.fix_type} | Priority: ${fix.priority}`);
      lines.push(
        `   Confidence: [${confidenceBar.padEnd(10, "░")}] ${(fix.confidence * 100).toFixed(1)}%`,
      );
      lines.push("");
    });

    if (report.generated_fixes.length > 8) {
      lines.push(`   ... and ${report.generated_fixes.length - 8} more fixes`);
      lines.push("");
    }
  }

  // Recommendations
  if (report.recommendations.length > 0) {
    lines.push("💡 RECOMMENDATIONS:");
    lines.push("─".repeat(50));
    report.recommendations.slice(0, 8).forEach((rec, i) => {
      lines.push(`${i + 1}. ${rec}`);
    });
    lines.push("");
  }

  // Next Steps
  lines.push("🚀 NEXT STEPS:");
  lines.push("─".repeat(50));
  if (report.generated_fixes.length > 0) {
    const safeFixes = report.generated_fixes.filter(
      (f) =>
        f.confidence > 0.8 &&
        ["config_change", "documentation"].includes(f.fix_type),
    );

    if (safeFixes.length > 0) {
      lines.push(`✅ ${safeFixes.length} safe fixes can be auto-applied`);
      lines.push("   Run: npm run debug -- --apply-safe-fixes");
    }

    lines.push("📋 Review all fixes: cat generated-fixes/README.md");
    lines.push("🔧 Apply specific fix: npm run debug -- --apply-fix <fix_id>");
  } else {
    lines.push("📊 Monitor system for 1 hour and re-run diagnostics");
    lines.push("📞 Consider manual investigation if issues persist");
  }

  lines.push("");
  lines.push("─".repeat(66));
  lines.push(`Report generated: ${report.timestamp.toLocaleString()}`);
  lines.push("");

  return lines.join("\n");
}

/**
 * Save diagnostic report to JSON file
 */
export async function saveReportFile(
  report: DiagnosticReport,
): Promise<string> {
  const timestamp = report.timestamp.toISOString().replace(/[:.]/g, "-");
  const fileName = `debug-report-${timestamp}.json`;
  const filePath = path.join("./generated-fixes", fileName);

  try {
    // Ensure directory exists
    await fs.mkdir(path.dirname(filePath), { recursive: true });

    // Save detailed JSON report
    await fs.writeFile(filePath, JSON.stringify(report, null, 2), "utf-8");

    // Also save a human-readable version
    const readableFileName = `debug-report-${timestamp}.txt`;
    const readablePath = path.join("./generated-fixes", readableFileName);
    const readableContent = await formatConsoleReport(report);
    await fs.writeFile(readablePath, readableContent, "utf-8");

    console.log(`📄 Report saved: ${fileName} & ${readableFileName}`);
    return filePath;
  } catch (error) {
    console.error("💥 Failed to save report:", error);
    throw error;
  }
}

/**
 * Send summary report via email (if configured)
 */
export async function sendEmailReport(
  report: DiagnosticReport,
  recipients: string[],
): Promise<void> {
  // This would integrate with an email service like SendGrid, SES, etc.
  // For now, just log the intent
  console.log(`📧 Email report would be sent to: ${recipients.join(", ")}`);
  console.log("   (Email integration not implemented yet)");
}

/**
 * Helper functions
 */
function getHealthColor(status: string): string {
  switch (status) {
    case "healthy":
      return "good";
    case "degraded":
      return "warning";
    case "critical":
      return "danger";
    default:
      return "#439FE0";
  }
}

function getHealthEmoji(status: string): string {
  switch (status) {
    case "healthy":
      return "✅";
    case "degraded":
      return "⚠️";
    case "critical":
      return "🚨";
    default:
      return "❓";
  }
}

function getMostAffectedAgent(
  errors: Array<{ affected_agents: string[]; frequency: number }>,
): string {
  const agentCounts: Record<string, number> = {};

  errors.forEach((error) => {
    error.affected_agents.forEach((agent) => {
      agentCounts[agent] = (agentCounts[agent] || 0) + error.frequency;
    });
  });

  const sortedAgents = Object.entries(agentCounts).sort(
    ([, a], [, b]) => b - a,
  );

  return sortedAgents[0]?.[0] || "Unknown";
}

/**
 * Create a quick status update for monitoring dashboards
 */
export async function createStatusUpdate(report: DiagnosticReport): Promise<{
  status: string;
  message: string;
  metrics: Record<string, number>;
  timestamp: string;
}> {
  const criticalErrors = report.errors_found.filter(
    (e) => e.severity === "critical",
  ).length;
  const warningErrors = report.errors_found.filter(
    (e) => e.severity === "warning",
  ).length;

  let status = "healthy";
  let message = "System operating normally";

  if (criticalErrors > 0) {
    status = "critical";
    message = `${criticalErrors} critical issues require immediate attention`;
  } else if (warningErrors > 3) {
    status = "degraded";
    message = `${warningErrors} warnings detected, monitoring required`;
  } else if (report.system_health.key_metrics.success_rate < 0.9) {
    status = "degraded";
    message = "Success rate below optimal threshold";
  }

  return {
    status,
    message,
    metrics: {
      health_score: report.system_health.overall_score,
      success_rate: report.system_health.key_metrics.success_rate,
      error_frequency: report.system_health.key_metrics.error_frequency,
      total_errors: report.errors_found.length,
      critical_errors: criticalErrors,
      warning_errors: warningErrors,
      fixes_generated: report.generated_fixes.length,
    },
    timestamp: report.timestamp.toISOString(),
  };
}
