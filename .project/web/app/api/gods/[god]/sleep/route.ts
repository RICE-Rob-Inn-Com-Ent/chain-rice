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

export async function POST(request: NextRequest, { params }: { params: { god: string } }) {
  const { god } = params;
  const ollamaPort = GOD_OLLAMA_PORTS[god];
  const apiPort = GOD_API_PORTS[god];

  try {
    console.log(`[${god}] Putting to sleep...`);

    // Call god's /sleep endpoint (FastAPI)
    if (apiPort) {
      try {
        const sleepResponse = await fetch(`http://localhost:${apiPort}/sleep`, {
          method: "POST",
          signal: AbortSignal.timeout(5000),
        });

        if (sleepResponse.ok) {
          console.log(`[${god}] ✅ God marked as sleeping`);
        }
      } catch (e) {
        console.warn(`Could not call /sleep on ${god}:`, e);
      }
    }

    // For Ollama-based gods: unload model from VRAM
    if (ollamaPort) {
      try {
        // Get currently loaded models
        const psResponse = await fetch(`http://localhost:${ollamaPort}/api/ps`, {
          signal: AbortSignal.timeout(5000),
        });

        if (psResponse.ok) {
          const data = await psResponse.json();

          // Trigger unload by setting keep_alive to 0
          if (data.models && data.models.length > 0) {
            for (const modelInfo of data.models) {
              await fetch(`http://localhost:${ollamaPort}/api/generate`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                  model: modelInfo.name,
                  prompt: "",
                  keep_alive: 0, // Immediate unload
                }),
              });
            }
          }
        }
      } catch (e) {
        console.warn(`Could not unload Ollama models from ${god}:`, e);
      }
    }

    console.log(`[${god}] ✅ Sleep complete`);

    return NextResponse.json({
      success: true,
      godId: god,
      message: `${god} is sleeping`,
      vram_cleared: ollamaPort ? true : false,
    });
  } catch (error) {
    console.error(`Failed to sleep ${god}:`, error);
    return NextResponse.json(
      {
        success: false,
        error: "Failed to sleep god",
        details: error instanceof Error ? error.message : "Unknown error",
      },
      { status: 500 }
    );
  }
}
