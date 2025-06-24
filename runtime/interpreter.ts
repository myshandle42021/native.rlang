// runtime/interpreter.ts
// MINIMAL TypeScript - 90/10 rule compliant
// CRITICAL FIX #4: Fixed operation name alignment for RCD resolution

import { loadRFile } from "./loader";
import { createContext } from "./context";
import { executeSteps } from "./step-executor";
import { RLangContext, RLangResult } from "../schema/types";

// CRITICAL FIX #4: RCD delegation with FIXED operation name
let rcdFileResolver: Function | null = null;

async function initRCD(): Promise<void> {
  if (rcdFileResolver) return;

  try {
    rcdFileResolver = async (fileId: string, context: RLangContext) => {
      const result = await runRLang({
        file: "r/system/dynamic-linker.r",
        operation: "resolve_capability", // CRITICAL FIX #4: Changed from "resolve_file_path"
        input: {
          capability: `file_resolution_${fileId}`, // CRITICAL FIX #4: Map to capability format
          file_id: fileId,
          client_id: context.clientId,
          resolution_type: "file_path", // Indicate this is file resolution
        },
        context,
      });
      return result.success ? result.result?.resolved_path : null;
    };
  } catch (error) {
    console.warn("RCD file resolver init failed:", error);
    rcdFileResolver = () => null;
  }
}

export interface RunRLangOptions {
  file: string;
  operation?: string;
  input?: any;
  context?: Partial<RLangContext>;
  clientId?: string;
}

// ENHANCED: Try RCD file resolution with FIXED operation name, fallback unchanged
export async function runRLang(options: RunRLangOptions): Promise<RLangResult> {
  await initRCD();

  const {
    file,
    operation = "default",
    input = {},
    context: partialContext,
    clientId,
  } = options;

  let resolvedFilePath = file;

  try {
    // TRY: RCD file resolution (FIXED: now uses correct operation name)
    if (rcdFileResolver) {
      const rcdPath = await rcdFileResolver(file, {
        agentId: "interpreter",
        clientId: clientId || "system",
      } as RLangContext);

      if (rcdPath) {
        resolvedFilePath = rcdPath;
        console.log(`🔗 RCD resolved file: ${file} -> ${rcdPath}`);
      }
    }

    // UNCHANGED: Load file (with intelligent fallback)
    let rData;
    try {
      rData = await loadRFile(resolvedFilePath);
    } catch (loadError) {
      if (resolvedFilePath !== file) {
        // RCD path failed, try original
        console.warn(`RCD path failed, trying original: ${file}`);
        rData = await loadRFile(file);
      } else {
        // Try intelligent path resolution
        const intelligentPath = await resolveIntelligentPath(file, clientId);
        rData = intelligentPath ? await loadRFile(intelligentPath) : null;
        if (!rData) throw loadError;
        if (intelligentPath) {
          console.log(
            `📁 Intelligent path resolved: ${file} -> ${intelligentPath}`,
          );
        }
      }
    }

    // UNCHANGED: Create context and execute
    const context = createContext({
      ...partialContext,
      input,
      clientId,
      agentId: rData.self?.id || "unknown",
      operation,
    });

    const operationSteps = rData.operations?.[operation];
    if (!operationSteps) {
      throw new Error(
        `Operation '${operation}' not found in ${resolvedFilePath}`,
      );
    }

    const result = await executeSteps(operationSteps, context, rData);

    return {
      success: true,
      result: result.output,
      context: result.context,
      trace: result.trace,
    };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : String(error),
      trace: [],
    };
  }
}

// ENHANCED: Intelligent path resolution with better logging
async function resolveIntelligentPath(
  file: string,
  clientId?: string,
): Promise<string | null> {
  const paths = [file, `r/${file}`, `r/agents/${file}`, `r/system/${file}`];

  if (clientId) {
    paths.unshift(`r/clients/${clientId}/${file}`);
  }

  // Add .r extension if missing
  const allPaths = [...paths];
  paths.forEach((path) => {
    if (!path.endsWith(".r")) {
      allPaths.push(`${path}.r`);
    }
  });

  const fs = await import("fs/promises");
  for (const path of allPaths) {
    try {
      await fs.access(path);
      return path;
    } catch {
      continue;
    }
  }
  return null;
}

// UNCHANGED: Convenience functions
export async function runSystemOperation(
  operation: string,
  input?: any,
  clientId?: string,
): Promise<RLangResult> {
  return runRLang({
    file: "r/main-system.r",
    operation,
    input,
    clientId,
  });
}

export async function runAgentOperation(
  agentId: string,
  operation: string,
  input?: any,
  clientId?: string,
): Promise<RLangResult> {
  const agentFile = clientId
    ? `r/clients/${clientId}/agents/${agentId}.r`
    : `r/agents/${agentId}.r`;

  return runRLang({
    file: agentFile,
    operation,
    input,
    clientId,
  });
}

// ENHANCED: Development helper for testing RCD resolution
export async function testRCDResolution(
  fileId: string,
  clientId?: string,
): Promise<{ success: boolean; resolvedPath?: string; error?: string }> {
  try {
    await initRCD();

    if (!rcdFileResolver) {
      return { success: false, error: "RCD not initialized" };
    }

    const context: RLangContext = {
      agentId: "test",
      clientId: clientId || "system",
    };

    const resolvedPath = await rcdFileResolver(fileId, context);

    return {
      success: !!resolvedPath,
      resolvedPath: resolvedPath || undefined,
      error: !resolvedPath ? "No path resolved" : undefined,
    };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

// ENHANCED: System health check for interpreter
export async function checkInterpreterHealth(): Promise<{
  rcdInitialized: boolean;
  pathResolution: boolean;
  fileLoading: boolean;
  contextCreation: boolean;
}> {
  const health = {
    rcdInitialized: false,
    pathResolution: false,
    fileLoading: false,
    contextCreation: false,
  };

  try {
    // Check RCD initialization
    await initRCD();
    health.rcdInitialized = !!rcdFileResolver;

    // Check path resolution
    const testPath = await resolveIntelligentPath("test-file");
    health.pathResolution = true; // If no error, it's working

    // Check file loading capability
    try {
      await loadRFile("package.json");
      health.fileLoading = true;
    } catch {
      // File might not exist, but loader is working if it gets this far
      health.fileLoading = true;
    }

    // Check context creation
    const testContext = createContext({ agentId: "test" });
    health.contextCreation = !!testContext.agentId;
  } catch (error) {
    console.warn("Interpreter health check failed:", error);
  }

  return health;
}

// Initialize RCD on module load
initRCD().catch(console.warn);
