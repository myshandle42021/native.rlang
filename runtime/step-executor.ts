// runtime/step-executor.ts
// ENHANCED: Auto-generation magic when service modules are missing
// This is where the "wow factor" happens - auto-generates utils/xero.ts when needed

import { evaluateCondition } from "./condition-evaluator";
import { getFunction } from "../utils/runtime";
import { RLangContext, RLangStep, ExecutionResult } from "../schema/types";
import { writeFile, mkdir } from "fs/promises";
import { dirname } from "path";

function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  if (typeof error === "string") {
    return error;
  }
  if (error && typeof error === "object" && "message" in error) {
    return String((error as any).message);
  }
  return String(error);
}

// RCD resolver for dynamic capability resolution
let rcdResolver: Function | null = null;

async function initRCD(): Promise<void> {
  if (rcdResolver) return;

  try {
    const { runRLang } = await import("./interpreter");
    rcdResolver = async (capability: string, context: RLangContext) => {
      const result = await runRLang({
        file: "r/system/dynamic-linker.r",
        operation: "resolve_capability",
        input: { capability },
        context,
      });
      return result.success ? result.result : null;
    };
  } catch (error) {
    console.warn("RCD init failed:", error);
    rcdResolver = () => null;
  }
}

export async function executeSteps(
  steps: RLangStep[],
  context: RLangContext,
  rData: any,
): Promise<ExecutionResult> {
  await initRCD();

  const trace: any[] = [];
  let output: any = null;

  for (const step of steps) {
    try {
      const stepResult = await executeStep(step, context, rData);

      trace.push({
        step: stepResult.stepName,
        input: stepResult.input,
        output: stepResult.output,
        timestamp: new Date().toISOString(),
        success: true,
      });

      if (stepResult.output !== undefined) {
        context.memory = { ...context.memory, ...stepResult.output };
        output = stepResult.output;
      }
    } catch (error) {
      trace.push({
        step: typeof step === "string" ? step : Object.keys(step)[0],
        error: error instanceof Error ? getErrorMessage(error) : String(error),
        timestamp: new Date().toISOString(),
        success: false,
      });

      if (!hasErrorHandling(step)) {
        throw error;
      }
    }
  }

  return { output, context, trace };
}

// 🪄 THE MAGIC HAPPENS HERE - Auto-generation when module missing
async function executeModuleFunction(
  funcPath: string,
  stepValue: any,
  context: RLangContext,
): Promise<{ stepName: string; input: any; output: any }> {
  const [module, funcName] = funcPath.split(".");

  try {
    // Try RCD resolution first
    if (rcdResolver) {
      const rcdResult = await rcdResolver(`${module}_integration`, context);
      if (rcdResult?.provider) {
        const providerModule = await import(`../${rcdResult.provider}`);
        if (providerModule[funcName]) {
          const resolvedArgs = resolveValue(stepValue, context);
          const output = await providerModule[funcName](resolvedArgs, context);
          return { stepName: funcPath, input: resolvedArgs, output };
        }
      }
    }

    // Try to load existing module
    const moduleFile = await import(`../utils/${module}.js`);
    const func = moduleFile[funcName];

    if (!func) {
      throw new Error(`Function ${funcName} not found in ${module}`);
    }

    const resolvedArgs = resolveValue(stepValue, context);
    const output = await func(resolvedArgs, context);
    return { stepName: funcPath, input: resolvedArgs, output };
  } catch (error) {
    // 🎯 AUTO-GENERATION TRIGGER - This is the magic moment!
    if (
      error instanceof Error &&
      (error.message.includes("Cannot resolve module") ||
        error.message.includes("ENOENT") ||
        error.message.includes("does not provide an export"))
    ) {
      console.log(
        `🪄 Service Integration Magic: Auto-generating ${module} module...`,
      );

      // Real-time progress notification
      if (context.input?.channel) {
        try {
          const rocketchat = await getFunction("rocketchat", "sendMessage");
          await rocketchat(
            {
              channel: context.input.channel,
              text: `🔧 **Auto-Generation Triggered**\n\nDetected missing ${module} integration. Generating universal service module...`,
              attachments: [
                {
                  color: "warning",
                  title: "Service Integration Magic",
                  text: `Creating ${module}.ts from universal template`,
                  fields: [
                    { title: "Service", value: module, short: true },
                    { title: "Function", value: funcName, short: true },
                    {
                      title: "Template",
                      value: "service-template.ts",
                      short: true,
                    },
                    { title: "Status", value: "🔄 Generating...", short: true },
                  ],
                },
              ],
            },
            context,
          );
        } catch (notificationError) {
          console.warn(
            "Failed to send auto-generation notification:",
            notificationError,
          );
        }
      }

      // Delegate to service integration template
      const { runRLang } = await import("./interpreter");
      const generationResult = await runRLang({
        file: "r/templates/service-integration.r",
        operation: "auto_generate_service_module",
        input: {
          service_name: module,
          required_function: funcName,
          context: context,
        },
        context: context,
      });

      if (!generationResult.success) {
        throw new Error(`Auto-generation failed: ${generationResult.error}`);
      }

      // Success notification
      if (context.input?.channel) {
        try {
          const rocketchat = await getFunction("rocketchat", "sendMessage");
          await rocketchat(
            {
              channel: context.input.channel,
              text: `✅ **${module} Integration Generated!**`,
              attachments: [
                {
                  color: "good",
                  title: "Module Created Successfully",
                  text: `utils/${module}.ts generated from universal template`,
                  fields: [
                    {
                      title: "Functions",
                      value:
                        generationResult.result?.functions_created?.join(
                          ", ",
                        ) || funcName,
                      short: true,
                    },
                    {
                      title: "Auth Type",
                      value: generationResult.result?.auth_type || "Detected",
                      short: true,
                    },
                  ],
                },
              ],
            },
            context,
          );
        } catch (notificationError) {
          console.warn(
            "Failed to send success notification:",
            notificationError,
          );
        }
      }

      // Now retry the original call with the generated module
      try {
        const generatedModule = await import(`../utils/${module}.js`);
        const generatedFunc = generatedModule[funcName];

        if (!generatedFunc) {
          throw new Error(
            `Generated module ${module} does not export function ${funcName}`,
          );
        }

        const resolvedArgs = resolveValue(stepValue, context);
        const output = await generatedFunc(resolvedArgs, context);

        return {
          stepName: funcPath,
          input: resolvedArgs,
          output: {
            ...output,
            _auto_generated: true,
            _generation_timestamp: new Date().toISOString(),
          },
        };
      } catch (retryError) {
        console.error(
          `Failed to execute generated ${module}.${funcName}:`,
          retryError,
        );
        throw new Error(
          `Generated module execution failed: ${retryError instanceof Error ? retryError.message : String(retryError)}`,
        );
      }
    }

    // If it's not a missing module error, rethrow
    throw error;
  }
}

