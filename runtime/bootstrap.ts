// runtime/bootstrap.ts
// PURE infrastructure (10% rule) - ZERO logic, only OS/filesystem primitives

import { RLangContext } from "../schema/types";

/**
 * Raw process signal registration - Cannot be done in .r files
 * NO logic - just primitive signal binding
 */
export async function registerSignalHandler(args: any, context: RLangContext) {
  const { signal, rlang_file, operation } = args;
  const { runRLang } = await import("../runtime/interpreter");

  process.on(signal, () => {
    runRLang({ file: rlang_file, operation, input: { signal } });
  });

  return { signal_registered: signal };
}

/**
 * Raw database connection - NO health checks or logic
 */
export async function connectDatabase(args: any, context: RLangContext) {
  const { db } = await import("../utils/db");
  return await db.health(); // Raw result, no interpretation
}

/**
 * Raw process exit - OS primitive
 */
export async function exitProcess(args: any, context: RLangContext) {
  process.exit(args.code || 0);
}

/**
 * Raw file write - Pure filesystem
 */
export async function writeFile(args: any, context: RLangContext) {
  const fs = await import("fs/promises");
  await fs.writeFile(args.path, args.content, "utf-8");
  return { written: true };
}

/**
 * Raw directory creation - Pure filesystem
 */
export async function mkdir(args: any, context: RLangContext) {
  const fs = await import("fs/promises");
  await fs.mkdir(args.path, { recursive: true });
  return { created: true };
}

/**
 * Raw file read - Pure filesystem
 */
export async function readFile(args: any, context: RLangContext) {
  const fs = await import("fs/promises");
  const content = await fs.readFile(args.path, "utf-8");
  return { content };
}

/**
 * Raw system information - OS primitives only
 */
export async function getSystemStats(args: any, context: RLangContext) {
  const os = await import("os");
  return {
    cpus: os.cpus().length,
    memory: { total: os.totalmem(), free: os.freemem() },
    load: os.loadavg(),
    platform: os.platform(),
  };
}

/**
 * Raw timer creation - OS primitive
 */
export async function setTimer(args: any, context: RLangContext) {
  const { runRLang } = await import("../runtime/interpreter");

  const timer = setInterval(() => {
    runRLang({ file: args.rlang_file, operation: args.operation });
  }, args.interval_ms);

  return { timer_id: timer[Symbol.toPrimitive]() };
}
