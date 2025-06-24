// runtime/generateAgent.ts
// Creates new .r agent files from templates and specifications

import { writeFile, mkdir } from "fs/promises";
import { dirname } from "path";
import { loadRFile } from "./loader";
import { RLangContext, AgentTemplate } from "../schema/types";
import { getFunction } from "../utils/runtime";

export interface GenerateAgentOptions {
  template?: string;
  agentId?: string;
  config?: Record<string, any>;
  outputPath?: string;
  clientId?: string;
  intent?: string;
  operations?: Record<string, any>;
  enhance?: boolean; // Use LLM to enhance the agent
}

export async function generateAgent(
  options: GenerateAgentOptions,
  context: RLangContext,
): Promise<{ agentId: string; filePath: string; content: any }> {
  const {
    template = "basic_agent",
    agentId = generateAgentId(options.intent || "custom"),
    config = {},
    clientId = context.clientId,
    intent,
    operations,
    enhance = true,
  } = options;

  // Determine output path
  const outputPath =
    options.outputPath || determineOutputPath(agentId, clientId);

  // Load template if specified
  let templateData: any = {};
  if (template && template !== "custom") {
    try {
      templateData = await loadRFile(`r/templates/${template}.r`);
    } catch (error) {
      console.warn(`Template ${template} not found, using basic template`);
      templateData = getBasicTemplate();
    }
  }

  // Create agent specification
  let agentSpec = createAgentFromTemplate(templateData, {
    agentId,
    intent: intent || config.intent || `Agent for ${agentId}`,
    config,
    operations: operations || config.operations,
  });

  // Enhance with LLM if requested
  if (enhance && (intent || config.enhance_prompt)) {
    try {
      const { enhanceAgent } = await import("../utils/infer");
      const enhanced = await enhanceAgent(
        {
          template: agentSpec,
          intent: intent || config.enhance_prompt,
          context: config,
        },
        context,
      );

      if (enhanced && enhanced.operations) {
        agentSpec = { ...agentSpec, ...enhanced };
      }
    } catch (error) {
      console.warn("Agent enhancement failed, using base template:", error);
    }
  }

  // Write agent file
  await ensureDirectoryExists(dirname(outputPath));
  const fileContent = serializeAgent(agentSpec);
  await writeFile(outputPath, fileContent, "utf-8");

  return {
    agentId,
    filePath: outputPath,
    content: agentSpec,
  };
}

function generateAgentId(intent: string): string {
  const cleaned = intent
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, "")
    .replace(/\s+/g, "-")
    .substring(0, 30);

  const timestamp = Date.now().toString(36).substring(-4);
  return `${cleaned}-${timestamp}`;
}

function determineOutputPath(agentId: string, clientId?: string): string {
  if (clientId) {
    return `r/clients/${clientId}/agents/${agentId}.r`;
  }
  return `r/agents/${agentId}.r`;
}

function createAgentFromTemplate(
  template: any,
  options: {
    agentId: string;
    intent: string;
    config: Record<string, any>;
    operations?: Record<string, any>;
  },
): any {
  const { agentId, intent, config, operations } = options;

  // Start with template or basic structure
  const agent = {
    self: {
      id: agentId,
      intent: intent,
      template: template.self?.template || "custom",
      version: "1.0.0",
      ...config.self,
    },

    aam: {
      require_role: config.require_role || template.aam?.require_role || "user",
      allow_actions: config.allow_actions ||
        template.aam?.allow_actions || ["default"],
      ...config.aam,
    },

    operations: {
      // Default operations
      initialize: [
        { "tamr.log": { event: "agent_initialized", agent: agentId } },
        { respond: `✅ ${agentId} initialized and ready` },
      ],

      request_handler: [
        {
          condition: {
            if: "${request.type == 'natural_language'}",
            then: [
              { "infer.intent": "${request.text}" },
              { respond: "I understand your request: ${intent}" },
            ],
          },
        },
      ],

      // Merge in template operations
      ...template.operations,

      // Override with custom operations
      ...operations,

      // Merge in config operations
      ...config.operations,
    },

    // Add concern detection if specified
    ...(config.concern && {
      concern: {
        if: config.concern.condition || "${error_count > 3}",
        priority: config.concern.priority || 3,
        action: config.concern.action || [
          { "tamr.log": { event: "concern_triggered", agent: agentId } },
          {
            "prompt.user": {
              to: "admin",
              message: `⚠️ Agent ${agentId} has triggered a concern: ${config.concern.description || "unknown issue"}`,
              buttons: ["Investigate", "Disable", "Reset"],
            },
          },
        ],
      },
    }),

    // Add webhook configuration if specified
    ...(config.webhook && {
      incoming: {
        webhook: {
          path: config.webhook.path || `/webhooks/${agentId}`,
          method: config.webhook.method || "POST",
          operation: config.webhook.operation || "webhook_handler",
        },
      },
    }),
  };

  return agent;
}

function getBasicTemplate(): any {
  return {
    self: {
      template: "basic_agent",
    },
    operations: {
      default: [{ respond: "Hello! I am a basic agent." }],
    },
  };
}

