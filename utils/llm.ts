// utils/llm.ts - Simple LLM router
import { RLangContext } from "../schema/types";
import { completeWithOpenAI } from "./openai-api";

export async function complete(args: any, context: RLangContext) {
  // For now, route everything to OpenAI
  // Later you can add: if (args.task_type === "complex_analysis") use Claude
  return completeWithOpenAI(args, context);
}
