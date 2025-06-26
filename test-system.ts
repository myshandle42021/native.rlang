// test-system.ts - Comprehensive ROL3 System Test
// Run with: npx tsx test-system.ts

import * as fs from "fs";
import * as path from "path";

interface TestResult {
  file: string;
  test: string;
  status: "PASS" | "FAIL" | "WARN";
  error?: string;
  details?: any;
}

const results: TestResult[] = [];

function log(
  file: string,
  test: string,
  status: "PASS" | "FAIL" | "WARN",
  error?: string,
  details?: any,
) {
  results.push({ file, test, status, error, details });
  const emoji = status === "PASS" ? "✅" : status === "FAIL" ? "❌" : "⚠️";
  console.log(`${emoji} ${file} - ${test}${error ? `: ${error}` : ""}`);
  if (details) console.log(`   Details:`, details);
}

async function testFileExists(filePath: string): Promise<boolean> {
  try {
    await fs.promises.access(filePath);
    return true;
  } catch {
    return false;
  }
}

async function testRLangFileStructure(filePath: string) {
  const fileName = path.basename(filePath);

  if (!(await testFileExists(filePath))) {
    log(fileName, "File Exists", "FAIL", "File not found");
    return;
  }

  try {
    const { loadRFile } = await import("./runtime/loader");
    const rData = await loadRFile(filePath);

    log(fileName, "YAML Parse", "PASS");

    // Test required structure
    if (!rData.operations) {
      log(fileName, "Operations Section", "FAIL", "Missing operations section");
      return;
    }

    log(fileName, "Operations Section", "PASS", "", {
      count: Object.keys(rData.operations).length,
    });

    // Test each operation
    for (const [opName, steps] of Object.entries(rData.operations)) {
      if (!Array.isArray(steps)) {
        log(fileName, `Operation: ${opName}`, "FAIL", "Not an array", {
          type: typeof steps,
          value: steps,
        });
      } else {
        log(fileName, `Operation: ${opName}`, "PASS", "", {
          stepCount: steps.length,
        });

        // Test step structure
        for (let i = 0; i < steps.length; i++) {
          const step = steps[i];
          if (typeof step !== "string" && typeof step !== "object") {
            log(
              fileName,
              `Step ${i} in ${opName}`,
              "FAIL",
              "Invalid step type",
              { type: typeof step, step },
            );
          }
        }
      }
    }

    // Test self section
    if (rData.self) {
      if (!rData.self.id) {
        log(fileName, "Self ID", "FAIL", "Missing self.id");
      } else {
        log(fileName, "Self ID", "PASS", "", { id: rData.self.id });
      }
    }
  } catch (error) {
    log(
      fileName,
      "Load Test",
      "FAIL",
      error instanceof Error ? error.message : String(error),
    );
  }
}

async function testStepExecutorBuiltins() {
  try {
    const { executeSteps } = await import("./runtime/step-executor");

    // Test set_memory
    const testContext = {
      memory: {},
      agentId: "test",
      operation: "test",
      timestamp: new Date().toISOString(),
      trace: [],
    };

    const setMemorySteps = [
      { set_memory: { test_value: "hello", test_array: [] } },
    ];

    const result = await executeSteps(setMemorySteps, testContext, {
      operations: {},
    });

    if (testContext.memory.test_value === "hello") {
      log("step-executor", "set_memory builtin", "PASS");
    } else {
      log(
        "step-executor",
        "set_memory builtin",
        "FAIL",
        "Memory not updated correctly",
        { memory: testContext.memory },
      );
    }

    // Test append_to_array
    const appendSteps = [
      { append_to_array: { array: "test_array", item: "new_item" } },
    ];

    await executeSteps(appendSteps, testContext, { operations: {} });

    if (
      Array.isArray(testContext.memory.test_array) &&
      testContext.memory.test_array.includes("new_item")
    ) {
      log("step-executor", "append_to_array builtin", "PASS");
    } else {
      log(
        "step-executor",
        "append_to_array builtin",
        "FAIL",
        "Array not updated correctly",
        { array: testContext.memory.test_array },
      );
    }
  } catch (error) {
    log(
      "step-executor",
      "Built-in Operations",
      "FAIL",
      error instanceof Error ? error.message : String(error),
    );
  }
}

async function testBootstrapOperationExecution() {
  try {
    const { runRLang } = await import("./runtime/interpreter");

    // Test individual operations first
    const testOps = [
      "validate_database_health",
      "add_validation_error",
      "check_memory_availability",
      "test_module_import",
    ];

    for (const opName of testOps) {
      try {
        const result = await runRLang({
          file: "r/system/bootstrap-policies.r",
          operation: opName,
          input: {
            health_result: { healthy: true },
            error: "test error",
            minimum_mb: 512,
            module: "fs/promises",
          },
          context: {
            memory: {},
            agentId: "test",
            operation: opName,
            timestamp: new Date().toISOString(),
            trace: [],
          },
        });

        log("bootstrap-policies", `Operation: ${opName}`, "PASS", "", {
          success: result.success,
        });
      } catch (error) {
        log(
          "bootstrap-policies",
          `Operation: ${opName}`,
          "FAIL",
          error instanceof Error ? error.message : String(error),
        );
      }
    }
  } catch (error) {
    log(
      "bootstrap-policies",
      "Operation Execution Test",
      "FAIL",
      error instanceof Error ? error.message : String(error),
    );
  }
}

