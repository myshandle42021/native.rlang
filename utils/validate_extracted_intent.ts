// utils/validate_extracted_intent.ts
// Intent validation module for agent creation pipeline

import { RLangContext } from "../schema/types";

export async function undefined(args: any, context: RLangContext) {
  // Handle the "undefined" function call from the R-lang file
  return validateExtractedIntent(args, context);
}

export async function validateExtractedIntent(
  args: any,
  context: RLangContext,
) {
  try {
    // 🔍 DEBUG LOGGING - Add this at the beginning
    console.log(
      "🔍 DEBUG - Raw validation args:",
      JSON.stringify(args, null, 2),
    );
    console.log(
      "🔍 DEBUG - Context input:",
      JSON.stringify(context.input, null, 2),
    );
    console.log(
      "🔍 DEBUG - Context memory:",
      JSON.stringify(context.memory, null, 2),
    );

    const extracted = args.extracted || args;
    console.log("🔍 DEBUG - Extracted data type:", typeof extracted);
    console.log(
      "🔍 DEBUG - Extracted data:",
      JSON.stringify(extracted, null, 2),
    );

    // Parse if it's a string (YAML/JSON response from LLM)
    let intentData = extracted;
    if (typeof extracted === "string") {
      console.log("🔍 DEBUG - Extracted is string, attempting to parse...");
      try {
        // Try JSON first
        intentData = JSON.parse(extracted);
        console.log(
          "🔍 DEBUG - Successfully parsed as JSON:",
          JSON.stringify(intentData, null, 2),
        );
      } catch {
        console.log("🔍 DEBUG - JSON parse failed, trying YAML...");
        // If JSON fails, try basic YAML parsing
        intentData = parseBasicYaml(extracted);
        console.log(
          "🔍 DEBUG - YAML parsed result:",
          JSON.stringify(intentData, null, 2),
        );
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
        console.log(
          `✅ DEBUG - Found field: ${field} = ${JSON.stringify(fieldValue)}`,
        );
      }
    }

    console.log("🔍 DEBUG - Incomplete fields:", validation.incomplete_fields);

    // Calculate completeness score
    const totalFields = requiredFields.length;
    const completeFields = totalFields - validation.incomplete_fields.length;
    validation.completeness_score = completeFields / totalFields;

    console.log(`🔍 DEBUG - Complete fields: ${completeFields}/${totalFields}`);
    console.log(
      `🔍 DEBUG - Completeness score: ${validation.completeness_score}`,
    );

    // Enhance with defaults if missing
    if (validation.incomplete_fields.length > 0) {
      console.log("🔍 DEBUG - Enhancing with defaults...");
      validation.validated_intent = enhanceWithDefaults(intentData, args);
      console.log(
        "🔍 DEBUG - Enhanced intent:",
        JSON.stringify(validation.validated_intent, null, 2),
      );
    }

    console.log(
      `✅ Intent validation: ${validation.completeness_score * 100}% complete`,
    );
    console.log(
      "🔍 DEBUG - Final validation result:",
      JSON.stringify(validation, null, 2),
    );

    return validation;
  } catch (error) {
    console.error("❌ DEBUG - Intent validation error:", error);
    console.error(
      "❌ DEBUG - Error stack:",
      error instanceof Error ? error.stack : "No stack trace",
    );
    return {
      incomplete_fields: ["validation_error"],
      completeness_score: 0,
      confidence: 0.1,
      error: error instanceof Error ? error.message : String(error),
      validated_intent: args.extracted || {},
    };
  }
}

function parseBasicYaml(yamlString: string): any {
  // Basic YAML parser for agent requirements
  const lines = yamlString.split("\n");
  const result: any = {};
  let currentObject: any = result;
  let currentPath: string[] = [];

  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;

    const indent = line.length - line.trimStart().length;
    const colonIndex = trimmed.indexOf(":");

    if (colonIndex > 0) {
      const key = trimmed.substring(0, colonIndex).trim();
      const value = trimmed.substring(colonIndex + 1).trim();

      // Adjust path based on indent
      if (indent === 0) {
        currentPath = [key];
        currentObject = result;
        setNestedValue(result, key, value || {});
      } else {
        // Nested property
        const nestedPath = [...currentPath, key];
        setNestedValue(result, nestedPath.join("."), value || key);
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
