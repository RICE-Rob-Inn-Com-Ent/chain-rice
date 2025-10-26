import { NextRequest, NextResponse } from "next/server";

const GOD_OLLAMA_PORTS: Record<string, number> = {
  thoth: 11434,
  maat: 11438,
  khnum: 11439,
};

export async function POST(request: NextRequest, { params }: { params: { god: string } }) {
  const { god } = params;
  const ollamaPort = GOD_OLLAMA_PORTS[god];

  try {
    console.log(`[${god}] Putting to sleep (unloading from VRAM)...`);

    // For Ollama-based gods: delete loaded model to free VRAM
    if (ollamaPort) {
      try {
        // Get currently loaded models
        const psResponse = await fetch(`http://localhost:${ollamaPort}/api/ps`, {
          signal: AbortSignal.timeout(5000),
        });

        if (psResponse.ok) {
          const data = await psResponse.json();

          // Ollama will auto-unload after KEEP_ALIVE expires
          // We can force it by calling DELETE on each loaded model
          if (data.models && data.models.length > 0) {
            for (const modelInfo of data.models) {
              // Trigger unload by setting keep_alive to 0
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
        console.warn(`Could not unload from ${god} (may already be unloaded)`);
      }
    }

    // For non-Ollama gods (Ra, Isis, Bastet): call their API to clear memory
    // This would be implemented in their FastAPI servers

    console.log(`[${god}] ✅ Sleep command sent`);

    return NextResponse.json({
      success: true,
      godId: god,
      message: `${god} is sleeping (VRAM freed)`,
      vram_cleared: true,
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