async function testBootstrapFull() {
  try {
    const { runRLang } = await import("./runtime/interpreter");

    log("bootstrap-policies", "Full Bootstrap Test", "WARN", "Starting...");

    const result = await runRLang({
      file: "r/system/bootstrap-policies.r",
      operation: "system_genesis",
      input: {},
      context: {
        memory: {},
        agentId: "system",
        operation: "bootstrap",
        timestamp: new Date().toISOString(),
        trace: [],
      },
    });

    log("bootstrap-policies", "Full Bootstrap Test", "PASS", "", {
      success: result.success,
      trace: result.trace?.length,
    });
  } catch (error) {
    log(
      "bootstrap-policies",
      "Full Bootstrap Test",
      "FAIL",
      error instanceof Error ? error.message : String(error),
    );

    // Try to identify which step failed
    if (error instanceof Error && error.stack) {
      console.log("\n🔍 DEBUGGING INFO:");
      console.log("Error stack:", error.stack);
    }
  }
}

async function testUtilsFunctions() {
  try {
    // Test db.health
    const { health } = await import("./utils/db");
    const healthResult = await health({}, {});
    log("utils/db", "health function", "PASS", "", {
      healthy: healthResult.healthy,
    });

    // Test bootstrap functions
    const bootstrap = await import("./runtime/bootstrap");
    const stats = await bootstrap.getSystemStats({}, {});
    log("runtime/bootstrap", "getSystemStats", "PASS", "", {
      memoryType: typeof stats.memory?.total,
      cpuType: typeof stats.cpus,
    });
  } catch (error) {
    log(
      "utils",
      "Function Tests",
      "FAIL",
      error instanceof Error ? error.message : String(error),
    );
  }
}

async function testVariableResolution() {
  try {
    const { executeSteps } = await import("./runtime/step-executor");

    const context = {
      memory: { test_value: "hello", items: ["a", "b", "c"] },
      agentId: "test",
      operation: "test",
      timestamp: new Date().toISOString(),
      trace: [],
    };

    // Test template string resolution
    const steps = [
      {
        set_memory: {
          resolved: "${test_value} world",
          count: "${items.length}",
        },
      },
    ];

    await executeSteps(steps, context, { operations: {} });

    if (
      context.memory.resolved === "hello world" &&
      context.memory.count === 3
    ) {
      log("step-executor", "Variable Resolution", "PASS");
    } else {
      log(
        "step-executor",
        "Variable Resolution",
        "FAIL",
        "Template resolution failed",
        {
          resolved: context.memory.resolved,
          count: context.memory.count,
        },
      );
    }
  } catch (error) {
    log(
      "step-executor",
      "Variable Resolution",
      "FAIL",
      error instanceof Error ? error.message : String(error),
    );
  }
}

async function runAllTests() {
  console.log("🔍 ROL3 System Holistic Test Report");
  console.log("=====================================\n");

  // Test core R-lang files
  const rlangFiles = [
    "r/system/bootstrap-policies.r",
    "r/system/rcd-bootstrap-check.r",
    "r/system/rcd-file-tagger.r",
    "r/agents/system-doctor.r",
    "r/templates/service-integration.r",
  ];

  console.log("📋 Testing R-lang File Structure...");
  for (const file of rlangFiles) {
    await testRLangFileStructure(file);
  }

  console.log("\n🔧 Testing Step Executor...");
  await testStepExecutorBuiltins();
  await testVariableResolution();

  console.log("\n🏥 Testing Utils Functions...");
  await testUtilsFunctions();

  console.log("\n🚀 Testing Bootstrap Operations...");
  await testBootstrapOperationExecution();

  console.log("\n🎯 Testing Full Bootstrap...");
  await testBootstrapFull();

  // Summary
  console.log("\n📊 TEST SUMMARY");
  console.log("================");

  const summary = {
    PASS: results.filter((r) => r.status === "PASS").length,
    FAIL: results.filter((r) => r.status === "FAIL").length,
    WARN: results.filter((r) => r.status === "WARN").length,
  };

  console.log(`✅ PASS: ${summary.PASS}`);
  console.log(`❌ FAIL: ${summary.FAIL}`);
  console.log(`⚠️  WARN: ${summary.WARN}`);

  const failedTests = results.filter((r) => r.status === "FAIL");
  if (failedTests.length > 0) {
    console.log("\n🚨 FAILED TESTS:");
    failedTests.forEach((test) => {
      console.log(`   ${test.file} - ${test.test}: ${test.error}`);
      if (test.details) {
        console.log(`      Details:`, JSON.stringify(test.details, null, 2));
      }
    });
  }

  console.log(
    `\n🎯 Confidence Level: ${(summary.PASS / results.length) * 100}%`,
  );
}

// Run the tests
runAllTests().catch(console.error);
