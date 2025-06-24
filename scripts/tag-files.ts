#!/usr/bin/env tsx
// scripts/tag-files.ts
// Local TypeScript script to pre-tag files and populate RCD database

import { readdir, readFile, writeFile } from "fs/promises";
import { join, extname, relative } from "path";
import { createHash } from "crypto";

// Import your database connection
import { db } from "../utils/db";

interface FileMetadata {
  file_path: string;
  file_type: string;
  capabilities: string[];
  dependencies: string[];
  meta_tags: Record<string, any>;
  content_hash: string;
  last_analyzed: string;
  performance_score?: number;
  usage_frequency?: number;
}

// File analysis patterns
const PATTERNS = {
  typescript: {
    extensions: [".ts", ".js"],
    baseCapabilities: ["typescript_execution"],
    detect: (content: string): string[] => {
      const caps: string[] = [];
      if (content.includes("export")) caps.push("module_export");
      if (content.includes("import")) caps.push("module_import");
      if (content.includes("await")) caps.push("async_execution");
      if (content.includes("class")) caps.push("class_definition");
      if (content.includes("function")) caps.push("function_definition");
      if (content.includes("interface")) caps.push("type_definition");
      if (content.includes("type ")) caps.push("type_definition");
      if (content.includes("Promise")) caps.push("promise_handling");
      if (content.includes("runRLang")) caps.push("rlang_integration");
      return caps;
    },
  },
  rlang: {
    extensions: [".r"],
    baseCapabilities: ["rlang_execution"],
    detect: (content: string): string[] => {
      const caps: string[] = [];
      if (content.includes("operations:")) caps.push("operation_definition");
      if (content.includes("aam:")) caps.push("access_control");
      if (content.includes("self:")) caps.push("self_awareness");
      if (content.includes("rcd:")) caps.push("rcd_metadata");
      if (content.includes("condition:")) caps.push("conditional_logic");
      if (content.includes("loop:")) caps.push("iteration_logic");
      if (content.includes("run:")) caps.push("agent_orchestration");
      if (content.includes("tamr.log")) caps.push("logging_capability");

      // Detect specific system roles
      if (
        content.includes('"system-doctor"') ||
        content.includes("system_health")
      )
        caps.push("system_monitoring");
      if (content.includes("bootstrap") || content.includes("startup"))
        caps.push("system_bootstrap");
      if (content.includes("capability_resolution"))
        caps.push("dynamic_linking");
      if (content.includes("file_track") || content.includes("analyze_file"))
        caps.push("file_analysis");

      return caps;
    },
  },
};

async function scanDirectory(
  dir: string,
  results: string[] = [],
): Promise<string[]> {
  try {
    const entries = await readdir(dir, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = join(dir, entry.name);

      if (entry.isDirectory()) {
        // Skip common build/dependency directories
        if (
          ![
            "node_modules",
            ".git",
            "dist",
            "build",
            ".next",
            "coverage",
          ].includes(entry.name)
        ) {
          await scanDirectory(fullPath, results);
        }
      } else if (entry.isFile()) {
        const ext = extname(entry.name);
        if ([".ts", ".js", ".r"].includes(ext)) {
          results.push(fullPath);
        }
      }
    }
  } catch (error) {
    console.warn(`Skip directory ${dir}:`, (error as Error).message);
  }

  return results;
}

async function analyzeFile(filePath: string): Promise<FileMetadata> {
  const content = await readFile(filePath, "utf-8");
  const ext = extname(filePath);
  const relativePath = relative(process.cwd(), filePath);

  let fileType: string;
  let capabilities: string[] = [];

  if ([".ts", ".js"].includes(ext)) {
    fileType = "typescript";
    capabilities = [
      ...PATTERNS.typescript.baseCapabilities,
      ...PATTERNS.typescript.detect(content),
    ];
  } else if (ext === ".r") {
    fileType = "rlang";
    capabilities = [
      ...PATTERNS.rlang.baseCapabilities,
      ...PATTERNS.rlang.detect(content),
    ];
  } else {
    fileType = "unknown";
  }

  // Extract dependencies
  const dependencies: string[] = [];
  const importMatches = content.match(
    /(?:import.*from\s+['"]([^'"]+)['"]|require\(['"]([^'"]+)['"]\))/g,
  );
  if (importMatches) {
    importMatches.forEach((match) => {
      const dep = match.match(/['"]([^'"]+)['"]/)?.[1];
      if (dep && !dep.startsWith(".") && !dep.startsWith("/")) {
        dependencies.push(dep);
      }
    });
  }

  // Calculate metrics
  const lines = content.split("\n").length;
  const complexity =
    lines < 50 ? 1 : lines < 200 ? 2 : lines < 500 ? 3 : lines < 1000 ? 4 : 5;

  // Determine system role and stability
  let systemRole = "application";
  let stability = "stable";

  if (relativePath.includes("/system/")) {
    systemRole = "system_core";
    stability = "critical";
  } else if (relativePath.includes("/agents/")) {
    systemRole = "agent";
    stability = "stable";
  } else if (relativePath.includes("/utils/")) {
    systemRole = "utility";
    stability = "stable";
  }

  return {
    file_path: relativePath,
    file_type: fileType,
    capabilities: [...new Set(capabilities)],
    dependencies: [...new Set(dependencies)],
    meta_tags: {
      system_role: systemRole,
      stability_level: stability,
      complexity_score: complexity,
      lines_of_code: lines,
      last_modified: new Date().toISOString(),
      tagged_locally: true,
      full_path: filePath,
    },
    content_hash: createHash("md5").update(content).digest("hex"),
    last_analyzed: new Date().toISOString(),
    performance_score: 1.0,
    usage_frequency: 0,
  };
}

