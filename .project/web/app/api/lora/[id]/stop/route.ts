import { NextRequest, NextResponse } from "next/server";

export async function POST(request: NextRequest, { params }: { params: { id: string } }) {
  const { id } = params;

  try {
    // Stop training (would call gRPC service in real implementation)
    return NextResponse.json({
      success: true,
      message: "Training stopped",
    });
  } catch (error) {
    console.error(`Failed to stop training for ${id}:`, error);
    return NextResponse.json({ error: "Failed to stop training" }, { status: 500 });
  }
}
