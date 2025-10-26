import { NextResponse } from "next/server";

const GOD_OLLAMA_PORTS: Record<string, number> = {
  thoth: 11434,
  maat: 11438,
  khnum: 11439,
};

const GOD_MODELS: Record<string, string> = {
  thoth: "mistral:7b-instruct-q4_K_M",
  maat: "mistral:7b-instruct-q4_K_M",
  khnum: "mistral:7b-instruct-q4_K_M",
};

export async function POST(_: Request, { params }: { params: { god: string } }) {
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
