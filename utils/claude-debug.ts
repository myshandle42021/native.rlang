// utils/claude-debug.ts
// Claude integration layer for AI-powered system analysis and fix generation

// Try to import Claude API, fallback if not available
let callClaude: (prompt: string) => Promise<string>;
try {
  const claudeApi = require("./claude-api");
  callClaude = claudeApi.callClaude;
} catch (error) {
  console.warn("Claude API not available - using fallback responses");
  callClaude = async (prompt: string) => {
    throw new Error("Claude API not configured");
  };
}
import { ErrorPattern, SystemMetrics, FailurePattern } from "./debug-queries";

export interface Analysis {
  summary: string;
  root_causes: Array<{
    cause: string;
    confidence: number;
    evidence: string[];
  }>;
  impact_assessment: {
    severity: "critical" | "high" | "medium" | "low";
    affected_components: string[];
    user_impact: string;
  };
  recommended_actions: Array<{
    action: string;
    priority: number;
    effort: "low" | "medium" | "high";
    risk: "low" | "medium" | "high";
  }>;
  patterns_identified: string[];
}

export interface Fix {
  id: string;
  title: string;
  description: string;
  file_path: string;
  fix_type: "code_change" | "config_change" | "new_file" | "documentation";
  content: string;
  validation_steps: string[];
  rollback_instructions: string;
  confidence: number;
  priority: number;
}

export interface Priority {
  issue: string;
  priority_score: number;
  reasoning: string;
  urgency: "immediate" | "urgent" | "normal" | "low";
  estimated_fix_time: string;
}

/**
 * Analyze errors using Claude AI
 */
export async function analyzeErrors(errors: ErrorPattern[]): Promise<Analysis> {
  const prompt = `You are an expert system administrator analyzing errors in the ROL3 autonomous agent system.

## System Context
ROL3 is a TypeScript-based system with:
- R-lang agents that process messages and execute operations
- PostgreSQL database with RCD (Relational Contextual Database) tables
- RocketChat webhook integration for user interactions
- Learning system that tracks agent performance and patterns

## Current Error Data
${JSON.stringify(errors, null, 2)}

## Analysis Request
Please analyze these errors and provide:

1. **Root Cause Analysis**: What are the most likely underlying causes?
2. **Impact Assessment**: How severe are these issues and what's affected?
3. **Pattern Recognition**: What patterns do you see in the error data?
4. **Recommended Actions**: What should be done to fix these issues?

Focus on:
- Intent validation problems (common in our system)
- Database connectivity issues
- Agent performance degradation
- Webhook processing failures
- RocketChat integration problems

Provide your analysis in this exact JSON format:
{
  "summary": "Brief overview of the situation",
  "root_causes": [
    {
      "cause": "Specific root cause",
      "confidence": 0.8,
      "evidence": ["evidence1", "evidence2"]
    }
  ],
  "impact_assessment": {
    "severity": "critical|high|medium|low",
    "affected_components": ["component1", "component2"],
    "user_impact": "Description of user impact"
  },
  "recommended_actions": [
    {
      "action": "Specific action to take",
      "priority": 1,
      "effort": "low|medium|high",
      "risk": "low|medium|high"
    }
  ],
  "patterns_identified": ["pattern1", "pattern2"]
}`;

  try {
    const response = await callClaude(prompt);

    // Try to parse JSON response
    try {
      return JSON.parse(response);
    } catch (parseError) {
      // If JSON parsing fails, create a structured response from the text
      return createFallbackAnalysis(response, errors);
    }
  } catch (error) {
    console.error("Claude analysis failed:", error);
    return createEmergencyAnalysis(errors);
  }
}

/**
 * Generate fixes for identified issues using Claude
 */
