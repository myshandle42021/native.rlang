#!/usr/bin/env tsx
// cli/debug-system.ts
// Command-line interface for ROL3 Auto-Debug System

import { Command } from "commander";
import {
  runDiagnostics,
  autoDebugSystem,
  generateSystemReport,
  quickHealthCheck,
  type AutoDebugConfig,
} from "../utils/auto-debug";
import {
  getRecentErrors,
  getSystemMetrics,
  checkTableHealth,
} from "../utils/debug-queries";
import { createFixFiles, validateFix, applyFix } from "../utils/fix-generator";
import { saveReportFile } from "../utils/debug-reporter";
import * as fs from "fs/promises";

const program = new Command();

program
  .name("debug-system")
  .description("ROL3 Auto-Debug System CLI")
  .version("1.0.0");

// Main diagnostic command
program
  .command("diagnose")
  .description("Run full system diagnostics")
  .option("-h, --hours <number>", "Hours of data to analyze", "24")
  .option("--no-ai", "Disable AI analysis")
  .option("--no-fixes", "Skip fix generation")
  .option("--no-report", "Skip RocketChat reporting")
  .option(
    "-o, --output <dir>",
    "Output directory for fixes",
    "./generated-fixes",
  )
  .action(async (options: any) => {
    console.log("🚀 Starting ROL3 Auto-Debug System...\n");

    const config: Partial<AutoDebugConfig> = {
      hours_to_analyze: parseInt(options.hours),
      claude_analysis: options.ai !== false,
      generate_fixes: options.fixes !== false,
      send_reports: options.report !== false,
      output_directory: options.output,
    };

    try {
      await autoDebugSystem(config);
      console.log("\n✅ Auto-debug completed successfully!");
    } catch (error) {
      console.error("\n💥 Auto-debug failed:", error);
      process.exit(1);
    }
  });

// Quick health check
program
  .command("health")
  .description("Quick system health check")
  .action(async (options: any) => {
    console.log("🏥 Running quick health check...\n");

    try {
      const health = await quickHealthCheck();

      const statusIcon = health.healthy ? "✅" : "⚠️";
      console.log(
        `${statusIcon} System Status: ${health.healthy ? "HEALTHY" : "ISSUES DETECTED"}`,
      );
      console.log(`🚨 Critical Issues: ${health.critical_issues}`);
      console.log(`⚠️  Warning Issues: ${health.warning_issues}`);
      console.log(`📝 Summary: ${health.summary}\n`);

      if (!health.healthy) {
        console.log('💡 Run "npm run debug diagnose" for detailed analysis');
        process.exit(1);
      }
    } catch (error) {
      console.error("💥 Health check failed:", error);
      process.exit(1);
    }
  });

// System metrics command
program
  .command("metrics")
  .description("Display system metrics")
  .option("-h, --hours <number>", "Hours to analyze", "24")
  .action(async (options) => {
    console.log(`📊 System Metrics (Last ${options.hours} hours)\n`);

    try {
      const metrics = await getSystemMetrics();

      console.log(`📈 Total Events: ${metrics.total_events}`);
      console.log(
        `✅ Success Rate: ${(metrics.success_rate * 100).toFixed(1)}%`,
      );
      console.log(
        `⚠️  Error Frequency: ${(metrics.error_frequency * 100).toFixed(1)}%`,
      );
      console.log(`📦 Agents Tracked: ${metrics.agent_performance.length}\n`);

      if (metrics.agent_performance.length > 0) {
        console.log("🤖 Agent Performance:");
        console.log("─".repeat(60));
        metrics.agent_performance.slice(0, 10).forEach((agent) => {
          const successRate = (agent.success_rate * 100).toFixed(1);
          const statusIcon =
            agent.success_rate > 0.9
              ? "✅"
              : agent.success_rate > 0.7
                ? "⚠️"
                : "❌";
          console.log(
            `${statusIcon} ${agent.agent_id.padEnd(25)} ${successRate}% success (${agent.error_count} errors)`,
          );
        });
        console.log("");
      }

      if (metrics.top_errors.length > 0) {
        console.log("🚨 Top Error Patterns:");
        console.log("─".repeat(60));
        metrics.top_errors.slice(0, 5).forEach((error, i) => {
          const severityIcon =
            error.severity === "critical"
              ? "🔴"
              : error.severity === "warning"
                ? "🟡"
                : "🔵";
          console.log(
            `${i + 1}. ${severityIcon} ${error.error_type} (${error.frequency}x)`,
          );
        });
      }
    } catch (error) {
      console.error("💥 Failed to get metrics:", error);
      process.exit(1);
    }
  });