async function ensureRCDSchema(): Promise<void> {
  console.log("🗄️ Ensuring RCD database schema exists...");

  try {
    // Create rcd_files table if it doesn't exist
    await db.query(`
      CREATE TABLE IF NOT EXISTS rcd_files (
        id SERIAL PRIMARY KEY,
        file_path TEXT UNIQUE NOT NULL,
        file_type TEXT NOT NULL,
        capabilities TEXT[],
        dependencies TEXT[],
        meta_tags JSONB,
        content_hash TEXT,
        last_analyzed TIMESTAMP DEFAULT NOW(),
        performance_score FLOAT DEFAULT 1.0,
        usage_frequency INTEGER DEFAULT 0
      )
    `);

    console.log("✅ RCD schema ready");
  } catch (error) {
    console.error("💥 Failed to create RCD schema:", error);
    throw error;
  }
}

async function storeFileMetadata(metadata: FileMetadata): Promise<void> {
  try {
    // Use the structure that matches your current db.ts implementation
    const { data, error } = await db
      .from("rcd_files")
      .insert(metadata)
      .on("file_path") // This triggers conflict resolution
      .execute(); // Explicitly call execute

    if (error) {
      throw error;
    }
  } catch (error) {
    console.error(`Failed to store metadata for ${metadata.file_path}:`, error);
  }
}

async function main(): Promise<void> {
  console.log("🏷️ Starting local file tagging...");

  try {
    // Ensure database schema exists
    await ensureRCDSchema();

    // Scan for files
    console.log("🔍 Scanning for files...");
    const files = await scanDirectory(".");
    console.log(`📁 Found ${files.length} files to analyze`);

    // Analyze and store each file
    let successCount = 0;
    let errorCount = 0;

    for (const file of files) {
      try {
        console.log(`📝 Analyzing: ${relative(process.cwd(), file)}`);
        const metadata = await analyzeFile(file);
        await storeFileMetadata(metadata);
        successCount++;

        // Show capabilities for important files
        if (metadata.capabilities.length > 2) {
          console.log(
            `   ⚡ Capabilities: ${metadata.capabilities.join(", ")}`,
          );
        }
      } catch (error) {
        console.error(
          `❌ Failed to analyze ${file}:`,
          (error as Error).message,
        );
        errorCount++;
      }
    }

    // Summary
    console.log("\n🎉 Tagging complete!");
    console.log(`✅ Successfully tagged: ${successCount} files`);
    console.log(`❌ Failed: ${errorCount} files`);

    // Verify database content
    const { data: countData } = await db
      .from("rcd_files")
      .select("id")
      .execute();
    const count = countData?.length || 0;
    console.log(`🗄️ Total files in RCD database: ${count}`);

    // Show some sample entries
    const { data: samples } = await db
      .from("rcd_files")
      .select("file_path, capabilities")
      .eq("file_type", "rlang")
      .limit(5)
      .execute();

    console.log("\n📋 Sample RCD entries:");
    if (samples && samples.length > 0) {
      samples.forEach((sample) => {
        console.log(
          `   ${sample.file_path}: [${sample.capabilities?.join(", ") || "no capabilities"}]`,
        );
      });
    } else {
      console.log("   No sample entries found");
    }
  } catch (error) {
    console.error("💥 Tagging failed:", error);
    process.exit(1);
  }
}

// Run the script
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}
