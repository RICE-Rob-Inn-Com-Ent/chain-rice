/**
 * Unified AI Bot Integration for Code-Rice
 * Connects to the unified AI bot API in devcontainer
 */

export interface AIResponse {
  model: string;
  response: string;
  usage?: {
    input_tokens: number;
    output_tokens: number;
    total_tokens?: number;
  };
  latency_ms: number;
  error?: string;
}

export async function chatWithAI(
  message: string,
  model?: string,
  systemPrompt?: string,
  maxTokens: number = 2000,
  temperature: number = 0.7
): Promise<AIResponse> {
  try {
    // Call the unified bot API (assuming it's exposed via API route or service)
    const response = await fetch("/api/ai/chat", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message,
        model,
        system_prompt: systemPrompt,
        max_tokens: maxTokens,
        temperature,
      }),
    });

    if (!response.ok) {
      throw new Error(`AI API error: ${response.statusText}`);
    }

    return await response.json();
  } catch (error) {
    return {
      model: model || "unknown",
      response: "",
      latency_ms: 0,
      error: error instanceof Error ? error.message : "Unknown error",
    };
  }
}

export async function generateModuleDescription(moduleName: string): Promise<string> {
  const result = await chatWithAI(
    `Generate a professional description for a software module named: ${moduleName}`,
    "claude",
    "You are a technical writer specializing in software documentation.",
    200
  );

  return result.response || "Description generation failed";
}

