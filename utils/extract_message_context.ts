// utils/extract_message_context.ts
import { RLangContext } from "../schema/types";

export async function undefined(args: any, context: RLangContext) {
  return extractMessageContext(args, context);
}

export async function extractMessageContext(args: any, context: RLangContext) {
  console.log("🔍 DEBUG - extract_message_context args:", JSON.stringify(args, null, 2));
  
  const message = args.message || args;
  
  const extracted = {
    text: message.text || message.message || "",
    user_id: message.user_id || "",
    channel_id: message.channel_id || "",
    username: message.username || message.user_name || "",
    timestamp: message.timestamp || new Date().toISOString(),
    message_id: message.message_id || "",
    history: [] // Could be enhanced later
  };
  
  console.log("✅ DEBUG - Extracted message context:", JSON.stringify(extracted, null, 2));
  
  return extracted;
}

export const extract_message_context = extractMessageContext;
