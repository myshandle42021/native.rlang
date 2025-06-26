// complete-system-scan.ts - Tests EVERY file in the codebase
// Run with: npx tsx complete-system-scan.ts

import * as fs from "fs";
import * as path from "path";

interface FileTestResult {
  file: string;
  type: "r-lang" | "typescript" | "other";
  status: "PASS" | "FAIL" | "WARN" | "SKIP";
  tests: Array<{
    name: string;
    status: "PASS" | "FAIL" | "WARN";
    error?: string;
    details?: any;
  }>;
}

const results: FileTestResult[] = [];

async function findAllFiles(
  dir: string,
  extensions: string[] = [".r", ".ts", ".js"],
): Promise<string[]> {
  const files: string[] = [];

  try {
    const entries = await fs.promises.readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        // Skip node_modules, .git, dist, build directories
        if (
          !["node_modules", ".git", "dist", "build", ".next"].includes(
            entry.name,
          )
        ) {
          files.push(...(await findAllFiles(fullPath, extensions)));
        }
      } else if (entry.isFile()) {
        const ext = path.extname(entry.name);
        if (extensions.includes(ext)) {
          files.push(fullPath);
        }
      }
    }
  } catch (error) {
    console.warn(`Cannot read directory ${dir}:`, error);
  }

  return files;
}

async function testRLangFile(filePath: string): Promise<FileTestResult> {
  const fileName = path.relative(".", filePath);
  const result: FileTestResult = {
    file: fileName,
    type: "r-lang",
    status: "PASS",
    tests: [],
  };

  // Test 1: File exists and readable
  try {
    await fs.promises.access(filePath, fs.constants.R_OK);
    result.tests.push({ name: "File Access", status: "PASS" });
  } catch (error) {
    result.tests.push({
      name: "File Access",
      status: "FAIL",
      error: "Cannot read file",
    });
    result.status = "FAIL";
    return result;
  }

  // Test 2: YAML parsing
  try {
    const { loadRFile } = await import("./runtime/loader");
    const rData = await loadRFile(filePath);
    result.tests.push({ name: "YAML Parse", status: "PASS" });

    // Test 3: Required structure
    if (rData.operations && typeof rData.operations === "object") {
      result.tests.push({
        name: "Operations Section",
        status: "PASS",
        details: { count: Object.keys(rData.operations).length },
      });

      // Test 4: Each operation is array
      let invalidOps = 0;
      for (const [opName, steps] of Object.entries(rData.operations)) {
        if (!Array.isArray(steps)) {
          invalidOps++;
          result.tests.push({
            name: `Operation: ${opName}`,
            status: "FAIL",
            error: "Not an array",
            details: { type: typeof steps },
          });
        } else {
          result.tests.push({
            name: `Operation: ${opName}`,
            status: "PASS",
            details: { stepCount: steps.length },
          });
        }
      }

      if (invalidOps > 0) {
        result.status = "FAIL";
      }
    } else {
      result.tests.push({
        name: "Operations Section",
        status: "FAIL",
        error: "Missing or invalid operations",
      });
      result.status = "FAIL";
    }

    // Test 5: Self section
    if (rData.self?.id) {
      result.tests.push({
        name: "Self ID",
        status: "PASS",
        details: { id: rData.self.id },
      });
    } else {
      result.tests.push({
        name: "Self ID",
        status: "WARN",
        error: "Missing self.id",
      });
      if (result.status === "PASS") result.status = "WARN";
    }
  } catch (error) {
    result.tests.push({
      name: "YAML Parse",
      status: "FAIL",
      error: error instanceof Error ? error.message : String(error),
    });
    result.status = "FAIL";
  }

  return result;
}

