// schema/types.ts
// Core type definitions for ROL3

export interface RLangContext {
  agentId: string;
  clientId?: string;
  operation: string;
  input: any;
  memory: Record<string, any>;
  trace: TraceEntry[];
  timestamp: string;
  user?: string;
  channel?: string;
}

export interface TraceEntry {
  step: string;
  input?: any;
  output?: any;
  error?: string;
  timestamp: string;
  success: boolean;
}

export interface ExecutionResult {
  output: any;
  context: RLangContext;
  trace: TraceEntry[];
}

export interface RLangResult {
  success: boolean;
  result?: any;
  error?: string;
  context?: RLangContext;
  trace: TraceEntry[];
}

export type RLangStep =
  | string
  | {
      condition?: {
        if?: string;
        condition?: string;
        then: RLangStep[];
        else?: RLangStep[];
      };
    }
  | {
      loop?: {
        forEach?: string;
        while?: string;
        do: RLangStep[];
      };
    }
  | {
      run?:
        | string
        | {
            file?: string;
            operation?: string;
            input?: any;
          };
    }
  | {
      respond?:
        | string
        | {
            message: string;
            to?: string;
          };
    }
  | {
      "prompt.user"?: {
        to: string;
        message: string;
        buttons?: string[];
      };
    }
  | {
      "self.modify"?: {
        template?: string;
        changes?: any;
      };
    }
  | {
      "self.reflect"?: {
        on?: string;
        aspect?: string;
      };
    }
  | Record<string, any>; // For module functions like xero.getInvoices

export interface RLangFile {
  self?: {
    id: string;
    intent?: string;
    version?: string;
    template?: string;
  };
  aam?: {
    require_role?: string;
    allow_actions?: string[];
    restrict_clients?: string[];
  };
  operations: Record<string, RLangStep[]>;
  concern?: {
    if: string;
    priority: number;
    action: RLangStep[];
  };
  incoming?: {
    webhook?: {
      path: string;
      method: string;
      operation: string;
    };
  };
}

export interface AgentTemplate {
  id: string;
  intent: string;
  operations: Record<string, RLangStep[]>;
  defaultConfig?: Record<string, any>;
  requiredInputs?: string[];
}

export interface ClientContext {
  id: string;
  name: string;
  settings: Record<string, any>;
  auth: Record<string, any>;
  agents: string[];
}

export interface SystemState {
  activeAgents: string[];
  clientContexts: Record<string, ClientContext>;
  systemHealth: {
    status: "healthy" | "degraded" | "critical";
    issues: string[];
    lastCheck: string;
  };
}

export interface WebhookConfig {
  path: string;
  method: "GET" | "POST" | "PUT" | "DELETE";
  agentFile: string;
  operation: string;
  auth?: {
    type: "bearer" | "api_key" | "none";
    header?: string;
  };
}

export interface InferRequest {
  type: "intent" | "enhance" | "reflect" | "summarize";
  input: any;
  context?: RLangContext;
}

export interface InferResponse {
  success: boolean;
  result?: any;
  confidence?: number;
  error?: string;
}
