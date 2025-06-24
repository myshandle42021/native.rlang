// scripts/run-test.ts
import fs from "fs/promises";
import path from "path";
import { runRLang } from "../runtime/interpreter";

const filePath = "r/examples/test-log-agent.r";

async function main() {
  try {
    const absolutePath = path.resolve(process.cwd(), filePath);
    console.log(`🧪 Loading RLang file from: ${absolutePath}`);

    const code = await fs.readFile(absolutePath, "utf-8");
    const context = {
      agentId: "test-log-agent",
      clientId: "test-client",
      memory: {},
      trace: [],
    };

    const result = await runRLang(code, "run_test", {}, context);
    console.log("✅ Test Result:", result);
  } catch (err: any) {
    console.error("❌ Test Error:", {
      error: err.message,
      stack: err.stack,
    });
  }
}

main();
