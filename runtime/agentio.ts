// utils/agentio.ts
// PURE file I/O (10% rule) - ZERO logic, only filesystem primitives

import { RLangContext } from "../schema/types";

/**
 * Raw file write - Pure filesystem primitive
 */
export async function writeFile(args: any, context: RLangContext) {
  const fs = await import("fs/promises");
  await fs.writeFile(args.path, args.content, "utf-8");
  const stats = await fs.stat(args.path);
  return { size: stats.size };
}

/**
 * Raw file read - Pure filesystem primitive
 */
export async function readFile(args: any, context: RLangContext) {
  const fs = await import("fs/promises");
  const content = await fs.readFile(args.path, "utf-8");
  return { content };
}

/**
 * Raw file copy - Pure filesystem primitive
 */
export async function copyFile(args: any, context: RLangContext) {
  const fs = await import("fs/promises");
  await fs.copyFile(args.source, args.destination);
  return { copied: true };
}

/**
 * Raw file delete - Pure filesystem primitive
 */
export async function deleteFile(args: any, context: RLangContext) {
  const fs = await import("fs/promises");
  await fs.unlink(args.path);
  return { deleted: true };
}

/**
 * Raw file move - Pure filesystem primitive
 */
export async function moveFile(args: any, context: RLangContext) {
  const fs = await import("fs/promises");
  await fs.rename(args.source, args.destination);
  return { moved: true };
}

/**
 * Raw directory listing - Pure filesystem primitive
 */
export async function listFiles(args: any, context: RLangContext) {
  const fs = await import("fs/promises");
  const entries = await fs.readdir(args.path, { withFileTypes: true });
  return {
    files: entries.filter((e) => e.isFile()).map((e) => e.name),
    directories: entries.filter((e) => e.isDirectory()).map((e) => e.name),
  };
}

/**
 * Raw file stats - Pure filesystem primitive
 */
export async function getFileStats(args: any, context: RLangContext) {
  const fs = await import("fs/promises");
  const stats = await fs.stat(args.path);
  return {
    size: stats.size,
    created: stats.birthtime.toISOString(),
    modified: stats.mtime.toISOString(),
  };
}

/**
 * Raw file existence check - Pure filesystem primitive
 */
export async function fileExists(args: any, context: RLangContext) {
  const fs = await import("fs/promises");
  try {
    await fs.access(args.path);
    return { exists: true };
  } catch {
    return { exists: false };
  }
}
