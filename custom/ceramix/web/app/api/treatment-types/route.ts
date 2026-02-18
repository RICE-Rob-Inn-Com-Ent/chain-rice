import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { queryMany } from "@/lib/db";

// GET - Lista typów leczenia
export async function GET(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const treatmentTypes = await queryMany<{
      id: string;
      code: string;
      name: string;
      description: string;
      default_duration_minutes: number;
      default_price: number;
      category: string;
    }>(
      `SELECT id, code, name, description, default_duration_minutes, default_price, category
       FROM treatment_types
       WHERE active = true
       ORDER BY category, name`
    );

    return NextResponse.json({ treatment_types: treatmentTypes });
  } catch (error: any) {
    console.error("Get treatment types error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
























































