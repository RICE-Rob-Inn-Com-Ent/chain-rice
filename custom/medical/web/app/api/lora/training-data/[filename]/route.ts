import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";

const CERAI_LORA_URL = process.env.CERAI_LORA_URL || "http://cerai-lora:8007";

// GET - Get specific training data file
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ filename: string }> }
) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const isAdmin = user.id.startsWith("ADM-") || user.id.startsWith("SUP-");
    if (!isAdmin) {
      return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    }

    const resolvedParams = await params;
    const filename = resolvedParams.filename;

    const response = await fetch(
      `${CERAI_LORA_URL}/training-data/${encodeURIComponent(filename)}`,
      {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      }
    );

    if (!response.ok) {
      return NextResponse.json(
        { error: "File not found" },
        { status: 404 }
      );
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error: any) {
    console.error("Error fetching training data file:", error);
    return NextResponse.json(
      { error: error.message || "Failed to fetch file" },
      { status: 500 }
    );
  }
}

// PUT - Update training data file
export async function PUT(
  request: NextRequest,
  { params }: { params: Promise<{ filename: string }> }
) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const isAdmin = user.id.startsWith("ADM-") || user.id.startsWith("SUP-");
    if (!isAdmin) {
      return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    }

    const resolvedParams = await params;
    const filename = resolvedParams.filename;
    const body = await request.json();
    const { data } = body;

    if (!data) {
      return NextResponse.json(
        { error: "Missing required field: data" },
        { status: 400 }
      );
    }

    const response = await fetch(
      `${CERAI_LORA_URL}/training-data/${encodeURIComponent(filename)}`,
      {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ data }),
      }
    );

    if (!response.ok) {
      const error = await response.text();
      return NextResponse.json(
        { error: error || "Failed to update file" },
        { status: response.status }
      );
    }

    const result = await response.json();
    return NextResponse.json(result);
  } catch (error: any) {
    console.error("Error updating training data:", error);
    return NextResponse.json(
      { error: error.message || "Failed to update file" },
      { status: 500 }
    );
  }
}

// DELETE - Delete training data file
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ filename: string }> }
) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const isAdmin = user.id.startsWith("ADM-") || user.id.startsWith("SUP-");
    if (!isAdmin) {
      return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    }

    const resolvedParams = await params;
    const filename = resolvedParams.filename;

    const response = await fetch(
      `${CERAI_LORA_URL}/training-data/${encodeURIComponent(filename)}`,
      {
        method: "DELETE",
      }
    );

    if (!response.ok) {
      return NextResponse.json(
        { error: "Failed to delete file" },
        { status: response.status }
      );
    }

    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error("Error deleting training data:", error);
    return NextResponse.json(
      { error: error.message || "Failed to delete file" },
      { status: 500 }
    );
  }
}