export async function generateFixes(analysis: Analysis): Promise<Fix[]> {
  const prompt = `You are an expert TypeScript developer working on the ROL3 system. Based on this analysis:

${JSON.stringify(analysis, null, 2)}

## System Architecture Context
- **TypeScript/Node.js** backend with Express webhook server
- **PostgreSQL** database with RCD tables (rcd_learning_events, rcd_performance_logs, etc.)
- **R-lang agents** in r/ directory that handle operations
- **Utils functions** in utils/ (claude-api.ts, db.ts, rcd.ts, tamr.ts, etc.)
- **Webhook handler** at server/webhook-handler.ts for RocketChat integration

## Current File Structure
Key files you can modify/create:
- utils/debug-queries.ts (database queries)
- utils/auto-debug.ts (main orchestrator)
- utils/fix-generator.ts (this file)
- utils/claude-debug.ts (Claude integration)
- server/webhook-handler.ts (webhook processing)
- r/agents/rocketchat-intake.r (main RocketChat agent)
- r/system/intent-detector.r (intent validation)

## Fix Generation Request
Generate practical code fixes for the identified issues. For each fix:

1. **Be specific**: Target exact files and functions
2. **Be safe**: Ensure changes won't break existing functionality
3. **Be testable**: Include validation steps
4. **Be rollback-ready**: Provide clear rollback instructions

Common fix patterns needed:
- Intent validation improvements
- Error handling enhancements
- Database query optimization
- Webhook payload validation
- Agent memory management

Provide exactly this JSON format:
{
  "fixes": [
    {
      "id": "fix_1",
      "title": "Fix Title",
      "description": "What this fix does",
      "file_path": "exact/file/path.ts",
      "fix_type": "code_change|config_change|new_file|documentation",
      "content": "Complete file content or specific code changes",
      "validation_steps": ["step1", "step2"],
      "rollback_instructions": "How to undo this change",
      "confidence": 0.9,
      "priority": 1
    }
  ]
}`;

  try {
    const response = await callClaude(prompt);

    try {
      const parsed = JSON.parse(response);
      return parsed.fixes || [];
    } catch (parseError) {
      // Extract fixes from text response
      return extractFixesFromText(response);
    }
  } catch (error) {
    console.error("Fix generation failed:", error);
    return generateFallbackFixes(analysis);
  }
}

/**
 * Prioritize issues using Claude's reasoning
 */
export async function prioritizeIssues(
  issues: ErrorPattern[],
): Promise<Priority[]> {
  const prompt = `As a system administrator, prioritize these issues based on:
- User impact severity
- System stability risk
- Fix complexity
- Business criticality

Issues to prioritize:
${JSON.stringify(issues, null, 2)}

Provide this JSON format:
{
  "priorities": [
    {
      "issue": "Issue description",
      "priority_score": 95,
      "reasoning": "Why this priority",
      "urgency": "immediate|urgent|normal|low",
      "estimated_fix_time": "15 minutes"
    }
  ]
}`;

  try {
    const response = await callClaude(prompt);
    const parsed = JSON.parse(response);
    return parsed.priorities || [];
  } catch (error) {
    console.error("Issue prioritization failed:", error);
    return createDefaultPriorities(issues);
  }
}

/**
 * Get system health assessment from Claude
 */
export async function assessSystemHealth(metrics: SystemMetrics): Promise<{
  health_score: number;
  status: "healthy" | "degraded" | "critical";
  key_concerns: string[];
  recommendations: string[];
}> {
  const prompt = `Assess the health of this autonomous agent system:

System Metrics:
${JSON.stringify(metrics, null, 2)}

Provide health assessment in this JSON format:
{
  "health_score": 85,
  "status": "healthy|degraded|critical",
  "key_concerns": ["concern1", "concern2"],
  "recommendations": ["rec1", "rec2"]
}`;

  try {
    const response = await callClaude(prompt);
    return JSON.parse(response);
  } catch (error) {
    console.error("Health assessment failed:", error);
    return {
      health_score: 50,
      status: "degraded",
      key_concerns: ["Unable to assess system health"],
      recommendations: ["Manual system review required"],
    };
  }
}

/**
 * Fallback analysis when Claude fails or returns invalid JSON
 */
