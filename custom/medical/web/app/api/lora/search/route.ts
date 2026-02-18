import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";

const CERAI_LORA_URL = process.env.CERAI_LORA_URL || "http://cerai-lora:8007";

// POST - Search training data by context
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
    const { query, adapter_type, limit = 10 } = body;

    if (!query) {
      return NextResponse.json(
        { error: "Missing required field: query" },
        { status: 400 }
      );
    }

    // Forward search to LoRA service
    const response = await fetch(`${CERAI_LORA_URL}/training-data/search`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ query, adapter_type, limit }),
    });

    if (!response.ok) {
      // If endpoint doesn't exist, return empty results
      return NextResponse.json({ results: [] });
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error: any) {
    console.error("Error searching training data:", error);
    return NextResponse.json(
      { error: error.message || "Failed to search" },
      { status: 500 }
    );
  }
}