// All other functions remain unchanged from original step-executor.ts
async function executeStep(step: RLangStep, context: RLangContext, rData: any) {
  if (typeof step === "string") {
    return executeSimpleStep(step, context);
  }

  const stepKey = Object.keys(step)[0];
  const stepValue = (step as any)[stepKey];

  switch (stepKey) {
    case "condition":
      return executeConditionalStep(stepValue, context, rData);
    case "loop":
      return executeLoopStep(stepValue, context, rData);
    case "run":
      return executeRunStep(stepValue, context);
    case "respond":
      return executeRespondStep(stepValue, context);
    case "prompt.user":
      return executePromptUserStep(stepValue, context);
    case "self.modify":
      return executeSelfModifyStep(stepValue, context);
    case "self.reflect":
      return executeSelfReflectStep(stepValue, context);
    default:
      return executeModuleFunction(stepKey, stepValue, context);
  }
}

async function executeSimpleStep(step: string, context: RLangContext) {
  const [funcName, ...args] = step.split(":").map((s) => s.trim());
  const input = args.length > 0 ? args.join(":") : undefined;
  const func = await getFunction("core", funcName);
  const output = await func(input, context);
  return { stepName: funcName, input, output };
}

async function executeConditionalStep(
  condition: any,
  context: RLangContext,
  rData: any,
) {
  const shouldExecute = evaluateCondition(
    condition.if || condition.condition,
    context,
  );
  if (shouldExecute && condition.then) {
    const result = await executeSteps(condition.then, context, rData);
    return { stepName: "condition", input: condition, output: result.output };
  } else if (!shouldExecute && condition.else) {
    const result = await executeSteps(condition.else, context, rData);
    return { stepName: "condition", input: condition, output: result.output };
  }
  return { stepName: "condition", input: condition, output: null };
}

async function executeLoopStep(loop: any, context: RLangContext, rData: any) {
  const results: any[] = [];
  if (loop.forEach) {
    const items = resolveValue(loop.forEach, context);
    for (const item of items) {
      const loopContext = { ...context, memory: { ...context.memory, item } };
      const result = await executeSteps(loop.do, loopContext, rData);
      results.push(result.output);
    }
  } else if (loop.while) {
    while (evaluateCondition(loop.while, context)) {
      const result = await executeSteps(loop.do, context, rData);
      results.push(result.output);
    }
  }
  return { stepName: "loop", input: loop, output: results };
}

async function executeRunStep(run: any, context: RLangContext) {
  const { runRLang } = await import("./interpreter");
  if (typeof run === "string") {
    const result = await runRLang({ file: run, context });
    return { stepName: "run", input: run, output: result.result };
  } else {
    const result = await runRLang({
      file: run.file || run[0],
      operation: run.operation || run[1],
      input: run.input,
      context,
      clientId: context.clientId,
    });
    return { stepName: "run", input: run, output: result.result };
  }
}

async function executeRespondStep(respond: any, context: RLangContext) {
  const rocketchat = await getFunction("rocketchat", "sendMessage");
  const message = typeof respond === "string" ? respond : respond.message;
  const to = respond.to || context.input?.user || context.input?.channel;
  const output = await rocketchat({ to, message }, context);
  return { stepName: "respond", input: respond, output };
}

