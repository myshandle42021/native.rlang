// utils/infer.ts
// Real LLM integration for self-healing

import { RLangContext } from "../schema/types";

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;

export async function generateFix(args: any, context: RLangContext) {
  const prompt = `
You are a TypeScript/Node.js expert helping fix a production issue in ROL3.

ISSUE: ${args.issue}
ERROR LOGS: ${JSON.stringify(args.system_logs || args.context, null, 2)}
SYSTEM: ROL3 agent ecosystem with .r files calling TypeScript utils

Generate a specific fix for this issue. Respond with JSON:
{
  "fix_type": "code_change|config_update|import_fix|template_regeneration",
  "changes": "specific code/config to change",
  "confidence": 0.8,
  "test_steps": ["step 1", "step 2"]
}
`;

  try {
    const response = await callLLM(prompt);
    return JSON.parse(response);
  } catch (error) {
    return {
      fix: "LLM unavailable - manual fix needed",
      confidence: 0.0,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

export async function getIntent(text: string, context: RLangContext) {
  const prompt = `
Analyze this user request and extract intent:
"${text}"

Respond with JSON:
{
  "action": "create_agent|send_message|get_data|configure_service",
  "services": ["slack", "xero", "github"],
  "parameters": {"key": "value"}
}
`;

  try {
    const response = await callLLM(prompt);
    return JSON.parse(response);
  } catch (error) {
    return { action: "unknown", confidence: 0.1, text };
  }
}

export async function enhanceAgent(args: any, context: RLangContext) {
  const prompt = `
Improve this agent template based on the user intent:

TEMPLATE: ${JSON.stringify(args.template, null, 2)}
USER INTENT: ${args.intent}
CONTEXT: ${JSON.stringify(args.context, null, 2)}

Generate improved .r file operations. Respond with JSON:
{
  "operations": {
    "operation_name": [
      {"step": "value"},
      {"condition": {"if": "...", "then": [...]}}
    ]
  },
  "improvements": ["improvement 1", "improvement 2"]
}
`;

  try {
    const response = await callLLM(prompt);
    return JSON.parse(response);
  } catch (error) {
    return { enhanced: false, reason: "LLM enhancement failed" };
  }
}

export async function generateServiceUtil(serviceName: string, intent: string) {
  const prompt = `
Generate a TypeScript utility file for ${serviceName} integration.

USER INTENT: ${intent}
SERVICE: ${serviceName}

Create a utils/${serviceName}.ts file with these functions:
- authenticate(args, context)
- sendMessage(args, context) or equivalent main function
- Any other service-specific functions

Use the ROL3 pattern:
- Import { RLangContext } from '../schema/types'
- All functions take (args, context) parameters
- Return JSON responses
- Handle errors gracefully

Generate only the TypeScript code:
`;

  try {
    const response = await callLLM(prompt);
    return { code: response, generated: true };
  } catch (error) {
    return {
      code: null,
      error: error instanceof Error ? error.message : String(error),
    };
  }
}

export async function reflect(args: any, context: RLangContext) {
  const prompt = `
Analyze system performance and suggest improvements:

AGENT: ${args.agent_id || context.agentId}
ASPECT: ${args.aspect}
DATA: ${JSON.stringify(args.data || context.memory, null, 2)}

Provide reflection and suggestions. Respond with JSON:
{
  "reflection": "analysis of current state",
  "suggestions": ["suggestion 1", "suggestion 2"],
  "priority": "high|medium|low"
}
`;

  try {
    const response = await callLLM(prompt);
    return JSON.parse(response);
  } catch (error) {
    return { reflection: "Analysis unavailable", suggestions: [] };
  }
}

export async function summarize(args: any, context: RLangContext) {
  const data = args.data || args;
  const format = args.format || "summary";

  const prompt = `
Summarize this data in ${format} format:
${JSON.stringify(data, null, 2)}

Provide a clear, concise summary.
`;

  try {
    const response = await callLLM(prompt);
    return { summary: response };
  } catch (error) {
    return { summary: "Summary unavailable" };
  }
}

export async function compare(args: any, context: RLangContext) {
  return { comparison: "Comparison placeholder" };
}

export async function generateEmail(args: any, context: RLangContext) {
  const template = args.template || "professional";
  const data = args.data || {};

  const prompt = `
Generate a ${template} email using this data:
${JSON.stringify(data, null, 2)}

Create appropriate subject and body text.
Respond with JSON:
{
  "subject": "email subject",
  "content": "email body"
}
`;

  try {
    const response = await callLLM(prompt);
    return JSON.parse(response);
  } catch (error) {
    return { content: "Email template unavailable" };
  }
}

async function callLLM(prompt: string): Promise<string> {
  // Try OpenAI first
  if (OPENAI_API_KEY) {
    try {
      const response = await fetch(
        "https://api.openai.com/v1/chat/completions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${OPENAI_API_KEY}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: process.env.OPENAI_MODEL || "gpt-4",
            messages: [{ role: "user", content: prompt }],
            max_tokens: 2000,
            temperature: 0.1,
          }),
        },
      );

      const data: any = await response.json();
      return data.choices[0].message.content;
    } catch (error) {
      console.warn("OpenAI failed, trying Anthropic...", error);
    }
  }

  // Fall back to Anthropic
  if (ANTHROPIC_API_KEY) {
    try {
      const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "x-api-key": ANTHROPIC_API_KEY,
          "Content-Type": "application/json",
          "anthropic-version": "2023-06-01",
        },
        body: JSON.stringify({
          model: process.env.ANTHROPIC_MODEL || "claude-3-sonnet-20240229",
          max_tokens: 2000,
          messages: [{ role: "user", content: prompt }],
        }),
      });

      const data: any = await response.json();
      return data.content[0].text;
    } catch (error) {
      console.warn("Anthropic also failed:", error);
    }
  }

  throw new Error("No LLM provider available");
}