// Database health check
program
  .command("db-health")
  .description("Check database table health")
  .action(async () => {
    console.log("🗄️ Checking database health...\n");

    try {
      const health = await checkTableHealth();

      if (health.healthy) {
        console.log("✅ Database appears healthy");
      } else {
        console.log("⚠️ Database issues detected");
      }

      console.log("\n📋 Table Status:");
      console.log("─".repeat(50));
      health.tables.forEach((table) => {
        const statusIcon = table.exists ? "✅" : "❌";
        console.log(
          `${statusIcon} ${table.name.padEnd(25)} ${table.row_count} recent rows`,
        );
      });

      if (health.missing_tables.length > 0) {
        console.log(`\n❌ Missing Tables: ${health.missing_tables.join(", ")}`);
      }
    } catch (error) {
      console.error("💥 Database health check failed:", error);
      process.exit(1);
    }
  });

// Error analysis command
program
  .command("errors")
  .description("Analyze recent errors")
  .option("-h, --hours <number>", "Hours to analyze", "6")
  .option("-l, --limit <number>", "Limit results", "20")
  .action(async (options) => {
    console.log(`🔍 Analyzing errors (Last ${options.hours} hours)\n`);

    try {
      const errors = await getRecentErrors(parseInt(options.hours));

      if (errors.length === 0) {
        console.log("✅ No errors found in the specified time period");
        return;
      }

      console.log(`Found ${errors.length} error patterns:\n`);

      const sortedErrors = errors
        .sort((a, b) => b.frequency - a.frequency)
        .slice(0, parseInt(options.limit));

      sortedErrors.forEach((error, i) => {
        const severityIcon =
          error.severity === "critical"
            ? "🔴"
            : error.severity === "warning"
              ? "🟡"
              : "🔵";
        console.log(`${i + 1}. ${severityIcon} ${error.error_type}`);
        console.log(
          `   Frequency: ${error.frequency} | Severity: ${error.severity}`,
        );
        console.log(`   First seen: ${error.first_seen.toLocaleString()}`);
        console.log(`   Last seen: ${error.last_seen.toLocaleString()}`);
        console.log(
          `   Affected agents: ${error.affected_agents.join(", ") || "Unknown"}`,
        );
        console.log("");
      });
    } catch (error) {
      console.error("💥 Error analysis failed:", error);
      process.exit(1);
    }
  });

// Fix management commands
const fixCmd = program.command("fix").description("Fix management commands");

