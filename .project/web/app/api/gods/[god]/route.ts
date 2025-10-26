import { NextRequest, NextResponse } from "next/server";

const GOD_PORTS: Record<string, number> = {
  thoth: 11434,
  ra: 11435,
  anubis: 11436,
  isis: 11437,
  horus: 11438,
};

const GOD_MODELS: Record<string, string> = {
  thoth: "mistral:latest",
  ra: "llama3.2:3b",
  anubis: "deepseek-coder:6.7b",
  isis: "phi4:latest",
  horus: "gemma2:2b",
};

export async function POST(request: NextRequest, { params }: { params: { god: string } }) {
  const { god } = params;
  const port = GOD_PORTS[god];

  if (!port) {
    return NextResponse.json({ error: "Unknown god" }, { status: 404 });
  }

  try {
    const { messages } = await request.json();

    if (!messages || !Array.isArray(messages)) {
      return NextResponse.json({ error: "Invalid messages format" }, { status: 400 });
    }

    const startTime = Date.now();

    const response = await fetch(`http://localhost:${port}/api/chat`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        model: GOD_MODELS[god],
        messages,
        stream: false,
      }),
    });

    if (!response.ok) {
      throw new Error(`Ollama API error: ${response.statusText}`);
    }

    const data = await response.json();
    const responseTime = Date.now() - startTime;

    return NextResponse.json({
      message: data.message.content,
      godId: god,
      metrics: {
        responseTime,
        tokensGenerated: data.eval_count || 0,
        tokensPerSecond: data.eval_count ? Math.round((data.eval_count / responseTime) * 1000) : 0,
      },
    });
  } catch (error) {
    console.error(`Failed to invoke ${god}:`, error);
    return NextResponse.json(
      { error: "Failed to invoke god", details: error instanceof Error ? error.message : "Unknown error" },
      { status: 500 }
    );
  }
}
