import { NextRequest, NextResponse } from "next/server";

const GOD_API_PORTS: Record<string, number> = {
  thoth: 8001,
  ra: 8002,
  isis: 8003,
  bastet: 8004,
  maat: 8005,
  khnum: 8006,
};

export async function GET(request: NextRequest, { params }: { params: { god: string } }) {
  const { god } = params;
  const apiPort = GOD_API_PORTS[god];

  if (!apiPort) {
    return NextResponse.json({ error: "Unknown god" }, { status: 404 });
  }

  try {
    const response = await fetch(`http://localhost:${apiPort}/health`, {
      signal: AbortSignal.timeout(3000),
    });

    if (response.ok) {
      const data = await response.json();
      return NextResponse.json({
        ...data,
        port: apiPort,
      });
    }

    return NextResponse.json({ god, status: "inactive" }, { status: 503 });
  } catch (error) {
    return NextResponse.json({ god, status: "inactive", error: "Unreachable" }, { status: 503 });
  }
}
