import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    // Validate
    if (!body.name || !body.baseGodId) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
    }

    // Create LoRa adapter (would call gRPC service in real implementation)
    const adapter = {
      id: `lora_${Date.now()}`,
      name: body.name,
      baseGodId: body.baseGodId,
      baseGodName: getGodName(body.baseGodId),
      status: "pending",
      progress: 0,
      currentEpoch: 0,
      totalEpochs: body.epochs || 3,
      loss: 0,
      accuracy: 0,
      config: {
        rank: body.rank || 8,
        alpha: body.alpha || 16,
        learningRate: body.learningRate || 0.0001,
        batchSize: body.batchSize || 4,
        epochs: body.epochs || 3,
        targetModules: body.targetModules || ["q_proj", "v_proj"],
      },
    };

    return NextResponse.json(adapter);
  } catch (error) {
    console.error("Failed to create LoRa adapter:", error);
    return NextResponse.json({ error: "Failed to create adapter" }, { status: 500 });
  }
}

function getGodName(godId: string): string {
  const names: Record<string, string> = {
    thoth: "Thoth",
    ra: "Ra",
    anubis: "Anubis",
    isis: "Isis",
    horus: "Horus",
  };
  return names[godId] || "Unknown";
}
