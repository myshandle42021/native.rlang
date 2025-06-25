// utils/openai-api.ts - Lazy initialization
import { RLangContext } from "../schema/types";
import OpenAI from "openai";

let openai: OpenAI | null = null;

function getOpenAIClient(): OpenAI {
  if (!openai) {
    if (!process.env.OPENAI_API_KEY) {
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

  // Get client when needed (after dotenv has loaded)
  const client = getOpenAIClient();

  const fullPrompt = `
${system_prompt}

TEMPLATE TO FILL:
${template}

USER REQUEST: "${user_input}"

Please fill in the template above based on the user's request. Output as ${output_format}.
`;

  try {
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
