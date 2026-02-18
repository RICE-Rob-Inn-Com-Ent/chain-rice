import { NextRequest, NextResponse } from "next/server";
import { randomUUID } from "crypto";
import { getCurrentUser } from "@/lib/auth";
import { query, queryOne } from "@/lib/db";
import { upsertPatientProfile } from "@/lib/patient-profiles";
import { generateUserId } from "@/lib/user-id-generator";

// GET - Lista pacjentów
export async function GET(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const search = searchParams.get("search") || "";
    const limit = parseInt(searchParams.get("limit") || "100");
    const offset = parseInt(searchParams.get("offset") || "0");

    let sql = `
      SELECT 
        u.id, get_patient_number(u.id) as patient_number, u.first_name, u.last_name, u.email, get_user_phone(u.id) as phone,
        u.date_of_birth, u.created_at, u.active
      FROM users u
      WHERE u.id::text NOT LIKE 'ADM-%'
        AND u.id::text NOT LIKE 'SUP-%'
        AND u.id::text NOT LIKE 'DOC-%'
    `;
    const params: any[] = [];
    let paramIndex = 1;

    if (search) {
      sql += ` AND (
        u.first_name ILIKE $${paramIndex} OR 
        u.last_name ILIKE $${paramIndex} OR 
        u.display_name ILIKE $${paramIndex} OR 
        u.email ILIKE $${paramIndex} OR 
        get_user_phone(u.id) ILIKE $${paramIndex} OR
        get_patient_number(u.id) ILIKE $${paramIndex}
      )`;
      params.push(`%${search}%`);
      paramIndex++;
    }

    sql += ` ORDER BY u.created_at DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(limit, offset);

    const patients = await query(sql, params);

    return NextResponse.json({ patients: patients.rows, total: patients.rows.length });
  } catch (error: any) {
    console.error("Get patients error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST - Utwórz pacjenta
export async function POST(request: NextRequest) {
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
      patient_profile,
    } = body;

    if (!first_name || !last_name) {
      return NextResponse.json({ error: "Imię i nazwisko są wymagane" }, { status: 400 });
    }

    let normalizedEmail = email?.trim().toLowerCase() || "";

    if (normalizedEmail) {
      const existingUser = await queryOne<{ id: string }>(
        `SELECT id FROM users WHERE email = $1`,
        [normalizedEmail]
      );

      if (existingUser) {
        return NextResponse.json(
          { error: "Użytkownik z tym emailem już istnieje" },
          { status: 409 }
        );
      }
    } else {
      normalizedEmail = `patient-${randomUUID()}@ceramix.local`;
    }

    // Generate role-based user ID (patient role)
    const userId = await generateUserId("patient");

    const result = await queryOne<{ id: string; patient_number: string | null }>(
      `INSERT INTO users (
        id,
        email,
        password_hash,
        display_name,
        first_name,
        last_name,
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
        email_verified,
        account_state
      )
      VALUES (
        $1, $2, NULL, $3, $4,
        $5, $6, $7, $8, $9,
        $10, $11, $12, $13, $14,
        true, false, 'ACTIVE'
      )
      RETURNING id, get_patient_number(id) as patient_number`,
      [
        userId,
        normalizedEmail,
        `${first_name} ${last_name}`,
        first_name,
        last_name,
        phone || null,
        date_of_birth || null,
        pesel || null,
        address || null,
        city || null,
        postal_code || null,
        country || "Polska",
        notes || null,
        insurance_number || null,
      ]
    );

    if (!result) {
      return NextResponse.json({ error: "Nie udało się utworzyć pacjenta" }, { status: 500 });
    }

    // Role is now in ID prefix - no need to insert into user_roles

    await upsertPatientProfile(result.id, patient_profile);

    return NextResponse.json({ success: true, patient: result });
  } catch (error: any) {
    console.error("Create patient error:", error);
    if (error.code === "23505") {
      return NextResponse.json({ error: "Pacjent z tym numerem już istnieje" }, { status: 409 });
    }
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}