function createFallbackAnalysis(
  claudeResponse: string,
  errors: ErrorPattern[],
): Analysis {
  const errorCount = errors.length;
  const criticalErrors = errors.filter((e) => e.severity === "critical").length;

  return {
    summary: `Detected ${errorCount} error patterns, ${criticalErrors} critical`,
    root_causes: [
      {
        cause: "Multiple system errors detected",
        confidence: 0.7,
        evidence: [`${errorCount} error patterns found`],
      },
    ],
    impact_assessment: {
      severity:
        criticalErrors > 0 ? "critical" : errorCount > 5 ? "high" : "medium",
      affected_components: [
        ...new Set(errors.flatMap((e) => e.affected_agents)),
      ],
      user_impact: "System functionality may be degraded",
    },
    recommended_actions: [
      {
        action: "Review error logs and fix highest frequency issues",
        priority: 1,
        effort: "medium",
        risk: "low",
      },
    ],
    patterns_identified: [...new Set(errors.map((e) => e.error_type))],
  };
}

/**
 * Emergency analysis when Claude is completely unavailable
 */
function createEmergencyAnalysis(errors: ErrorPattern[]): Analysis {
  const highFrequencyErrors = errors.filter((e) => e.frequency > 5);

  return {
    summary: "Claude AI unavailable - using fallback analysis",
    root_causes: [
      {
        cause: "Analysis system offline",
        confidence: 1.0,
        evidence: ["Claude API unavailable"],
      },
    ],
    impact_assessment: {
      severity: highFrequencyErrors.length > 0 ? "high" : "medium",
      affected_components: ["auto-debug system"],
      user_impact: "Reduced diagnostic capabilities",
    },
    recommended_actions: [
      {
        action: "Manually review highest frequency errors",
        priority: 1,
        effort: "high",
        risk: "low",
      },
    ],
    patterns_identified: ["manual_review_required"],
  };
}

/**
 * Extract fixes from text when JSON parsing fails
 */
function extractFixesFromText(text: string): Fix[] {
  // Simple text parsing fallback
  const fixes: Fix[] = [];

  if (text.includes("intent") || text.includes("validation")) {
    fixes.push({
      id: "intent_fix_1",
      title: "Intent Validation Enhancement",
      description: "Improve intent validation logic",
      file_path: "r/system/intent-detector.r",
      fix_type: "code_change",
      content: "# Review intent validation rules and confidence thresholds",
      validation_steps: ["Test intent detection", "Check validation accuracy"],
      rollback_instructions: "Revert to previous intent detection logic",
      confidence: 0.6,
      priority: 1,
    });
  }

  return fixes;
}

/**
 * Generate basic fixes when Claude fails
 */
function generateFallbackFixes(analysis: Analysis): Fix[] {
  const fixes: Fix[] = [];

  // Basic database connection fix
  if (
    analysis.patterns_identified.some(
      (p) => p.includes("database") || p.includes("connection"),
    )
  ) {
    fixes.push({
      id: "db_connection_fix",
      title: "Database Connection Pool Optimization",
      description: "Increase connection pool size and add retry logic",
      file_path: "utils/db.ts",
      fix_type: "config_change",
      content: "// Increase DB_POOL_SIZE in environment variables",
      validation_steps: [
        "Check database connectivity",
        "Monitor connection pool usage",
      ],
      rollback_instructions: "Restore previous pool size settings",
      confidence: 0.8,
      priority: 1,
    });
  }

  return fixes;
}

/**
 * Create default priorities when Claude is unavailable
 */
function createDefaultPriorities(issues: ErrorPattern[]): Priority[] {
  return issues.map((issue, index) => ({
    issue: issue.error_type,
    priority_score: Math.max(90 - index * 10, 10),
    reasoning: `Frequency: ${issue.frequency}, Severity: ${issue.severity}`,
    urgency:
      issue.severity === "critical"
        ? "immediate"
        : issue.frequency > 5
          ? "urgent"
          : "normal",
    estimated_fix_time: "30 minutes",
  }));
}
