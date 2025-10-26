import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest, { params }: { params: { id: string } }) {
  const { id } = params;

  try {
    // Start training (would call gRPC service in real implementation)
    // This would interact with the training service in .bot directory

    return NextResponse.json({
      success: true,
      jobId: `train_${Date.now()}`,
      message: "Training started",
    });
  } catch (error) {
    console.error(`Failed to start training for ${id}:`, error);
    return NextResponse.json({ error: "Failed to start training" }, { status: 500 });
  }
}
