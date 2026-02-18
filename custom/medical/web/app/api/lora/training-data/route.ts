import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";

const CERAI_LORA_URL = process.env.CERAI_LORA_URL || "http://cerai-lora:8007";

// GET - List all training data files
export async function GET(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Check if user is admin
    const isAdmin = user.id.startsWith("ADM-") || user.id.startsWith("SUP-");
    if (!isAdmin) {
      return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    }

    // Fetch list of training files from LoRA service
    const response = await fetch(`${CERAI_LORA_URL}/training-data`, {
      method: "GET",
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (!response.ok) {
      // If endpoint doesn't exist, return empty list
      return NextResponse.json({ files: [] });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error: any) {
    console.error("Error fetching training data:", error);
    return NextResponse.json(
      { error: error.message || "Failed to fetch training data" },
      { status: 500 }
    );
  }
}

// POST - Create new training data file
export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const isAdmin = user.id.startsWith("ADM-") || user.id.startsWith("SUP-");
    if (!isAdmin) {
      return NextResponse.json({ error: "Forbidden" }, { status: 403 });
    }

    const body = await request.json();
    const { filename, data, adapter_type } = body;

    if (!filename || !data || !adapter_type) {
      return NextResponse.json(
        { error: "Missing required fields: filename, data, adapter_type" },
        { status: 400 }
      );
    }

    // Forward to LoRA service
    const response = await fetch(`${CERAI_LORA_URL}/training-data`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ filename, data, adapter_type }),
    });

    if (!response.ok) {
      const error = await response.text();
      return NextResponse.json(
        { error: error || "Failed to create training data" },
        { status: response.status }
      );
    }

    const result = await response.json();
    return NextResponse.json(result, { status: 201 });
  } catch (error: any) {
    console.error("Error creating training data:", error);
    return NextResponse.json(
      { error: error.message || "Failed to create training data" },
      { status: 500 }
    );
  }
}