async function executePromptUserStep(prompt: any, context: RLangContext) {
  const rocketchat = await getFunction("rocketchat", "promptUser");
  const output = await rocketchat(prompt, context);
  return { stepName: "prompt.user", input: prompt, output };
}

async function executeSelfModifyStep(modify: any, context: RLangContext) {
  const generateAgent = await getFunction("core", "generateAgent");
  const output = await generateAgent(modify, context);
  return { stepName: "self.modify", input: modify, output };
}

async function executeSelfReflectStep(reflect: any, context: RLangContext) {
  const infer = await getFunction("infer", "reflect");
  const output = await infer(reflect, context);
  return { stepName: "self.reflect", input: reflect, output };
}

// 🔧 Universal Service Module Generator
async function generateServiceModule(
  serviceName: string,
  serviceConfig: any,
  context: RLangContext,
): Promise<string> {
  const template = `// utils/${serviceName}.ts - Auto-generated from universal template
// Generated by ROL3 Service Integration Magic

import { authenticate, makeRequest } from "../templates/service-template";
import { RLangContext } from "../schema/types";

// Service-specific configuration
const SERVICE_CONFIG = ${JSON.stringify(serviceConfig, null, 2)};

// Universal functions with ${serviceName} context
export async function authenticate(args: any, context: RLangContext) {
  context.memory.current_service = "${serviceName}";
  const serviceModule = await import("../templates/service-template");
  return serviceModule.authenticate(args, context);
}

export async function makeRequest(method: string, endpoint: string, data: any, context: RLangContext) {
  context.memory.current_service = "${serviceName}";
  const serviceModule = await import("../templates/service-template");
  return serviceModule.makeRequest(method, endpoint, data, context);
}

// Generated service-specific functions
${generateServiceSpecificFunctions(serviceName, serviceConfig)}

// Export service configuration for runtime access
export const config = SERVICE_CONFIG;
`;

  return template;
}

function generateServiceSpecificFunctions(
  serviceName: string,
  config: any,
): string {
  const functions = [];

  // Generate common functions based on service type
  if (config.endpoints) {
    for (const [endpointName, endpointPath] of Object.entries(
      config.endpoints,
    )) {
      const functionName = endpointNameToFunction(endpointName);
      functions.push(`
export async function ${functionName}(args: any, context: RLangContext) {
  context.memory.current_service = "${serviceName}";
  return makeRequest("${getHttpMethod(endpointName)}", "${endpointName}", args, context);
}`);
    }
  }

  // Add service-specific aliases
  if (serviceName === "xero") {
    functions.push(`
// Xero-specific convenience functions
export const getInvoices = (args: any, context: RLangContext) => makeRequest("GET", "get_invoices", args, context);
export const getContacts = (args: any, context: RLangContext) => makeRequest("GET", "get_contacts", args, context);
export const getPayments = (args: any, context: RLangContext) => makeRequest("GET", "get_payments", args, context);
export const getOrganisation = (args: any, context: RLangContext) => makeRequest("GET", "get_organisation", args, context);
`);
  } else if (serviceName === "slack") {
    functions.push(`
// Slack-specific convenience functions
export const sendMessage = (args: any, context: RLangContext) => makeRequest("POST", "send_message", args, context);
export const postMessage = sendMessage;
export const uploadFile = (args: any, context: RLangContext) => makeRequest("POST", "upload_file", args, context);
`);
  }

  return functions.join("\n");
}

function endpointNameToFunction(endpointName: string): string {
  return endpointName.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
}

function getHttpMethod(endpointName: string): string {
  if (endpointName.startsWith("get_") || endpointName.includes("list"))
    return "GET";
  if (endpointName.startsWith("create_") || endpointName.includes("post"))
    return "POST";
  if (endpointName.startsWith("update_") || endpointName.includes("put"))
    return "PUT";
  if (endpointName.startsWith("delete_")) return "DELETE";
  return "GET"; // Default
}

function resolveValue(value: any, context: RLangContext): any {
  if (value === undefined || value === null) return value;
  if (typeof value === "string" && value.includes("${")) {
    try {
      return value.replace(/\$\{([^}]+)\}/g, (match, path) => {
        const keys = path.split(".");
        let result: any = context;
        for (const key of keys) {
          result = result?.[key];
        }
        return String(result ?? match);
      });
    } catch (err) {
      return value;
    }
  }
  if (Array.isArray(value)) {
    return value.map((item) => resolveValue(item, context));
  }
  if (typeof value === "object" && value !== null) {
    const resolved: any = {};
    for (const [key, val] of Object.entries(value)) {
      resolved[key] = resolveValue(val, context);
    }
    return resolved;
  }
  return value;
}

function hasErrorHandling(step: RLangStep): boolean {
  return (
    typeof step === "object" &&
    step !== null &&
    ("onError" in step || "catch" in step)
  );
}
