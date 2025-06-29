// utils/validate_extracted_intent.ts
// Intent validation module for agent creation pipeline

import { RLangContext } from "../schema/types";

export async function undefined(args: any, context: RLangContext) {
  // Handle the "undefined" function call from the R-lang file
  return validateExtractedIntent(args, context);
}

// Helper function to safely stringify objects with circular references
function safeStringify(obj: any, maxDepth = 3): string {
  const seen = new WeakSet();

  return JSON.stringify(
    obj,
    (key, value) => {
      if (typeof value === "object" && value !== null) {
        if (seen.has(value)) {
          return "[Circular Reference]";
        }
        seen.add(value);
      }
      return value;
    },
    2,
  );
}

export async function validateExtractedIntent(
  args: any,
  context: RLangContext,
) {
  try {
    // 🔍 DEBUG LOGGING - Use safe stringify
    console.log("🔍 DEBUG - Raw validation args:");
    console.log(safeStringify(args));

    console.log("🔍 DEBUG - Context input:");
    console.log(safeStringify(context.input));

    // Don't log full context memory due to circular references
    console.log("🔍 DEBUG - Context metadata:");
    console.log(
      safeStringify({
        user: context.user,
        agentId: context.agentId,
        operation: context.operation,
        timestamp: context.timestamp,
      }),
    );

    const extracted = args.extracted || args;
    console.log("🔍 DEBUG - Extracted data type:", typeof extracted);

    // Check if extracted is still a template variable
    if (typeof extracted === "string" && extracted.includes("${")) {
      console.log(
        "⚠️ DEBUG - Extracted contains template variables:",
        extracted,
      );
      console.log(
        "🔧 DEBUG - This suggests LLM response wasn't properly resolved",
      );

      // Return a basic validation result for now
      return {
        incomplete_fields: ["llm_response_not_resolved"],
        completeness_score: 0,
        confidence: 0.5,
        validated_intent: {
          agent_requirements: {
            agent_type: "integration",
            primary_purpose: "Unknown - LLM response not resolved",
          },
          system_integrations: {
            required_services: ["to_be_determined"],
          },
        },
        debug_info: {
          issue: "LLM response contains unresolved template variables",
          raw_extracted: extracted,
        },
      };
    }

    // Parse if it's a string (YAML/JSON response from LLM)
    let intentData = extracted;
    if (typeof extracted === "string") {
      console.log("🔍 DEBUG - Extracted is string, attempting to parse...");
      try {
        // Try JSON first
        intentData = JSON.parse(extracted);
        console.log("🔍 DEBUG - Successfully parsed as JSON");
      } catch {
        console.log("🔍 DEBUG - JSON parse failed, trying YAML...");
        // If JSON fails, try basic YAML parsing
        intentData = parseBasicYaml(extracted);
        console.log("🔍 DEBUG - YAML parsed result");
      }
    } else {
      console.log("🔍 DEBUG - Extracted is not string, using as-is");
    }

    // Required fields for agent creation
    const requiredFields = [
      "agent_requirements.agent_type",
      "agent_requirements.primary_purpose",
      "system_integrations.required_services",
    ];

    console.log("🔍 DEBUG - Required fields:", requiredFields);

    const validation = {
      incomplete_fields: [] as string[],
      completeness_score: 0,
      confidence: 0.8,
      validated_intent: intentData,
    };

    // Check for required fields
    for (const field of requiredFields) {
      const fieldValue = getNestedValue(intentData, field);
      console.log(`🔍 DEBUG - Checking field "${field}":`, fieldValue);
      if (!fieldValue) {
        validation.incomplete_fields.push(field);
        console.log(`❌ DEBUG - Missing field: ${field}`);
      } else {
        console.log(`✅ DEBUG - Found field: ${field}`);
      }
    }

    // Calculate completeness score
    const totalFields = requiredFields.length;
    const completedFields = totalFields - validation.incomplete_fields.length;
    validation.completeness_score = Math.round(
      (completedFields / totalFields) * 100,
    );

    console.log(
      `🎯 DEBUG - Validation complete: ${validation.completeness_score}% (${completedFields}/${totalFields} fields)`,
    );

    if (validation.incomplete_fields.length > 0) {
      console.log("📋 DEBUG - Missing fields:", validation.incomplete_fields);
    }

    return validation;
  } catch (error) {
    console.error("❌ DEBUG - Intent validation error:", error);
    console.error(
      "❌ DEBUG - Error stack:",
      error instanceof Error ? error.stack : String(error),
    );

    return {
      incomplete_fields: ["validation_error"],
      completeness_score: 0,
      confidence: 0.1,
      validated_intent: {},
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

// Basic YAML parser for simple cases
function parseBasicYaml(yamlString: string): any {
  const result: any = {};
  const lines = yamlString.split("\n");

  let currentObject = result;
  let objectStack: any[] = [result];

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;

    const indentLevel = (line.match(/^(\s*)/)?.[1]?.length || 0) / 2;

    // Adjust object stack based on indentation
    while (objectStack.length > indentLevel + 1) {
      objectStack.pop();
    }
    currentObject = objectStack[objectStack.length - 1];

    if (trimmed.includes(":")) {
      const [key, ...valueParts] = trimmed.split(":");
      const value = valueParts.join(":").trim();

      if (value === "" || value === "{}" || value === "[]") {
        // New object or array
        currentObject[key.trim()] = {};
        objectStack.push(currentObject[key.trim()]);
      } else if (value.startsWith("[") && value.endsWith("]")) {
        // Array value
        const arrayContent = value.slice(1, -1);
        currentObject[key.trim()] = arrayContent
          .split(",")
          .map((item) => item.trim().replace(/['"]/g, ""));
      } else {
        // Simple value
        currentObject[key.trim()] = value.replace(/['"]/g, "");
      }
    }
  }

  return result;
}

function getNestedValue(obj: any, path: string): any {
  return path.split(".").reduce((current, key) => current?.[key], obj);
}

function setNestedValue(obj: any, path: string, value: any): void {
  const keys = path.split(".");
  const lastKey = keys.pop()!;
  const target = keys.reduce((current, key) => {
    if (!current[key]) current[key] = {};
    return current[key];
  }, obj);
  target[lastKey] = value;
}

function enhanceWithDefaults(intentData: any, originalArgs: any): any {
  const enhanced = { ...intentData };

  // Ensure agent_requirements exists
  if (!enhanced.agent_requirements) {
    enhanced.agent_requirements = {};
  }

  // Default agent type based on request
  if (!enhanced.agent_requirements.agent_type) {
    const request = originalArgs.user_input || originalArgs.text || "";
    if (
      request.toLowerCase().includes("expense") ||
      request.toLowerCase().includes("finance")
    ) {
      enhanced.agent_requirements.agent_type = "finance_processor";
    } else if (
      request.toLowerCase().includes("data") ||
      request.toLowerCase().includes("analysis")
    ) {
      enhanced.agent_requirements.agent_type = "data_analysis";
    } else {
      enhanced.agent_requirements.agent_type = "custom";
    }
  }

  // Default primary purpose
  if (!enhanced.agent_requirements.primary_purpose) {
    enhanced.agent_requirements.primary_purpose =
      "Process user requests and provide data insights";
  }

  // Ensure system_integrations exists
  if (!enhanced.system_integrations) {
    enhanced.system_integrations = {};
  }

  // Default required services
  if (!enhanced.system_integrations.required_services) {
    enhanced.system_integrations.required_services = ["xero"];
  }

  return enhanced;
}

// Export aliases for R-lang compatibility
export const validate_extracted_intent = validateExtractedIntent;