fixCmd
  .command("list")
  .description("List available fixes")
  .option("-d, --dir <directory>", "Fix directory", "./generated-fixes")
  .action(async (options) => {
    console.log("🔧 Available Fixes:\n");

    try {
      const fixFiles = await fs.readdir(options.dir);
      const markdownFiles = fixFiles.filter(
        (f) => f.endsWith(".md") && !f.includes("README"),
      );

      if (markdownFiles.length === 0) {
        console.log('No fixes found. Run "npm run debug diagnose" first.');
        return;
      }

      for (const file of markdownFiles.slice(0, 20)) {
        const content = await fs.readFile(`${options.dir}/${file}`, "utf-8");
        const titleMatch = content.match(/# Fix: (.+)/);
        const priorityMatch = content.match(/\*\*Priority:\*\* (\d+)/);
        const confidenceMatch = content.match(/\*\*Confidence:\*\* ([\d.]+)%/);

        const title = titleMatch?.[1] || file;
        const priority = priorityMatch?.[1] || "?";
        const confidence = confidenceMatch?.[1] || "?";

        const priorityIcon =
          parseInt(priority) <= 2
            ? "🔴"
            : parseInt(priority) <= 4
              ? "🟡"
              : "🟢";
        console.log(`${priorityIcon} ${title}`);
        console.log(`   File: ${file}`);
        console.log(`   Priority: ${priority} | Confidence: ${confidence}%\n`);
      }
    } catch (error) {
      console.error("💥 Failed to list fixes:", error);
      process.exit(1);
    }
  });

fixCmd
  .command("apply <fix-id>")
  .description("Apply a specific fix")
  .option("-d, --dir <directory>", "Fix directory", "./generated-fixes")
  .option("-f, --force", "Force apply without validation")
  .action(async (fixId, options) => {
    console.log(`🔧 Applying fix: ${fixId}\n`);

    try {
      // Load the fix from generated files
      const fixFiles = await fs.readdir(options.dir);
      const targetFile = fixFiles.find((f) => f.startsWith(fixId));

      if (!targetFile) {
        console.error(`❌ Fix ${fixId} not found`);
        process.exit(1);
      }

      console.log(`📄 Found fix file: ${targetFile}`);
      console.log(
        "🚨 Note: Manual application required - this is a prototype CLI",
      );
      console.log(`📖 Review fix: cat ${options.dir}/${targetFile}`);
    } catch (error) {
      console.error("💥 Failed to apply fix:", error);
      process.exit(1);
    }
  });

fixCmd
  .command("safe")
  .description("Apply all safe fixes automatically")
  .option("-d, --dir <directory>", "Fix directory", "./generated-fixes")
  .action(async (options) => {
    console.log("🛡️ Applying safe fixes...\n");

    try {
      console.log("🚨 Safe fix application not implemented yet");
      console.log("💡 Use the generated apply-fixes.js script instead:");
      console.log(`   cd ${options.dir} && node apply-fixes.js --safe`);
    } catch (error) {
      console.error("💥 Failed to apply safe fixes:", error);
      process.exit(1);
    }
  });

// Monitoring and scheduling commands
program
  .command("monitor")
  .description("Start continuous monitoring mode")
  .option("-i, --interval <minutes>", "Check interval in minutes", "15")
  .action(async (options) => {
    const interval = parseInt(options.interval) * 60 * 1000; // Convert to ms
    console.log(
      `🔄 Starting continuous monitoring (${options.interval} minute intervals)\n`,
    );

    let checkCount = 0;

    const runCheck = async () => {
      checkCount++;
      console.log(
        `\n🔍 Health Check #${checkCount} - ${new Date().toLocaleString()}`,
      );

      try {
        const health = await quickHealthCheck();

        if (health.healthy) {
          console.log("✅ System healthy");
        } else {
          console.log(`⚠️ Issues detected: ${health.summary}`);

          if (health.critical_issues > 0) {
            console.log(
              "🚨 Running full diagnostics due to critical issues...",
            );
            await autoDebugSystem({
              hours_to_analyze: 2,
              send_reports: true,
            });
          }
        }
      } catch (error) {
        console.error("💥 Monitoring check failed:", error);
      }
    };

    // Initial check
    await runCheck();

    // Schedule recurring checks
    const intervalId = setInterval(runCheck, interval);

    // Handle graceful shutdown
    process.on("SIGINT", () => {
      console.log("\n🛑 Stopping monitoring...");
      clearInterval(intervalId);
      process.exit(0);
    });

    console.log("\n💡 Press Ctrl+C to stop monitoring");
  });

// Report generation
program
  .command("report")
  .description("Generate diagnostic report only")
  .option("-h, --hours <number>", "Hours to analyze", "24")
  .option("-o, --output <file>", "Output file path")
  .action(async (options) => {
    console.log(`📊 Generating diagnostic report...\n`);

    try {
      const report = await generateSystemReport();

      if (options.output) {
        await saveReportFile(report);
        console.log(`📄 Report saved to: ${options.output}`);
      } else {
        console.log("Report would be displayed here (use --output to save)");
      }
    } catch (error) {
      console.error("💥 Report generation failed:", error);
      process.exit(1);
    }
  });

// Help and examples
program
  .command("examples")
  .description("Show usage examples")
  .action(() => {
    console.log(`
🛠️ ROL3 Auto-Debug System - Usage Examples

Basic Commands:
  npm run debug health              # Quick health check
  npm run debug diagnose            # Full system diagnosis
  npm run debug metrics             # Show system metrics
  npm run debug errors --hours 6   # Analyze recent errors

Fix Management:
  npm run debug fix list            # List available fixes
  npm run debug fix apply fix_1     # Apply specific fix
  npm run debug fix safe            # Apply safe fixes only

Monitoring:
  npm run debug monitor             # Continuous monitoring
  npm run debug monitor -i 5        # Check every 5 minutes

Advanced:
  npm run debug diagnose --no-ai    # Skip AI analysis
  npm run debug diagnose --hours 48 # Analyze 48 hours of data
  npm run debug db-health           # Check database health

Configuration:
  Add to package.json scripts:
  "debug": "tsx cli/debug-system.ts"
  "debug:health": "tsx cli/debug-system.ts health"
  "debug:monitor": "tsx cli/debug-system.ts monitor"
`);
  });

// Default action
program.action(() => {
  console.log("🛠️ ROL3 Auto-Debug System");
  console.log("Run with --help to see available commands");
  console.log("Quick start: npm run debug diagnose");
});

// Parse command line arguments
program.parse();

// Export for use as module
export default program;
