import { NextRequest, NextResponse } from "next/server";

const GOD_OLLAMA_PORTS: Record<string, number> = {
  thoth: 11434,
  maat: 11438,
  khnum: 11439,
};

const GOD_API_PORTS: Record<string, number> = {
  thoth: 8001,
  ra: 8002,
  isis: 8003,
  bastet: 8004,
  maat: 8005,
  khnum: 8006,
};

const GOD_MODELS: Record<string, string> = {
  thoth: "mistral:7b-instruct-q4_K_M",
  maat: "mistral:7b-instruct-q4_K_M",
  khnum: "mistral:7b-instruct-q4_K_M",
  ra: "stable-diffusion-2.1",
  isis: "monai",
  bastet: "insightface",
};

export async function POST(request: NextRequest, { params }: { params: { god: string } }) {
  const { god } = params;
  const ollamaPort = GOD_OLLAMA_PORTS[god];
  const apiPort = GOD_API_PORTS[god];
  const model = GOD_MODELS[god];

  if (!apiPort || !model) {
    return NextResponse.json({ error: "Unknown god" }, { status: 404 });
  }

  try {
    const startTime = Date.now();

    // Step 1: Clear VRAM - sleep all other gods first
    console.log(`[${god}] Step 1: Clearing VRAM from other gods...`);
    for (const otherGod of Object.keys(GOD_API_PORTS)) {
      if (otherGod !== god) {
        try {
          await fetch(`http://localhost:3000/api/gods/${otherGod}/sleep`, {
            method: "POST",
          });
        } catch (e) {
          // Ignore errors - god might not be running
        }
      }
    }

    // Wait for VRAM to clear
    await new Promise((resolve) => setTimeout(resolve, 2000));

    // Step 2: Check if god is healthy
    console.log(`[${god}] Step 2: Checking health...`);
    const healthResponse = await fetch(`http://localhost:${apiPort}/health`, {
      signal: AbortSignal.timeout(5000),
    });

    if (!healthResponse.ok) {
      throw new Error("God container not running or unhealthy");
    }

    // Step 3: For Ollama-based gods, pull/load model from cache
    if (ollamaPort) {
      console.log(`[${god}] Step 3: Loading model from cache...`);
      const pullResponse = await fetch(`http://localhost:${ollamaPort}/api/pull`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: model, stream: false }),
        signal: AbortSignal.timeout(120000), // 2 minute timeout
      });

      if (!pullResponse.ok) {
        throw new Error("Failed to load model from cache");
      }

      // Step 4: Warm up with test generation
      console.log(`[${god}] Step 4: Warming up model...`);
      await fetch(`http://localhost:${ollamaPort}/api/generate`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          model,
          prompt: "test",
          stream: false,
        }),
        signal: AbortSignal.timeout(60000),
      });
    }

    const loadTime = Date.now() - startTime;

    console.log(`[${god}] ✅ Awakened in ${loadTime}ms`);

    return NextResponse.json({
      success: true,
      godId: god,
      model: model,
      message: `${god} awakened from cache`,
      loadTimeMs: loadTime,
      steps: {
        vram_cleared: true,
        health_checked: true,
        model_loaded: true,
        warmed_up: ollamaPort ? true : false,
      },
    });
  } catch (error) {
    console.error(`Failed to wake ${god}:`, error);
    return NextResponse.json(
      {
        success: false,
        error: "Failed to wake god",
        details: error instanceof Error ? error.message : "Unknown error",
        hint: "Make sure god container is running: docker-compose up -d " + god,
      },
      { status: 500 }
    );
  }
}
