// runtime/condition-evaluator.ts
// Evaluates conditional expressions in RLang steps

import { RLangContext } from "../schema/types";

export function evaluateCondition(
  condition: string,
  context: RLangContext,
): boolean {
  if (!condition || typeof condition !== "string") {
    return false;
  }

  try {
    // Replace template variables with actual values
    const resolved = resolveTemplateVars(condition, context);

    // Parse and evaluate the expression
    return evaluateExpression(resolved, context);
  } catch (error) {
    console.warn(`Condition evaluation failed: ${condition}`, error);
    return false;
  }
}

function resolveTemplateVars(
  expression: string,
  context: RLangContext,
): string {
  return expression.replace(/\$\{([^}]+)\}/g, (match, path) => {
    const value = getValueByPath(path.trim(), context);

    if (value === undefined || value === null) {
      return "null";
    }

    if (typeof value === "string") {
      return `"${value.replace(/"/g, '\\"')}"`;
    }

    if (typeof value === "number" || typeof value === "boolean") {
      return String(value);
    }

    if (Array.isArray(value)) {
      return JSON.stringify(value);
    }

    if (typeof value === "object") {
      return JSON.stringify(value);
    }

    return String(value);
  });
}

function getValueByPath(path: string, context: RLangContext): any {
  const parts = path.split(".");
  let current: any = context;

  for (const part of parts) {
    if (current === null || current === undefined) {
      return undefined;
    }

    // Handle array access like items[0] or items.length
    if (part.includes("[") && part.includes("]")) {
      const [arrayName, indexStr] = part.split("[");
      const index = indexStr.replace("]", "");
      current = current[arrayName];

      if (Array.isArray(current)) {
        if (index === "length") {
          current = current.length;
        } else {
          const idx = parseInt(index, 10);
          current = isNaN(idx) ? undefined : current[idx];
        }
      } else {
        return undefined;
      }
    } else {
      current = current[part];
    }
  }

  return current;
}

function evaluateExpression(
  expression: string,
  context: RLangContext,
): boolean {
  // Handle simple boolean values
  if (expression === "true") return true;
  if (expression === "false") return false;
  if (expression === "null" || expression === "undefined") return false;

  // Handle numeric comparisons
  if (
    expression.includes(">") ||
    expression.includes("<") ||
    expression.includes("=")
  ) {
    return evaluateComparison(expression);
  }

  // Handle logical operators
  if (
    expression.includes("&&") ||
    expression.includes("||") ||
    expression.includes("!")
  ) {
    return evaluateLogical(expression);
  }

  // Handle string operations
  if (
    expression.includes(".includes(") ||
    expression.includes(".startsWith(") ||
    expression.includes(".endsWith(")
  ) {
    return evaluateStringOperation(expression);
  }

  // Handle array operations
  if (expression.includes(".length")) {
    return evaluateArrayOperation(expression);
  }

  // Handle object property checks
  if (expression.includes(".") && !expression.includes("(")) {
    return evaluatePropertyCheck(expression);
  }

  // Handle existence checks
  if (expression.startsWith('"') && expression.endsWith('"')) {
    return expression.length > 2; // Non-empty string
  }

  // Try to parse as number
  const num = parseFloat(expression);
  if (!isNaN(num)) {
    return num !== 0;
  }

  // Default: check if expression is truthy
  return (
    expression !== "" && expression !== "null" && expression !== "undefined"
  );
}

function evaluateComparison(expression: string): boolean {
  // Handle different comparison operators
  const operators = ["===", "!==", ">=", "<=", ">", "<", "==", "!="];

  for (const op of operators) {
    if (expression.includes(op)) {
      const [left, right] = expression.split(op).map((s) => s.trim());
      return performComparison(parseValue(left), parseValue(right), op);
    }
  }

  return false;
}

function performComparison(left: any, right: any, operator: string): boolean {
  switch (operator) {
    case "===":
      return left === right;
    case "!==":
      return left !== right;
    case "==":
      return left == right;
    case "!=":
      return left != right;
    case ">":
      return left > right;
    case "<":
      return left < right;
    case ">=":
      return left >= right;
    case "<=":
      return left <= right;
    default:
      return false;
  }
}

