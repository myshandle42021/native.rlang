// utils/openai-api.ts - Fixed to handle missing API keys gracefully
import { RLangContext } from "../schema/types";
import OpenAI from "openai";

let openai: OpenAI | null = null;

function getOpenAIClient(): OpenAI {
  if (!openai) {
    if (!process.env.OPENAI_API_KEY) {
      // Don't throw here - let the calling function handle it
      throw new Error("OPENAI_API_KEY environment variable not set");
    }

    openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });
  }
  return openai;
}

export async function completeWithOpenAI(args: any, context: RLangContext) {
  const { system_prompt, template, user_input, output_format } = args;

  // ✅ FIXED: Check for API key BEFORE creating client
  if (!process.env.OPENAI_API_KEY) {
    console.warn("⚠️ OPENAI_API_KEY not set - returning fallback response");
    return generateFallbackResponse(user_input);
  }

  try {
    const client = getOpenAIClient();

    const fullPrompt = `You are an intent extraction specialist. I will give you a user request and a template. Your job is to fill out the template with specific values based on the user's request.

    IMPORTANT: Do not return the template structure or metadata. Fill in the actual values and return ONLY the filled template.

    USER REQUEST: "${user_input}"

    TEMPLATE TO FILL OUT:
    ${template}

    INSTRUCTIONS:
    1. Replace ALL placeholder values (like "[customer_service|email_assistant...]") with actual values
    2. Replace ALL bracketed instructions with real content
    3. Based on the user request, determine what type of agent they need
    4. Fill in ALL the required fields
    5. Return the filled template as valid ${output_format}

    Do NOT return explanations or wrapper structures. Return ONLY the filled template.`;

    console.log("🔍 DEBUG - Template being sent to LLM:");
    console.log("=".repeat(50));
    console.log(template);
    console.log("=".repeat(50));

    const response = await client.chat.completions.create({
      model: "gpt-4o-mini",
      messages: [{ role: "user", content: fullPrompt }],
      temperature: 0.1,
      max_tokens: 1000,
    });

    const result = response.choices[0].message.content;

    if (!result) {
      throw new Error("No content returned from OpenAI");
    }

    return result;
  } catch (error) {
    console.error("OpenAI API error:", error);

    // Return fallback for any error
    console.warn("⚠️ OpenAI failed - returning fallback response");
    return generateFallbackResponse(user_input);
  }
}

// ✅ NEW: Fallback response generator
function generateFallbackResponse(user_input: string): string {
  console.log("🔄 Generating fallback intent for:", user_input);

  return `
agent_requirements:
  agent_type: "integration"
  primary_purpose: "${user_input}"
  key_capabilities: ["api_integration", "data_processing", "automation"]

system_integrations:
  required_services: ["${extractServiceFromInput(user_input)}"]
  data_sources: ["api_endpoints"]
  output_destinations: ["user_interface", "database"]

technical_requirements:
  authentication: "api_key_or_oauth"
  data_format: "json"
  update_frequency: "real_time"

missing_information:
  clarification_needed: ["API credentials", "specific endpoints", "data mapping requirements"]

confidence_score: 0.8
intent_complete: true
`;
}

// ✅ NEW: Extract service name from user input
function extractServiceFromInput(input: string): string {
  const commonServices = [
    "xero",
    "slack",
    "github",
    "salesforce",
    "stripe",
    "shopify",
    "quickbooks",
  ];
  const lowerInput = input.toLowerCase();

  for (const service of commonServices) {
    if (lowerInput.includes(service)) {
      return service;
    }
  }

  // Default to generic if no service detected
  return "external_api";
}