function serializeAgent(agent: any): string {
  // Convert to YAML format
  const yamlLines: string[] = [];

  // Add header comment
  yamlLines.push(`# ${agent.self.id}`);
  yamlLines.push(`# ${agent.self.intent}`);
  yamlLines.push("# Generated by ROL3 Agent Generator");
  yamlLines.push("");

  // Serialize sections
  yamlLines.push("self:");
  yamlLines.push(`  id: "${agent.self.id}"`);
  yamlLines.push(`  intent: "${agent.self.intent}"`);
  if (agent.self.template)
    yamlLines.push(`  template: "${agent.self.template}"`);
  if (agent.self.version) yamlLines.push(`  version: "${agent.self.version}"`);
  yamlLines.push("");

  if (agent.aam) {
    yamlLines.push("aam:");
    if (agent.aam.require_role)
      yamlLines.push(`  require_role: "${agent.aam.require_role}"`);
    if (agent.aam.allow_actions) {
      yamlLines.push("  allow_actions:");
      agent.aam.allow_actions.forEach((action: string) => {
        yamlLines.push(`    - "${action}"`);
      });
    }
    yamlLines.push("");
  }

  yamlLines.push("operations:");
  for (const [opName, steps] of Object.entries(agent.operations)) {
    yamlLines.push(`  ${opName}:`);
    serializeSteps(steps as any[], yamlLines, 4);
    yamlLines.push("");
  }

  if (agent.concern) {
    yamlLines.push("concern:");
    yamlLines.push(`  if: "${agent.concern.if}"`);
    yamlLines.push(`  priority: ${agent.concern.priority}`);
    yamlLines.push("  action:");
    serializeSteps(agent.concern.action, yamlLines, 4);
    yamlLines.push("");
  }

  if (agent.incoming) {
    yamlLines.push("incoming:");
    if (agent.incoming.webhook) {
      yamlLines.push("  webhook:");
      yamlLines.push(`    path: "${agent.incoming.webhook.path}"`);
      yamlLines.push(`    method: "${agent.incoming.webhook.method}"`);
      yamlLines.push(`    operation: "${agent.incoming.webhook.operation}"`);
    }
  }

  return yamlLines.join("\n");
}

function serializeSteps(steps: any[], lines: string[], indent: number): void {
  const indentStr = " ".repeat(indent);

  steps.forEach((step) => {
    if (typeof step === "string") {
      lines.push(`${indentStr}- ${step}`);
    } else if (typeof step === "object") {
      const key = Object.keys(step)[0];
      const value = step[key];

      if (typeof value === "string") {
        lines.push(`${indentStr}- ${key}: "${value}"`);
      } else if (typeof value === "object") {
        lines.push(`${indentStr}- ${key}:`);
        serializeValue(value, lines, indent + 4);
      }
    }
  });
}

function serializeValue(value: any, lines: string[], indent: number): void {
  const indentStr = " ".repeat(indent);

  if (Array.isArray(value)) {
    value.forEach((item) => {
      if (typeof item === "string") {
        lines.push(`${indentStr}- "${item}"`);
      } else {
        lines.push(`${indentStr}- `);
        serializeValue(item, lines, indent + 2);
      }
    });
  } else if (typeof value === "object" && value !== null) {
    Object.entries(value).forEach(([key, val]) => {
      if (typeof val === "string") {
        lines.push(`${indentStr}${key}: "${val}"`);
      } else if (typeof val === "number" || typeof val === "boolean") {
        lines.push(`${indentStr}${key}: ${val}`);
      } else if (Array.isArray(val)) {
        lines.push(`${indentStr}${key}:`);
        serializeValue(val, lines, indent + 2);
      } else if (typeof val === "object") {
        lines.push(`${indentStr}${key}:`);
        serializeValue(val, lines, indent + 2);
      }
    });
  }
}

async function ensureDirectoryExists(dirPath: string): Promise<void> {
  try {
    await mkdir(dirPath, { recursive: true });
  } catch (error) {
    // Directory might already exist, that's fine
    if (error instanceof Error && !error.message.includes("EEXIST")) {
      throw error;
    }
  }
}

// Self-modification: update existing agent
export async function modifyAgent(
  agentId: string,
  changes: any,
  context: RLangContext,
): Promise<{ success: boolean; changes: string[] }> {
  const agentPath = context.clientId
    ? `r/clients/${context.clientId}/agents/${agentId}.r`
    : `r/agents/${agentId}.r`;

  try {
    // Load current agent
    const currentAgent = await loadRFile(agentPath);

    // Apply changes
    const modifiedAgent = applyChanges(currentAgent, changes);

    // Backup original
    const backupPath = `${agentPath}.backup.${Date.now()}`;
    const originalContent = serializeAgent(currentAgent);
    await writeFile(backupPath, originalContent, "utf-8");

    // Write modified agent
    const newContent = serializeAgent(modifiedAgent);
    await writeFile(agentPath, newContent, "utf-8");

    // Log the modification
    const changesList = Object.keys(changes);

    return {
      success: true,
      changes: changesList,
    };
  } catch (error) {
    console.error(`Failed to modify agent ${agentId}:`, error);
    return {
      success: false,
      changes: [],
    };
  }
}

function applyChanges(agent: any, changes: any): any {
  // Deep merge changes into agent
  const modified = JSON.parse(JSON.stringify(agent));

  if (changes.operations) {
    modified.operations = { ...modified.operations, ...changes.operations };
  }

  if (changes.self) {
    modified.self = { ...modified.self, ...changes.self };
  }

  if (changes.concern) {
    modified.concern = changes.concern;
  }

  if (changes.aam) {
    modified.aam = { ...modified.aam, ...changes.aam };
  }

  return modified;
}
