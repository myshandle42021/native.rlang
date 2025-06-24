// utils/serpapi.ts - SerpAPI Integration for Dynamic Service Discovery
import { RLangContext } from "../schema/types";

// Production-ready error type guard
function isError(error: unknown): error is Error {
  return error instanceof Error;
}

function getErrorMessage(error: unknown): string {
  if (isError(error)) return error.message;
  if (typeof error === "string") return error;
  return String(error);
}

const SERPAPI_KEY = process.env.SERPAPI_API_KEY;

export async function search(args: any, context: RLangContext) {
  if (!SERPAPI_KEY) {
    throw new Error("SERPAPI_API_KEY not configured");
  }

  const {
    query,
    type = "web",
    num_results = 10,
    focus = [],
    location = "United States",
  } = args;

  try {
    const searchParams = new URLSearchParams({
      api_key: SERPAPI_KEY,
      q: query,
      num: num_results.toString(),
      location: location,
      hl: "en",
      gl: "us",
    });

    // Add type-specific parameters
    if (type === "web") {
      // Standard web search - good for general API documentation
    } else if (type === "documentation_search") {
      // Enhanced search for technical documentation
      searchParams.append(
        "q",
        `${query} site:docs.* OR site:developer.* OR site:api.*`,
      );
    } else if (type === "github_search") {
      // Search GitHub for code examples
      searchParams.append("q", `${query} site:github.com`);
    }

    const response = await fetch(`https://serpapi.com/search?${searchParams}`);

    if (!response.ok) {
      throw new Error(
        `SerpAPI error: ${response.status} ${response.statusText}`,
      );
    }

    const data = (await response.json()) as any;

    // Process and filter results based on focus areas
    const processedResults = processSearchResults(data, focus);

    return {
      success: true,
      results: processedResults,
      total_results: data.search_metadata?.total_results || 0,
      search_time: data.search_metadata?.processed_at,
      query_used: query,
    };
  } catch (error) {
    console.error("SerpAPI search failed:", error);
    return {
      success: false,
      error: getErrorMessage(error),
      results: [],
    };
  }
}

function processSearchResults(data: any, focus: string[]) {
  const results = data.organic_results || [];

  return results
    .map((result: any) => ({
      title: result.title,
      url: result.link,
      snippet: result.snippet,
      relevance_score: calculateRelevanceScore(result, focus),
      source_type: identifySourceType(result.link),
      content_indicators: extractContentIndicators(result),
    }))
    .sort((a: any, b: any) => b.relevance_score - a.relevance_score);
}

function calculateRelevanceScore(result: any, focus: string[]) {
  let score = 0;
  const text = `${result.title} ${result.snippet}`.toLowerCase();

  // Base relevance factors
  if (text.includes("api documentation")) score += 10;
  if (text.includes("developer guide")) score += 8;
  if (text.includes("rest api")) score += 7;
  if (text.includes("authentication")) score += 6;
  if (text.includes("endpoints")) score += 5;

  // Focus area bonuses
  focus.forEach((focusArea) => {
    if (text.includes(focusArea.toLowerCase())) {
      score += 5;
    }
  });

  // Source quality bonuses
  if (result.link.includes("docs.") || result.link.includes("developer."))
    score += 8;
  if (result.link.includes("api.")) score += 6;
  if (result.link.includes("github.com")) score += 4;

  return score;
}

function identifySourceType(url: string) {
  if (url.includes("docs.") || url.includes("documentation"))
    return "official_docs";
  if (url.includes("developer.")) return "developer_portal";
  if (url.includes("api.")) return "api_reference";
  if (url.includes("github.com")) return "code_repository";
  if (url.includes("stackoverflow.com")) return "community_qa";
  if (url.includes("medium.com") || url.includes("blog."))
    return "tutorial_blog";
  return "general_web";
}

