// utils/runtime.ts
// MINIMAL TypeScript - 90/10 rule compliant
// All RCD logic moved to r/system/dynamic-linker.r

import { RLangContext } from "../schema/types";

// Keep existing function registry (no changes to core functionality)
const functionRegistry: Map<string, Map<string, Function>> = new Map();

// MINIMAL: One-line RCD delegation
let rcdDelegate: Function | null = null;

async function initRCD(): Promise<void> {
  if (rcdDelegate) return;

  try {
    const { runRLang } = await import("../runtime/interpreter");
    rcdDelegate = async (
      operation: string,
      input: any,
      context: RLangContext,
    ) => {
      const result = await runRLang({
        file: "r/system/dynamic-linker.r",
        operation,
        input,
        context,
      });
      return result.success ? result.result : null;
    };
  } catch (error) {
    console.warn("RCD delegate init failed:", error);
    rcdDelegate = () => null;
  }
}

// UNCHANGED: Existing function registration with optional RCD notification
export async function registerFunction(
  module: string,
  functionName: string,
  fn: Function,
): Promise<boolean> {
  try {
    // Traditional registration (unchanged)
    if (!functionRegistry.has(module)) {
      functionRegistry.set(module, new Map());
    }
    functionRegistry.get(module)!.set(functionName, fn);

    // MINIMAL: Notify RCD system (one line)
    if (rcdDelegate) {
      await rcdDelegate(
        "register_capability",
        {
          module,
          function: functionName,
          provider: `utils/${module}.ts`,
        },
        { agentId: "runtime", clientId: "system" } as RLangContext,
      );
    }

    return true;
  } catch (error) {
    console.error(
      `Failed to register function ${module}.${functionName}:`,
      error,
    );
    return false;
  }
}

// ENHANCED: Try RCD first, fallback unchanged
export async function getFunction(
  module: string,
  functionName: string,
  context?: RLangContext,
): Promise<Function> {
  await initRCD();

  try {
    // TRY: RCD resolution (one line delegation)
    if (rcdDelegate && context) {
      const rcdResult = await rcdDelegate(
        "resolve_capability",
        {
          capability: `${module}_${functionName}`,
          consumer: context.agentId,
        },
        context,
      );

      if (rcdResult?.provider) {
        const providerModule = await import(
          `../${rcdResult.provider.replace(".ts", ".js")}`
        );
        if (providerModule[functionName]) {
          return providerModule[functionName];
        }
      }
    }

    // FALLBACK: Existing logic unchanged
    const moduleRegistry = functionRegistry.get(module);
    if (moduleRegistry && moduleRegistry.has(functionName)) {
      return moduleRegistry.get(functionName)!;
    }

    // Dynamic import fallback (unchanged)
    const dynamicModule = await import(`../${module}`);
    if (dynamicModule[functionName]) {
      await registerFunction(module, functionName, dynamicModule[functionName]);
      return dynamicModule[functionName];
    }

    throw new Error(`Function ${functionName} not found in module ${module}`);
  } catch (error) {
    console.error(
      `Function resolution failed for ${module}.${functionName}:`,
      error,
    );
    throw error;
  }
}

// UNCHANGED: Existing function listing
export async function listFunctions(module?: string): Promise<string[]> {
  const functions: string[] = [];

  if (module) {
    const moduleRegistry = functionRegistry.get(module);
    if (moduleRegistry) {
      functions.push(...Array.from(moduleRegistry.keys()));
    }
  } else {
    for (const [mod, registry] of functionRegistry.entries()) {
      for (const funcName of registry.keys()) {
        functions.push(`${mod}.${funcName}`);
      }
    }
  }

  return functions.sort();
}

// UNCHANGED: Performance monitoring
export function getRuntimeStats(): {
  registeredFunctions: number;
  moduleCount: number;
  rcdEnabled: boolean;
} {
  let totalFunctions = 0;
  for (const moduleRegistry of functionRegistry.values()) {
    totalFunctions += moduleRegistry.size;
  }

  return {
    registeredFunctions: totalFunctions,
    moduleCount: functionRegistry.size,
    rcdEnabled: !!rcdDelegate,
  };
}

// Initialize on module load
initRCD().catch(console.warn);

// Export existing registry for compatibility
export { functionRegistry };
