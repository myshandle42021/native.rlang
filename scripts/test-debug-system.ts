#!/usr/bin/env tsx
// scripts/test-debug-system.ts
// Test the auto-debug system with current database

import {
  checkTableHealth,
  getRecentErrors,
  getSystemMetrics,
} from "../utils/debug-queries";
import { runDiagnostics } from "../utils/auto-debug";

async function testDatabaseConnection() {
  console.log("🔍 Testing database connection...\n");

  try {
    const health = await checkTableHealth();

    console.log("📊 Database Health:");
    console.log(
      `✅ Overall Health: ${health.healthy ? "GOOD" : "ISSUES DETECTED"}`,
    );

    console.log("\n📋 Table Status:");
    health.tables.forEach((table) => {
      const status = table.exists ? "✅" : "❌";
      console.log(`${status} ${table.name}: ${table.row_count} recent rows`);
    });

    if (health.missing_tables.length > 0) {
      console.log(`\n⚠️ Missing tables: ${health.missing_tables.join(", ")}`);
    }

    return health.healthy;
  } catch (error) {
    console.error("💥 Database connection failed:", error);
    return false;
  }
}

async function testErrorAnalysis() {
  console.log("\n🔍 Testing error analysis...\n");

  try {
    const errors = await getRecentErrors(24);
    console.log(`📈 Found ${errors.length} error patterns in last 24 hours`);

    if (errors.length > 0) {
      console.log("\n🚨 Recent Error Patterns:");
      errors.slice(0, 5).forEach((error, i) => {
        console.log(
          `${i + 1}. ${error.error_type} (${error.frequency}x, ${error.severity})`,
        );
      });
    } else {
      console.log("✅ No errors found - system appears healthy!");
    }

    return true;
  } catch (error) {
    console.error("💥 Error analysis failed:", error);
    return false;
  }
}

async function testSystemMetrics() {
  console.log("\n📊 Testing system metrics...\n");

  try {
    const metrics = await getSystemMetrics();

    console.log(`📈 Total Events: ${metrics.total_events}`);
    console.log(`✅ Success Rate: ${(metrics.success_rate * 100).toFixed(1)}%`);
    console.log(
      `⚠️ Error Rate: ${(metrics.error_frequency * 100).toFixed(1)}%`,
    );
    console.log(`🤖 Agents Tracked: ${metrics.agent_performance.length}`);

    if (metrics.agent_performance.length > 0) {
      console.log("\n🤖 Top Performing Agents:");
      metrics.agent_performance
        .sort((a, b) => b.success_rate - a.success_rate)
        .slice(0, 3)
        .forEach((agent) => {
          console.log(
            `  • ${agent.agent_id}: ${(agent.success_rate * 100).toFixed(1)}% success`,
          );
        });
    }

    return true;
  } catch (error) {
    console.error("💥 Metrics test failed:", error);
    return false;
  }
}

async function testFullDiagnostics() {
  console.log("\n🛠️ Testing full diagnostics system...\n");

  try {
    const report = await runDiagnostics({
      hours_to_analyze: 6,
      claude_analysis: false, // Disable AI for testing
      generate_fixes: false,
      send_reports: false,
    });

    console.log("✅ Diagnostic Report Generated:");
    console.log(
      `🏥 System Health: ${report.system_health.status} (${report.system_health.overall_score}/100)`,
    );
    console.log(`🚨 Errors Found: ${report.errors_found.length}`);
    console.log(`🔍 Patterns Detected: ${report.failure_patterns.length}`);
    console.log(`⏱️ Analysis Time: ${report.execution_time_ms}ms`);

    if (report.recommendations.length > 0) {
      console.log("\n💡 Top Recommendations:");
      report.recommendations.slice(0, 3).forEach((rec, i) => {
        console.log(`  ${i + 1}. ${rec}`);
      });
    }

    return true;
  } catch (error) {
    console.error("💥 Full diagnostics test failed:", error);
    return false;
  }
}

async function main() {
  console.log("🚀 ROL3 Auto-Debug System Test Suite\n");
  console.log("=".repeat(50));

  const tests = [
    { name: "Database Connection", fn: testDatabaseConnection },
    { name: "Error Analysis", fn: testErrorAnalysis },
    { name: "System Metrics", fn: testSystemMetrics },
    { name: "Full Diagnostics", fn: testFullDiagnostics },
  ];

  let passed = 0;
  let failed = 0;

  for (const test of tests) {
    try {
      const result = await test.fn();
      if (result) {
        console.log(`\n✅ ${test.name}: PASSED`);
        passed++;
      } else {
        console.log(`\n❌ ${test.name}: FAILED`);
        failed++;
      }
    } catch (error) {
      console.log(`\n💥 ${test.name}: ERROR - ${error}`);
      failed++;
    }

    console.log("-".repeat(50));
  }

  console.log(`\n📊 Test Results: ${passed} passed, ${failed} failed`);

  if (passed === tests.length) {
    console.log("\n🎉 All tests passed! Auto-debug system is ready to use.");
    console.log("\n🚀 Next steps:");
    console.log("1. Run: npm run debug health");
    console.log("2. Run: npm run debug diagnose");
    console.log("3. Check generated-fixes/ directory");
  } else {
    console.log(
      "\n⚠️ Some tests failed. Check your database connection and table structure.",
    );
    process.exit(1);
  }
}

// Handle script execution
if (require.main === module) {
  main().catch(console.error);
}

export { main as testDebugSystem };
