import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { query, queryOne } from "@/lib/db";

// GET - Lista dentystów
export async function GET(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const dentists = await query(
      `SELECT d.*, u.email as user_email, u.display_name as user_display_name
       FROM dentists d
       LEFT JOIN users u ON d.user_id = u.id
       ORDER BY d.last_name, d.first_name`
    );

    return NextResponse.json({ dentists: dentists.rows });
  } catch (error: any) {
    console.error("Get dentists error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST - Utwórz dentystę
export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || (user.role !== "admin" && user.role !== "superadmin")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const {
      license_number,
      user_id,
      first_name,
      last_name,
      email,
      phone,
      specialization,
      clinic_location,
      bio,
      hourly_rate,
    } = body;

    if (!license_number || !first_name || !last_name) {
      return NextResponse.json(
        { error: "Numer licencji, imię i nazwisko są wymagane" },
        { status: 400 }
      );
    }

    const result = await queryOne<{ id: string }>(
      `INSERT INTO dentists (
        license_number, user_id, first_name, last_name, email, phone,
        specialization, clinic_location, bio, hourly_rate
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING *`,
      [
        license_number,
        user_id || null,
        first_name,
        last_name,
        email || null,
        phone || null,
        specialization || [],
        clinic_location || "ceramix",
        bio || null,
        hourly_rate || null,
      ]
    );

    return NextResponse.json({ success: true, dentist: result });
  } catch (error: any) {
    console.error("Create dentist error:", error);
    if (error.code === "23505") {
      return NextResponse.json({ error: "Dentysta z tym numerem licencji już istnieje" }, { status: 409 });
    }
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
























































