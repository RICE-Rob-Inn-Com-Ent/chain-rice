import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { query, queryOne } from "@/lib/db";

// GET - Szczegóły pacjenta
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const patient = await queryOne(
      `SELECT 
        u.id, get_patient_number(u.id) as patient_number, u.first_name, u.last_name, u.email, get_user_phone(u.id) as phone,
        u.date_of_birth, u.pesel, u.address, u.city, u.postal_code, u.country,
        u.notes, u.insurance_number, u.active, u.created_at, u.updated_at
       FROM users u
       WHERE u.id = $1
         AND NOT EXISTS (
          (u.id::text LIKE 'ADM-%' OR u.id::text LIKE 'SUP-%' OR u.id::text LIKE 'DOC-%')
        )`,
      [params.id]
    );

    if (!patient) {
      return NextResponse.json({ error: "Pacjent nie znaleziony" }, { status: 404 });
    }

    return NextResponse.json({ patient });
  } catch (error: any) {
    console.error("Get patient error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PUT - Aktualizuj pacjenta
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
      first_name,
      last_name,
      email,
      phone,
      date_of_birth,
      pesel,
      address,
      city,
      postal_code,
      country,
      notes,
      insurance_number,
      active,
    } = body;

    const result = await queryOne(
      `UPDATE users SET
        first_name = COALESCE($1, first_name),
        last_name = COALESCE($2, last_name),
        email = COALESCE($3, email),
        phone = COALESCE($4, phone),
        date_of_birth = COALESCE($5, date_of_birth),
        pesel = COALESCE($6, pesel),
        address = COALESCE($7, address),
        city = COALESCE($8, city),
        postal_code = COALESCE($9, postal_code),
        country = COALESCE($10, country),
        notes = COALESCE($11, notes),
        insurance_number = COALESCE($12, insurance_number),
        active = COALESCE($13, active),
        display_name = CONCAT(
          COALESCE($1, first_name),
          ' ',
          COALESCE($2, last_name)
        ),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $14
        AND NOT (users.id::text LIKE 'ADM-%' OR users.id::text LIKE 'SUP-%' OR users.id::text LIKE 'DOC-%')
      RETURNING *`,
      [
        first_name,
        last_name,
        email,
        phone,
        date_of_birth,
        pesel,
        address,
        city,
        postal_code,
        country,
        notes,
        insurance_number,
        active,
        params.id,
      ]
    );

    return NextResponse.json({ success: true, patient: result });
  } catch (error: any) {
    console.error("Update patient error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// DELETE - Usuń pacjenta
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await getCurrentUser();
    if (!user || (user.role !== "admin" && user.role !== "superadmin")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    await query(
      `DELETE FROM users 
       WHERE id = $1
         AND NOT EXISTS (
           SELECT 1 FROM user_roles ur
           WHERE ur.user_id = users.id AND ur.role IN ('admin', 'dentist', 'superadmin')
         )`,
      [params.id]
    );

    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error("Delete patient error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}


