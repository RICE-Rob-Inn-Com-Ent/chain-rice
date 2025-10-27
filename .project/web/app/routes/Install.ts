import { NextResponse } from "next/server";

// Porty Ollama dla każdego boga
const GOD_OLLAMA_PORTS: Record<string, number> = {
  thoth: 11434,
  maat: 11438,
  khnum: 11439,
};

// Modele dla każdego boga
const GOD_MODELS: Record<string, string> = {
  thoth: "mistral:7b-instruct-q4_K_M",
  maat: "mistral:7b-instruct-q4_K_M",
  khnum: "mistral:7b-instruct-q4_K_M",
};

// Porty API dla bogów bez Ollama
const GOD_API_PORTS: Record<string, number> = {
  thoth: 8001,
  ra: 8002,
  isis: 8003,
  bastet: 8004,
  maat: 8005,
  khnum: 8006,
};

/**
 * Sprawdza czy model danego boga jest zainstalowany
 * GET /api/gods/[god]/installed
 */
export async function checkInstalled(_: Request, { params }: { params: { god: string } }) {
  const { god } = params;
  const ollamaPort = GOD_OLLAMA_PORTS[god];
  const model = GOD_MODELS[god];

  // Jeśli nie jest obsługiwany przez Ollama, sprawdź health backendu (jeśli istnieje)
  if (!ollamaPort || !model) {
    const apiPort = GOD_API_PORTS[god];
    if (!apiPort) {
      return NextResponse.json({ god, installed: false, unknown: true });
    }
    try {
      const health = await fetch(`http://localhost:${apiPort}/health`, { signal: AbortSignal.timeout(3000) });
      return NextResponse.json({ god, installed: health.ok, source: "health" });
    } catch {
      return NextResponse.json({ god, installed: false, source: "health" });
    }
  }

  try {
    const res = await fetch(`http://localhost:${ollamaPort}/api/tags`, { signal: AbortSignal.timeout(5000) });
    if (!res.ok) {
      return NextResponse.json({ god, installed: false, model });
    }
    const data = await res.json();
    const tags = Array.isArray(data.models) ? data.models : Array.isArray(data) ? data : [];
    const hasModel = tags.some((t: any) => t?.name === model);
    return NextResponse.json({ god, installed: hasModel, model });
  } catch (e) {
    return NextResponse.json({ god, installed: false, model, error: "unreachable" }, { status: 200 });
  }
}

/**
 * Instaluje model dla danego boga
 * POST /api/gods/[god]/install
 */
export async function installModel(_: Request, { params }: { params: { god: string } }) {
  const { god } = params;
  const ollamaPort = GOD_OLLAMA_PORTS[god];
  const model = GOD_MODELS[god];

  if (!ollamaPort || !model) {
    return NextResponse.json({ error: "Unknown or unsupported god" }, { status: 400 });
  }

  try {
    const pullRes = await fetch(`http://localhost:${ollamaPort}/api/pull`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name: model, stream: false }),
      signal: AbortSignal.timeout(10 * 60 * 1000), // 10 min
    });
    if (!pullRes.ok) {
      const txt = await pullRes.text();
      return NextResponse.json({ success: false, error: txt }, { status: 500 });
    }
    return NextResponse.json({ success: true, god, model });
  } catch (e: any) {
    return NextResponse.json({ success: false, error: e?.message || "failed" }, { status: 500 });
  }
}

// Eksport stałych dla użycia w innych miejscach
export { GOD_OLLAMA_PORTS, GOD_MODELS, GOD_API_PORTS };
