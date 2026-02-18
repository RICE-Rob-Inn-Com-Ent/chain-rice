import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { query, queryOne } from "@/lib/db";

// GET - Szczegóły wizyty
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const appointment = await queryOne(
      `SELECT 
        a.*,
        p.first_name as patient_first_name,
        p.last_name as patient_last_name,
        get_patient_number(p.id) as patient_number,
        p.email as patient_email,
        get_user_phone(p.id) as patient_phone,
        d.first_name as dentist_first_name,
        d.last_name as dentist_last_name,
        d.license_number
      FROM appointments a
      JOIN users p ON a.patient_id::text = p.id
      JOIN dentists d ON a.dentist_id::text = d.id
      WHERE a.id = $1`,
      [params.id]
    );

    if (!appointment) {
      return NextResponse.json({ error: "Wizyta nie znaleziona" }, { status: 404 });
    }

    // Sprawdź uprawnienia - dentysta widzi tylko swoje wizyty
    if (user.role === "dentist") {
      const dentist = await queryOne(`SELECT id FROM dentists WHERE user_id = $1`, [user.id]);
      if (!dentist || appointment.dentist_id !== dentist.id) {
        return NextResponse.json({ error: "Brak dostępu" }, { status: 403 });
      }
    }

    return NextResponse.json({ appointment });
  } catch (error: any) {
    console.error("Get appointment error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PUT - Aktualizuj wizytę
export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await getCurrentUser();
    if (!user || (user.role !== "admin" && user.role !== "superadmin" && user.role !== "dentist")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const {
      patient_id,
      dentist_id,
      appointment_date,
      appointment_time,
      duration_minutes,
      status,
      treatment_type,
      treatment_description,
      notes,
      price,
      paid,
      payment_method,
    } = body;

    // Sprawdź uprawnienia
    if (user.role === "dentist") {
      const appointment = await queryOne(`SELECT dentist_id FROM appointments WHERE id = $1`, [params.id]);
      const dentist = await queryOne(`SELECT id FROM dentists WHERE user_id = $1`, [user.id]);
      if (!dentist || appointment?.dentist_id !== dentist.id) {
        return NextResponse.json({ error: "Możesz edytować tylko swoje wizyty" }, { status: 403 });
      }
    }

    const result = await queryOne(
      `UPDATE appointments SET
        patient_id = COALESCE($1, patient_id),
        dentist_id = COALESCE($2, dentist_id),
        appointment_date = COALESCE($3, appointment_date),
        appointment_time = COALESCE($4, appointment_time),
        duration_minutes = COALESCE($5, duration_minutes),
        status = COALESCE($6, status),
        treatment_type = COALESCE($7, treatment_type),
        treatment_description = COALESCE($8, treatment_description),
        notes = COALESCE($9, notes),
        price = COALESCE($10, price),
        paid = COALESCE($11, paid),
        payment_method = COALESCE($12, payment_method),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $13
      RETURNING *`,
      [
        patient_id,
        dentist_id,
        appointment_date,
        appointment_time,
        duration_minutes,
        status,
        treatment_type,
        treatment_description,
        notes,
        price,
        paid,
        payment_method,
        params.id,
      ]
    );

    return NextResponse.json({ success: true, appointment: result });
  } catch (error: any) {
    console.error("Update appointment error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// DELETE - Usuń wizytę
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await getCurrentUser();
    if (!user || (user.role !== "admin" && user.role !== "superadmin")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    await query(`DELETE FROM appointments WHERE id = $1`, [params.id]);

    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error("Delete appointment error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}


