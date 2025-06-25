// utils/openai-api.ts - OpenAI client for fast intent detection
import { RLangContext } from "../schema/types";
import OpenAI from "openai";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export async function completeWithOpenAI(args: any, context: RLangContext) {
  const { system_prompt, template, user_input, output_format } = args;

  if (!process.env.OPENAI_API_KEY) {
    throw new Error("OPENAI_API_KEY environment variable not set");
  }

  const fullPrompt = `
${system_prompt}

TEMPLATE TO FILL:
${template}

USER REQUEST: "${user_input}"

Please fill in the template above based on the user's request. Output as ${output_format}.
`;

  try {
    const response = await openai.chat.completions.create({
      model: "gpt-4o-mini", // Fast and cost-effective for intent detection
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

    // Graceful fallback for development
    if (error instanceof Error && error.message.includes("API key")) {
      console.warn("⚠️ OpenAI API key issue - returning fallback response");
      return `
agent_requirements:
  agent_type: "custom"
  primary_purpose: "${user_input}"
  key_capabilities: ["basic_functionality"]

system_integrations:
  required_services: ["manual_detection_needed"]
  data_sources: ["to_be_determined"]
  output_destinations: ["standard_output"]

missing_information:
  clarification_needed: ["LLM service unavailable - manual review needed"]
`;
    }

    throw new Error(
      `OpenAI completion failed: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}