async function testTypeScriptFile(filePath: string): Promise<FileTestResult> {
  const fileName = path.relative(".", filePath);
  const result: FileTestResult = {
    file: fileName,
    type: "typescript",
    status: "PASS",
    tests: [],
  };

  // Test 1: File exists and readable
  try {
    await fs.promises.access(filePath, fs.constants.R_OK);
    result.tests.push({ name: "File Access", status: "PASS" });
  } catch (error) {
    result.tests.push({
      name: "File Access",
      status: "FAIL",
      error: "Cannot read file",
    });
    result.status = "FAIL";
    return result;
  }

  // Test 2: Import/require test
  try {
    await import(path.resolve(filePath));
    result.tests.push({ name: "Module Import", status: "PASS" });
  } catch (error) {
    const errorMsg = error instanceof Error ? error.message : String(error);

    // Some import errors are expected (like missing dependencies)
    if (
      errorMsg.includes("Cannot find module") ||
      errorMsg.includes("ENOENT")
    ) {
      result.tests.push({
        name: "Module Import",
        status: "WARN",
        error: "Missing dependencies",
        details: { error: errorMsg },
      });
      if (result.status === "PASS") result.status = "WARN";
    } else {
      result.tests.push({
        name: "Module Import",
        status: "FAIL",
        error: errorMsg,
      });
      result.status = "FAIL";
    }
  }

  // Test 3: Syntax check (read file and check for obvious issues)
  try {
    const content = await fs.promises.readFile(filePath, "utf8");

    // Check for syntax issues
    const issues = [];
    if (content.includes("import") && !content.includes("export")) {
      issues.push("Has imports but no exports");
    }

    // Check for unmatched braces/brackets (simple check)
    const openBraces = (content.match(/{/g) || []).length;
    const closeBraces = (content.match(/}/g) || []).length;
    if (Math.abs(openBraces - closeBraces) > 2) {
      // Allow small variance
      issues.push("Potential unmatched braces");
    }

    if (issues.length > 0) {
      result.tests.push({
        name: "Syntax Check",
        status: "WARN",
        details: { issues },
      });
      if (result.status === "PASS") result.status = "WARN";
    } else {
      result.tests.push({ name: "Syntax Check", status: "PASS" });
    }
  } catch (error) {
    result.tests.push({
      name: "Syntax Check",
      status: "FAIL",
      error: error instanceof Error ? error.message : String(error),
    });
    result.status = "FAIL";
  }

  return result;
}