function extractContentIndicators(result: any) {
  const text = `${result.title} ${result.snippet}`.toLowerCase();
  const indicators = [];

  if (text.includes("oauth")) indicators.push("oauth_auth");
  if (text.includes("api key")) indicators.push("api_key_auth");
  if (text.includes("bearer token")) indicators.push("bearer_auth");
  if (text.includes("rate limit")) indicators.push("rate_limiting");
  if (text.includes("endpoint")) indicators.push("endpoints");
  if (text.includes("example") || text.includes("tutorial"))
    indicators.push("examples");
  if (text.includes("swagger") || text.includes("openapi"))
    indicators.push("api_spec");

  return indicators;
}

// Enhanced web scraping for detailed documentation content
export async function scrapeDocumentation(args: any, context: RLangContext) {
  const { urls, max_pages = 5, focus_sections = [] } = args;

  const scrapedContent: any[] = [];
  let processedPages = 0;

  for (const url of urls.slice(0, max_pages)) {
    if (processedPages >= max_pages) break;

    try {
      const content = await scrapePageContent(url, focus_sections);
      if (content && content.quality_score > 0.3) {
        scrapedContent.push(content);
        processedPages++;
      }
    } catch (error) {
      console.warn(`Failed to scrape ${url}:`, getErrorMessage(error));
    }
  }

  return {
    content: scrapedContent,
    sources: scrapedContent.map((c) => c.url),
    quality_score: calculateAverageQuality(scrapedContent),
    total_pages: processedPages,
  };
}

async function scrapePageContent(url: string, focusSections: string[]) {
  const response = await fetch(url, {
    headers: {
      "User-Agent": "ROL3-ServiceDiscovery/1.0 (API Integration Bot)",
    },
  });

  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }

  const html = await response.text();

  // Extract relevant content sections
  const extractedContent = extractRelevantSections(html, focusSections);

  return {
    url: url,
    title: extractTitle(html),
    content: extractedContent,
    quality_score: assessContentQuality(extractedContent),
    extracted_at: new Date().toISOString(),
  };
}

function extractRelevantSections(html: string, focusSections: string[]) {
  // Simple content extraction - in production, use a proper HTML parser
  const sections: Record<string, any[]> = {
    authentication: extractSection(html, ["auth", "token", "key", "oauth"]),
    endpoints: extractSection(html, ["endpoint", "api", "rest", "url"]),
    examples: extractSection(html, ["example", "sample", "curl", "code"]),
    headers: extractSection(html, ["header", "authorization", "content-type"]),
    errors: extractSection(html, ["error", "status", "code", "response"]),
  };

  // Filter to focus sections if specified
  if (focusSections.length > 0) {
    const filtered: Record<string, any[]> = {};
    focusSections.forEach((section: string) => {
      if (sections[section]) {
        filtered[section] = sections[section];
      }
    });
    return filtered;
  }

  return sections;
}

function extractSection(html: string, keywords: string[]) {
  // Simplified extraction - look for content near keywords
  const content: any[] = [];

  keywords.forEach((keyword) => {
    const regex = new RegExp(`(.{0,200}${keyword}.{0,200})`, "gi");
    const matches = html.match(regex);
    if (matches) {
      content.push(...matches.map((match) => cleanText(match)));
    }
  });

  return content;
}

function cleanText(text: string) {
  return text
    .replace(/<[^>]*>/g, "") // Remove HTML tags
    .replace(/\s+/g, " ") // Normalize whitespace
    .trim();
}

function extractTitle(html: string) {
  const titleMatch = html.match(/<title[^>]*>([^<]+)</i);
  return titleMatch ? titleMatch[1] : "Unknown";
}

function assessContentQuality(content: any) {
  let score = 0;
  const sections = Object.keys(content);

  // More sections = higher quality
  score += sections.length * 0.1;

  // Check for valuable content indicators
  sections.forEach((section) => {
    if (content[section] && content[section].length > 0) {
      score += 0.2;

      // Bonus for authentication and endpoint info
      if (section === "authentication" || section === "endpoints") {
        score += 0.3;
      }
    }
  });

  return Math.min(score, 1.0);
}

function calculateAverageQuality(scrapedContent: any[]) {
  if (scrapedContent.length === 0) return 0;

  const total = scrapedContent.reduce(
    (sum, content) => sum + content.quality_score,
    0,
  );
  return total / scrapedContent.length;
}
