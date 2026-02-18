/**
 * Unified AI Bot Integration for Meowtopia
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
  temperature: number = 0.8
): Promise<AIResponse> {
  try {
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

export async function getProductRecommendation(userPreferences: string): Promise<string> {
  const result = await chatWithAI(
    `Recommend pet products based on these preferences: ${userPreferences}`,
    "gemini",
    "You are a pet care expert helping customers find the perfect products for their pets.",
    300,
    0.8
  );

  return result.response || "Recommendation generation failed";
}

