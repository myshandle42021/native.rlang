// server/webhook-handler.ts
// Express.js webhook endpoint for RocketChat integration

import express, { Request, Response, RequestHandler } from "express";
import { runRLang } from "../runtime/interpreter";
import { createRocketChatContext } from "../runtime/context";

const app = express();
app.use(express.json());

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

// FIXED: Let TypeScript infer the handler type for Express 5.x
const handleRocketChatWebhook = async (req: Request, res: Response) => {
  try {
    console.log("RocketChat webhook received:", req.body);

    // Validate webhook payload
    const payload = validateRocketChatWebhook(req.body);
    if (!payload.valid) {
      return res.status(400).json({ error: "Invalid webhook payload" });
    }

    // Skip bot messages to avoid loops
    if (payload.message.user_type === "bot" || payload.message.bot) {
      return res.status(200).json({ status: "ignored_bot_message" });
    }

    // Create RocketChat context
    const context = createRocketChatContext(
      "rocketchat-intake",
      "message_handler",
      {
        userId: payload.message.user_id,
        username: payload.message.username,
        channel: payload.message.channel_id,
        messageId: payload.message.message_id,
        text: payload.message.text,
        button: payload.message.button,
        context: payload.message.context,
      },
    );

    // Process message through RocketChat intake agent
    const result = await runRLang({
      file: "r/agents/rocketchat-intake.r",
      operation: "message_handler",
      input: {
        message: payload.message,
        webhook_data: req.body,
        headers: req.headers,
      },
      context: context,
    });

    if (result.success) {
      res.status(200).json({
        status: "processed",
        message_id: payload.message.message_id,
        response: result.result,
      });
    } else {
      console.error("Message processing failed:", result.error);
      res.status(500).json({
        status: "error",
        error: result.error,
      });
    }
  } catch (error) {
    console.error("Webhook error:", error);
    res.status(500).json({
      status: "error",
      error: getErrorMessage(error),
    });
  }
};

// FIXED: Let TypeScript infer the handler type for buttons
const handleRocketChatButtons = async (req: Request, res: Response) => {
  try {
    const payload = req.body;

    // Extract button action data from payload
    const rawButtonData = {
      user_id: payload.user?._id || payload.user_id,
      username: payload.user?.username || payload.username,
      channel: payload.channel?._id || payload.channel_id,
      message_id: payload.message?._id || payload.message_id,
      button_action: payload.action || payload.button_action,
      button_value: payload.action_value || payload.button_value,
      original_message: payload.message?.msg || payload.original_message,
    };

    // Map to expected interface
    const buttonData = {
      userId: rawButtonData.user_id,
      username: rawButtonData.username,
      channel: rawButtonData.channel,
      messageId: rawButtonData.message_id,
      button: rawButtonData.button_action,
      context: rawButtonData,
    };

    // Create context for button response
    const context = createRocketChatContext(
      "rocketchat-intake",
      "button_response_handler",
      buttonData,
    );

    // Process button response
    const result = await runRLang({
      file: "r/agents/rocketchat-intake.r",
      operation: "button_response_handler",
      input: buttonData,
      context: context,
    });

    res.status(200).json({
      status: "button_processed",
      response: result.result,
    });
  } catch (error) {
    console.error("Button response error:", error);
    res.status(500).json({ error: getErrorMessage(error) });
  }
};

// FIXED: Let TypeScript infer the handler type for health check
const handleHealthCheck = (req: Request, res: Response) => {
  res.status(200).json({
    status: "healthy",
    service: "rocketchat-webhook",
    timestamp: new Date().toISOString(),
  });
};

// ✅ FIXED: Cast each handler to RequestHandler to resolve TS2769
app.post("/webhooks/rocketchat", handleRocketChatWebhook as RequestHandler);
app.post(
  "/webhooks/rocketchat/buttons",
  handleRocketChatButtons as RequestHandler,
);
app.get("/webhooks/rocketchat/health", handleHealthCheck as RequestHandler);

// Validate RocketChat webhook payload
function validateRocketChatWebhook(payload: any): {
  valid: boolean;
  message?: any;
  error?: string;
} {
  try {
    // Basic payload structure validation
    if (!payload || typeof payload !== "object") {
      return { valid: false, error: "Invalid payload structure" };
    }

    // RocketChat webhook formats can vary, handle common patterns
    let message;

    if (
      payload.messages &&
      Array.isArray(payload.messages) &&
      payload.messages.length > 0
    ) {
      // Batch message format
      message = extractMessageData(payload.messages[0]);
    } else if (payload.message) {
      // Single message format
      message = extractMessageData(payload.message);
    } else if (payload.msg) {
      // Direct message format
      message = extractMessageData(payload);
    } else {
      return { valid: false, error: "No message data found in payload" };
    }

    // Validate required message fields
    if (!message.text || !message.user_id || !message.channel_id) {
      return { valid: false, error: "Missing required message fields" };
    }

    return { valid: true, message };
  } catch (error) {
    return {
      valid: false,
      error: `Validation error: ${getErrorMessage(error)}`,
    };
  }
}

// Extract and normalize message data from various RocketChat formats
function extractMessageData(rawMessage: any): any {
  return {
    message_id: rawMessage._id || rawMessage.messageId || rawMessage.id,
    text: rawMessage.msg || rawMessage.text || rawMessage.message,
    user_id: rawMessage.u?._id || rawMessage.userId || rawMessage.user_id,
    username: rawMessage.u?.username || rawMessage.username,
    user_name: rawMessage.u?.name || rawMessage.user_name,
    channel_id: rawMessage.rid || rawMessage.channelId || rawMessage.channel_id,
    channel_name: rawMessage.channel?.name || rawMessage.channel_name,
    timestamp:
      rawMessage.ts || rawMessage.timestamp || new Date().toISOString(),
    type: rawMessage.t || rawMessage.type || "message",
    thread_id: rawMessage.tmid || rawMessage.thread_id,
    edited: rawMessage.editedAt || rawMessage.edited,
    mentions: rawMessage.mentions || [],
    channels: rawMessage.channels || [],
    attachments: rawMessage.attachments || [],
    reactions: rawMessage.reactions || {},
    starred: rawMessage.starred || false,
    pinned: rawMessage.pinned || false,
    bot: rawMessage.bot || false,
    user_type: rawMessage.u?.type || "user",
  };
}

// Start webhook server
const PORT = process.env.WEBHOOK_PORT || 3001;
app.listen(PORT, () => {
  console.log(`🔗 RocketChat webhook server listening on port ${PORT}`);
  console.log(`📝 Webhook URL: http://localhost:${PORT}/webhooks/rocketchat`);
});

export default app;
