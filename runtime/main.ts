// runtime/main.ts - Actual startup script for ROL3

import { runRLang } from "./interpreter";
import { connectDatabase } from "./bootstrap";

process.on("unhandledRejection", (reason) => {
  console.error("🚨 Unhandled Rejection:", reason);
  process.exit(1);
});

process.on("uncaughtException", (err) => {
  console.error("🚨 Uncaught Exception:", err);
  process.exit(1);
});

async function startROL3() {
  console.log("🚀 Starting ROL3 Agent System...");

  try {
    // Test database connection
    console.log("📡 Connecting to database...");
    const dbHealth = await connectDatabase({}, {
      agentId: "system",
      operation: "startup",
    } as any);
    console.log("✅ Database connected:", dbHealth);

    // Start webhook server
    console.log("🔗 Starting webhook server...");
    const webhookModule = await import("../server/webhook-handler.js");
    console.log("✅ Webhook server started on port 3001");

    // Initialize RCD system
    console.log("🧠 Initializing RCD system...");
    try {
      console.log("⏳ Calling runRLang...");
      const result = await runRLang({
        file: "r/agents/system-doctor.r",
        operation: "system_health_check",
        input: { startup: true },
      });
      console.log("✅ runRLang returned");
      console.log("🧪 runRLang result:", result);
      console.log("✅ RCD system initialized:", result?.success ?? "unknown");
    } catch (err) {
      console.error("💥 RCD init failed:", err);
      process.exit(1);
    }

    console.log("🎉 ROL3 system is ALIVE and ready!");

    // Keep the process alive
    await new Promise(() => {});
  } catch (error) {
    console.error("💥 Startup failed:", error);
    console.error(
      "Stack:",
      error instanceof Error ? error.stack : String(error),
    );
    process.exit(1);
  }
}

// Start the system
startROL3().catch((err) => {
  console.error("❌ Uncaught error in startROL3:", err);
});