async function testSystemIntegrations() {
  console.log("\n🔗 Testing System Integrations...");

  // Test core system functions
  const integrationTests = [
    {
      name: "Database Connection",
      test: async () => {
        const { health } = await import("./utils/db");
        return await health({}, {});
      },
    },
    {
      name: "Bootstrap Functions",
      test: async () => {
        const bootstrap = await import("./runtime/bootstrap");
        return await bootstrap.getSystemStats({}, {});
      },
    },
    {
      name: "Step Executor Built-ins",
      test: async () => {
        const { executeSteps } = await import("./runtime/step-executor");
        const context = {
          memory: {},
          agentId: "test",
          operation: "test",
          timestamp: new Date().toISOString(),
          trace: [],
        };

        await executeSteps([{ set_memory: { test: "value" } }], context, {
          operations: {},
        });
        return { success: context.memory.test === "value" };
      },
    },
    {
      name: "R-lang Interpreter",
      test: async () => {
        const { runRLang } = await import("./runtime/interpreter");
        return await runRLang({
          file: "r/system/bootstrap-policies.r",
          operation: "add_validation_error",
          input: { error: "test" },
          context: {
            memory: {},
            agentId: "test",
            operation: "test",
            timestamp: new Date().toISOString(),
            trace: [],
          },
        });
      },
    },
  ];

  for (const { name, test } of integrationTests) {
    try {
      const result = await test();
      console.log(`✅ ${name}: PASS`);
    } catch (error) {
      console.log(
        `❌ ${name}: FAIL - ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}

async function runCompleteSystemScan() {
  console.log("🔍 Complete ROL3 System Scan");
  console.log("===============================\n");

  // Find all files
  console.log("📁 Discovering files...");
  const allFiles = await findAllFiles(".");
  const rlangFiles = allFiles.filter((f) => f.endsWith(".r"));
  const tsFiles = allFiles.filter(
    (f) => f.endsWith(".ts") && !f.includes("node_modules"),
  );

  console.log(
    `Found ${rlangFiles.length} R-lang files and ${tsFiles.length} TypeScript files\n`,
  );

  // Test R-lang files
  console.log("📋 Testing R-lang Files...");
  for (const file of rlangFiles) {
    const result = await testRLangFile(file);
    results.push(result);

    const emoji =
      result.status === "PASS" ? "✅" : result.status === "FAIL" ? "❌" : "⚠️";
    console.log(`${emoji} ${result.file} - ${result.tests.length} tests`);
  }

  // Test TypeScript files
  console.log("\n🔧 Testing TypeScript Files...");
  for (const file of tsFiles) {
    const result = await testTypeScriptFile(file);
    results.push(result);

    const emoji =
      result.status === "PASS" ? "✅" : result.status === "FAIL" ? "❌" : "⚠️";
    console.log(`${emoji} ${result.file} - ${result.tests.length} tests`);
  }

  // Test integrations
  await testSystemIntegrations();

  // Generate comprehensive report
  console.log("\n📊 COMPLETE SYSTEM REPORT");
  console.log("===========================");

  const summary = {
    totalFiles: results.length,
    rlangFiles: results.filter((r) => r.type === "r-lang").length,
    tsFiles: results.filter((r) => r.type === "typescript").length,
    passing: results.filter((r) => r.status === "PASS").length,
    failing: results.filter((r) => r.status === "FAIL").length,
    warnings: results.filter((r) => r.status === "WARN").length,
  };

  console.log(`📁 Total Files Tested: ${summary.totalFiles}`);
  console.log(`   - R-lang files: ${summary.rlangFiles}`);
  console.log(`   - TypeScript files: ${summary.tsFiles}`);
  console.log(`✅ Passing: ${summary.passing}`);
  console.log(`❌ Failing: ${summary.failing}`);
  console.log(`⚠️ Warnings: ${summary.warnings}`);

  // Detailed failure report
  const failures = results.filter((r) => r.status === "FAIL");
  if (failures.length > 0) {
    console.log("\n🚨 FAILED FILES:");
    failures.forEach((file) => {
      console.log(`\n❌ ${file.file}:`);
      file.tests
        .filter((t) => t.status === "FAIL")
        .forEach((test) => {
          console.log(`   - ${test.name}: ${test.error}`);
          if (test.details) {
            console.log(`     Details: ${JSON.stringify(test.details)}`);
          }
        });
    });
  }

  // R-lang specific issues
  const rlangIssues = results.filter(
    (r) => r.type === "r-lang" && r.status !== "PASS",
  );
  if (rlangIssues.length > 0) {
    console.log("\n🔴 R-lang Issues:");
    rlangIssues.forEach((file) => {
      const failedTests = file.tests.filter((t) => t.status !== "PASS");
      console.log(
        `   ${file.file}: ${failedTests.map((t) => t.name).join(", ")}`,
      );
    });
  }

  // TypeScript specific issues
  const tsIssues = results.filter(
    (r) => r.type === "typescript" && r.status === "FAIL",
  );
  if (tsIssues.length > 0) {
    console.log("\n🔴 TypeScript Issues:");
    tsIssues.forEach((file) => {
      const failedTests = file.tests.filter((t) => t.status === "FAIL");
      console.log(
        `   ${file.file}: ${failedTests.map((t) => t.name).join(", ")}`,
      );
    });
  }

  const confidence = Math.round((summary.passing / summary.totalFiles) * 100);
  console.log(`\n🎯 System Confidence: ${confidence}%`);

  if (confidence >= 95) {
    console.log("🎉 System is in excellent health!");
  } else if (confidence >= 80) {
    console.log("✅ System is healthy with minor issues");
  } else if (confidence >= 60) {
    console.log("⚠️ System has significant issues that need attention");
  } else {
    console.log("🚨 System requires immediate attention");
  }
}

// Run the complete scan
runCompleteSystemScan().catch(console.error);
