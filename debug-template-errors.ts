import { callClaude } from './utils/claude-debug-api';

async function analyzeTemplateErrors() {
  const errorData = {
    primary_error: "Cannot access ${item.path} for ${operation.operation}: ${operation.error}",
    frequency: 468,
    context: "nested loops in bootstrap-policies.r validate_file_permissions operation",
    secondary_error: "Critical module missing: ${item.name} - ${item.error}",
    secondary_frequency: 44,
    root_cause: "R-lang template variable resolution failing in nested loop contexts"
  };

  const prompt = `You are debugging R-lang template variable resolution errors in the ROL3 system.

SPECIFIC ERROR PATTERN:
- Error: "Cannot access \${item.path} for \${operation.operation}: \${operation.error}"
- Frequency: 468 occurrences
- Location: bootstrap-policies.r in nested loops

ROOT CAUSE:
In nested R-lang loops, template variables like \${item.path} and \${operation.operation} are not resolving properly. This suggests a variable scoping issue in the R-lang interpreter.

CODE CONTEXT:
\`\`\`r
- loop:
    forEach: "\${input.permission_results}"
    do:
      - loop:
          forEach: "\${item.operations}"  
          do:
            - condition:
                if: "!\${operation.accessible}"
                then:
                  - add_validation_error: { error: "Cannot access \${item.path} for \${operation.operation}: \${operation.error}" }
\`\`\`

SOLUTION NEEDED:
Fix the nested loop variable scoping so that:
1. Outer loop \${item} refers to permission_results item
2. Inner loop \${operation} refers to operations item  
3. Template variables resolve properly in nested contexts

Generate a specific fix for this R-lang template variable scoping issue.

Respond with JSON:
{
  "fix_title": "R-lang Template Variable Scoping Fix",
  "description": "Fix nested loop variable resolution in bootstrap-policies.r",
  "file_path": "r/system/bootstrap-policies.r", 
  "fix_content": "exact R-lang code to replace the problematic validate_file_permissions operation",
  "confidence": 0.95,
  "explanation": "Why this fixes the template variable resolution"
}`;

  try {
    const response = await callClaude(prompt);
    console.log('🤖 Claude Analysis Result:');
    console.log(response);
  } catch (error) {
    console.error('❌ Claude analysis failed:', error.message);
  }
}

analyzeTemplateErrors().catch(console.error);