function evaluateLogical(expression: string): boolean {
  // Handle NOT operator
  if (expression.startsWith("!")) {
    const inner = expression.slice(1).trim();
    return !evaluateExpression(inner, {} as RLangContext);
  }

  // Handle AND operator
  if (expression.includes("&&")) {
    const parts = expression.split("&&").map((s) => s.trim());
    return parts.every((part) => evaluateExpression(part, {} as RLangContext));
  }

  // Handle OR operator
  if (expression.includes("||")) {
    const parts = expression.split("||").map((s) => s.trim());
    return parts.some((part) => evaluateExpression(part, {} as RLangContext));
  }

  return false;
}

function evaluateStringOperation(expression: string): boolean {
  const includesMatch = expression.match(/(.+)\.includes\((.+)\)/);
  if (includesMatch) {
    const [, str, search] = includesMatch;
    const strValue = parseValue(str);
    const searchValue = parseValue(search);
    return typeof strValue === "string" && strValue.includes(searchValue);
  }

  const startsWithMatch = expression.match(/(.+)\.startsWith\((.+)\)/);
  if (startsWithMatch) {
    const [, str, prefix] = startsWithMatch;
    const strValue = parseValue(str);
    const prefixValue = parseValue(prefix);
    if (typeof strValue !== "string" || typeof prefixValue !== "string")
      return false;
    return strValue.startsWith(prefixValue);
  }

  const endsWithMatch = expression.match(/(.+)\.endsWith\((.+)\)/);
  if (endsWithMatch) {
    const [, str, suffix] = endsWithMatch;
    const strValue = parseValue(str);
    const suffixValue = parseValue(suffix);
    return typeof strValue === "string" && strValue.endsWith(suffixValue);
  }

  return false;
}

function evaluateArrayOperation(expression: string): boolean {
  const lengthMatch = expression.match(/(.+)\.length\s*([><=!]+)\s*(\d+)/);
  if (lengthMatch) {
    const [, arrayExpr, operator, countStr] = lengthMatch;
    const arrayValue = parseValue(arrayExpr);
    const count = parseInt(countStr, 10);

    if (Array.isArray(arrayValue)) {
      return performComparison(arrayValue.length, count, operator);
    }
  }

  return false;
}

function evaluatePropertyCheck(expression: string): boolean {
  // Simple property existence check
  const value = parseValue(expression);
  return value !== null && value !== undefined;
}

function parseValue(value: string): any {
  const trimmed = value.trim();

  // Handle quoted strings
  if (
    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
    (trimmed.startsWith("'") && trimmed.endsWith("'"))
  ) {
    return trimmed.slice(1, -1);
  }

  // Handle booleans
  if (trimmed === "true") return true;
  if (trimmed === "false") return false;
  if (trimmed === "null") return null;
  if (trimmed === "undefined") return undefined;

  // Handle numbers
  const num = parseFloat(trimmed);
  if (!isNaN(num)) return num;

  // Handle arrays/objects (basic JSON parsing)
  if (trimmed.startsWith("[") || trimmed.startsWith("{")) {
    try {
      return JSON.parse(trimmed);
    } catch {
      return trimmed;
    }
  }

  return trimmed;
}

// Special evaluation for switch statements
export function evaluateSwitch(
  value: any,
  cases: Record<string, any>,
): string | null {
  const stringValue = String(value);

  // First try exact match
  if (cases[stringValue]) {
    return stringValue;
  }

  // Then try pattern matching
  for (const [pattern, _] of Object.entries(cases)) {
    if (pattern.includes("*") || pattern.includes("?")) {
      const regex = new RegExp(
        pattern.replace(/\*/g, ".*").replace(/\?/g, "."),
      );
      if (regex.test(stringValue)) {
        return pattern;
      }
    }
  }

  // Check for default case
  if (cases.default) {
    return "default";
  }

  return null;
}
