// runtime/loader.ts
// Loads and parses .r files (YAML/JSON format)

import { readFile } from "fs/promises";
import { parse as parseYAML } from "yaml";
import { RLangFile } from "../schema/types";

const cache = new Map<string, { content: RLangFile; timestamp: number }>();
const CACHE_TTL = 5000; // 5 seconds in dev, longer in prod

export async function loadRFile(filePath: string): Promise<RLangFile> {
  const absolutePath = filePath.startsWith("/") ? filePath : `./${filePath}`;

  // Check cache first
  const cached = cache.get(absolutePath);
  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.content;
  }

  try {
    const fileContent = await readFile(absolutePath, "utf-8");
    const parsed = parseRLangContent(fileContent, absolutePath);

    // Validate structure
    validateRLangFile(parsed, absolutePath);

    // Cache the result
    cache.set(absolutePath, {
      content: parsed,
      timestamp: Date.now(),
    });

    return parsed;
  } catch (error) {
    if (error instanceof Error && error.message.includes("ENOENT")) {
      throw new Error(`RLang file not found: ${absolutePath}`);
    }
    throw new Error(
      `Failed to load ${absolutePath}: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

function parseRLangContent(content: string, filePath: string): RLangFile {
  const trimmed = content.trim();

  // Determine format by file extension or content
  if (
    filePath.endsWith(".json") ||
    (trimmed.startsWith("{") && trimmed.endsWith("}"))
  ) {
    return JSON.parse(content);
  }

  // Default to YAML parsing
  try {
    return parseYAML(content);
  } catch (yamlError) {
    // Try JSON as fallback
    try {
      return JSON.parse(content);
    } catch (jsonError) {
      throw new Error(
        `Invalid RLang format in ${filePath}. Expected YAML or JSON.`,
      );
    }
  }
}

function validateRLangFile(rFile: any, filePath: string): void {
  if (!rFile || typeof rFile !== "object") {
    throw new Error(`Invalid RLang file ${filePath}: must be an object`);
  }

  // Validate required structure
  if (!rFile.operations || typeof rFile.operations !== "object") {
    throw new Error(
      `Invalid RLang file ${filePath}: missing 'operations' section`,
    );
  }

  // Validate self section if present
  if (rFile.self) {
    if (!rFile.self.id || typeof rFile.self.id !== "string") {
      throw new Error(
        `Invalid RLang file ${filePath}: self.id must be a string`,
      );
    }
  }

  // Validate operations
  for (const [opName, steps] of Object.entries(rFile.operations)) {
    if (!Array.isArray(steps)) {
      throw new Error(
        `Invalid RLang file ${filePath}: operation '${opName}' must be an array of steps`,
      );
    }
  }

  // Validate concern if present
  if (rFile.concern) {
    const concern = rFile.concern;
    if (!concern.if || typeof concern.if !== "string") {
      throw new Error(
        `Invalid RLang file ${filePath}: concern.if must be a string`,
      );
    }
    if (!concern.action || !Array.isArray(concern.action)) {
      throw new Error(
        `Invalid RLang file ${filePath}: concern.action must be an array`,
      );
    }
    if (typeof concern.priority !== "number") {
      throw new Error(
        `Invalid RLang file ${filePath}: concern.priority must be a number`,
      );
    }
  }
}

// Preload commonly used files
export async function preloadSystemFiles(): Promise<void> {
  const systemFiles = ["r/main-system.r", "r/shared/capability-index.r"];

  await Promise.all(
    systemFiles.map((file) =>
      loadRFile(file).catch((err) =>
        console.warn(`Failed to preload ${file}:`, err.message),
      ),
    ),
  );
}

// Clear cache (useful for development)
export function clearCache(): void {
  cache.clear();
}

// Get cache stats
export function getCacheStats() {
  return {
    size: cache.size,
    files: Array.from(cache.keys()),
    lastUpdated: Math.max(
      ...Array.from(cache.values()).map((v) => v.timestamp),
    ),
  };
}
