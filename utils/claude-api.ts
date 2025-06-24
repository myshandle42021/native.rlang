// Enhanced Claude API integration for API analysis
// utils/claude-api.ts
export async function analyzeAPIDocumentation(
  args: any,
  context: RLangContext,
) {
  const CLAUDE_API_KEY = process.env.ANTHROPIC_API_KEY;

  if (!CLAUDE_API_KEY) {
    throw new Error("ANTHROPIC_API_KEY not configured");
  }

  const {
    service_name,
    documentation_content,
    documentation_sources,
    required_function,
    analysis_context,
    extraction_requirements,
  } = args;

  const prompt = buildAPIAnalysisPrompt(
    service_name,
    documentation_content,
    required_function,
    extraction_requirements,
  );

  try {
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": CLAUDE_API_KEY,
        "Content-Type": "application/json",
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: process.env.ANTHROPIC_MODEL || "claude-3-sonnet-20240229",
        max_tokens: 4000,
        messages: [{ role: "user", content: prompt }],
        temperature: 0.1, // Low temperature for consistent analysis
      }),
    });

    if (!response.ok) {
      throw new Error(
        `Claude API error: ${response.status} ${response.statusText}`,
      );
    }

    const data = await response.json();
    const analysisText = data.content[0].text;

    // Parse Claude's structured response
    const parsedAnalysis = parseClaudeAnalysis(analysisText);

    // Calculate confidence score based on completeness
    const confidenceScore = calculateAnalysisConfidence(parsedAnalysis);

    return {
      success: true,
      analysis: parsedAnalysis,
      confidence_score: confidenceScore,
      token_usage: data.usage || {},
      sources_analyzed: documentation_sources?.length || 0,
      raw_response: analysisText,
    };
  } catch (error) {
    console.error("Claude API analysis failed:", error);
    return {
      success: false,
      error: error.message,
      analysis: null,
      confidence_score: 0,
    };
  }
}

function buildAPIAnalysisPrompt(
  serviceName: string,
  documentation: any,
  requiredFunction: string,
  requirements: any,
) {
  return `You are an expert API integration analyst. Analyze the following ${serviceName} API documentation and extract the information needed to create a universal service integration.

SERVICE: ${serviceName}
REQUIRED FUNCTION: ${requiredFunction}
CONTEXT: This analysis will be used to auto-generate a TypeScript integration module using a universal template pattern.

DOCUMENTATION CONTENT:
${JSON.stringify(documentation, null, 2)}

Please analyze this documentation and provide a structured JSON response with the following information:

${JSON.stringify(requirements, null, 2)}

CRITICAL REQUIREMENTS:
1. Provide specific, actionable information that can be used to configure API calls
2. Include actual endpoint URLs, header names, and authentication parameters
3. Focus on the "${requiredFunction}" function requirements specifically
4. Rate your confidence in each section (0.0 to 1.0)
5. Include source attribution for each piece of information

Respond with valid JSON only, no additional text:

{
  "authentication": { ... },
  "api_structure": { ... },
  "endpoints": { ... },
  "headers": { ... },
  "error_handling": { ... },
  "data_formats": { ... },
  "confidence_score": 0.85,
  "source_attribution": { ... },
  "integration_notes": "Any special considerations for ${serviceName} integration"
}`;
}

function parseClaudeAnalysis(analysisText: string) {
  try {
    // Claude should return clean JSON, but handle edge cases
    const jsonMatch = analysisText.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    } else {
      // Fallback parsing if Claude didn't return pure JSON
      return parseStructuredText(analysisText);
    }
  } catch (error) {
    console.warn("Failed to parse Claude analysis as JSON:", error);
    return parseStructuredText(analysisText);
  }
}

function parseStructuredText(text: string) {
  // Fallback parser for non-JSON responses
  return {
    authentication: { method: "unknown", confidence: 0.1 },
    api_structure: { base_url: "unknown", confidence: 0.1 },
    endpoints: { confidence: 0.1 },
    headers: { required_headers: [], confidence: 0.1 },
    error_handling: { confidence: 0.1 },
    data_formats: { confidence: 0.1 },
    confidence_score: 0.1,
    source_attribution: {},
    integration_notes: "Analysis parsing failed - manual review needed",
  };
}

function calculateAnalysisConfidence(analysis: any) {
  if (!analysis) return 0;

  let totalScore = 0;
  let sectionCount = 0;

  const sections = ["authentication", "api_structure", "endpoints", "headers"];

  sections.forEach((section) => {
    if (analysis[section]) {
      sectionCount++;
      const sectionConfidence = analysis[section].confidence || 0;
      totalScore += sectionConfidence;
    }
  });

  return sectionCount > 0 ? totalScore / sectionCount : 0;
}
