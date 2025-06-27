// utils/claude-debug-api.ts
// Claude API integration specifically for ROL3 Auto-Debug System

import dotenv from 'dotenv';
dotenv.config();

interface ClaudeResponse {
  content: Array<{
    type: string;
    text: string;
  }>;
}

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

/**
 * Call Claude API with a prompt for debug analysis
 */
export async function callClaude(prompt: string): Promise<string> {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  
  if (!apiKey) {
    throw new Error('ANTHROPIC_API_KEY not found in environment variables');
  }

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01'
      },
      body: JSON.stringify({
        model: 'claude-3-sonnet-20240229',
        max_tokens: 4000,
        messages: [
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.3 // Balanced for analysis + creativity
      })
    });

    if (!response.ok) {
      const errorData = await response.text();
      throw new Error(`Claude API error: ${response.status} - ${errorData}`);
    }

    const data: ClaudeResponse = await response.json();
    
    if (!data.content || data.content.length === 0) {
      throw new Error('Empty response from Claude API');
    }

    return data.content[0].text;

  } catch (error) {
    throw new Error(`Claude debug API call failed: ${getErrorMessage(error)}`);
  }
}

/**
 * Test Claude API connection for debug system
 */
export async function testClaudeDebugAPI(): Promise<boolean> {
  try {
    const response = await callClaude('Reply with just "DEBUG_OK" to confirm the auto-debug API is working.');
    return response.toLowerCase().includes('debug_ok') || response.toLowerCase().includes('ok');
  } catch (error) {
    console.error('Claude debug API test failed:', error);
    return false;
  }
}

/**
 * Check if Claude is configured for debug system
 */
export function isClaudeDebugConfigured(): boolean {
  return !!process.env.ANTHROPIC_API_KEY;
}
