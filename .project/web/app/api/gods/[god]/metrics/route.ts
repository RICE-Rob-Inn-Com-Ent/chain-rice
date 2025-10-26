import { NextRequest, NextResponse } from "next/server";

const GOD_PORTS: Record<string, number> = {
  thoth: 11434,
  ra: 11435,
  anubis: 11436,
  isis: 11437,
  horus: 11438,
};

export async function GET(request: NextRequest, { params }: { params: { god: string } }) {
  const { god } = params;
  const port = GOD_PORTS[god];

  if (!port) {
    return NextResponse.json({ error: "Unknown god" }, { status: 404 });
  }

  try {
    // Get status from Ollama
    const response = await fetch(`http://localhost:${port}/api/tags`, {
      signal: AbortSignal.timeout(2000),
    });

    if (!response.ok) {
      throw new Error("God is not responding");
    }

    const data = await response.json();

    // Mock metrics (in real implementation, would get from cache-manager)
    return NextResponse.json({
      responseTime: Math.floor(Math.random() * 1000) + 500,
      tokensPerSecond: Math.floor(Math.random() * 50) + 20,
      gpuUtilization: Math.floor(Math.random() * 100),
      memoryUsed: Math.floor(Math.random() * 4000) + 2000,
    });
  } catch (error) {
    return NextResponse.json({ error: "Failed to get metrics" }, { status: 500 });
  }
}
