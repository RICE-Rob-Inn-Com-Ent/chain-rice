import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { query, queryOne } from "@/lib/db";

// GET - Szczegóły dentysty
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const dentist = await queryOne(
      `SELECT d.*, u.email as user_email, u.display_name as user_display_name
       FROM dentists d
       LEFT JOIN users u ON d.user_id = u.id
       WHERE d.id = $1`,
      [params.id]
    );

    if (!dentist) {
      return NextResponse.json({ error: "Dentysta nie znaleziony" }, { status: 404 });
    }

    return NextResponse.json({ dentist });
  } catch (error: any) {
    console.error("Get dentist error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PUT - Aktualizuj dentystę
export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
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
      active,
    } = body;

    const result = await queryOne(
      `UPDATE dentists SET
        license_number = COALESCE($1, license_number),
        user_id = COALESCE($2, user_id),
        first_name = COALESCE($3, first_name),
        last_name = COALESCE($4, last_name),
        email = COALESCE($5, email),
        phone = COALESCE($6, phone),
        specialization = COALESCE($7, specialization),
        clinic_location = COALESCE($8, clinic_location),
        bio = COALESCE($9, bio),
        hourly_rate = COALESCE($10, hourly_rate),
        active = COALESCE($11, active),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $12
      RETURNING *`,
      [
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
        active,
        params.id,
      ]
    );

    return NextResponse.json({ success: true, dentist: result });
  } catch (error: any) {
    console.error("Update dentist error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// DELETE - Usuń dentystę
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await getCurrentUser();
    if (!user || (user.role !== "admin" && user.role !== "superadmin")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    await query(`DELETE FROM dentists WHERE id = $1`, [params.id]);

    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error("Delete dentist error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
























































