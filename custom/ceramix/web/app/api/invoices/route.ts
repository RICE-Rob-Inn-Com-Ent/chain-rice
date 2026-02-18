import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { query, queryOne } from "@/lib/db";

// GET - Lista faktur
export async function GET(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const status = searchParams.get("status");
    const patientId = searchParams.get("patient_id");
    const limit = parseInt(searchParams.get("limit") || "100");
    const offset = parseInt(searchParams.get("offset") || "0");

    let sql = `
      SELECT 
        i.id, i.invoice_number, i.issue_date, i.due_date, 
        i.total_amount, i.tax_amount, i.status, i.notes, i.created_at,
        i.patient_id,
        p.first_name as patient_first_name, p.last_name as patient_last_name
      FROM invoices i
      JOIN users p ON i.patient_id::text = p.id
      WHERE 1=1
    `;
    const params: any[] = [];
    let paramIndex = 1;

    if (status) {
      sql += ` AND i.status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }

    if (patientId) {
      sql += ` AND i.patient_id = $${paramIndex}`;
      params.push(patientId);
      paramIndex++;
    }

    sql += ` ORDER BY i.issue_date DESC LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    params.push(limit, offset);

    const invoices = await query(sql, params);

    return NextResponse.json({ invoices: invoices.rows, total: invoices.rows.length });
  } catch (error: any) {
    console.error("Get invoices error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST - Utwórz fakturę
export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || (user.role !== "admin" && user.role !== "superadmin")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const {
      patient_id,
      issue_date,
      due_date,
      total_amount,
      tax_amount,
      status,
      notes,
    } = body;

    if (!patient_id || !due_date || total_amount === undefined) {
      return NextResponse.json(
        { error: "ID pacjenta, data wymagalności i kwota są wymagane" },
        { status: 400 }
      );
    }

    // Verify patient exists
    const patient = await queryOne<{ id: string }>(
      `SELECT id FROM users WHERE id = $1`,
      [patient_id]
    );

    if (!patient) {
      return NextResponse.json({ error: "Pacjent nie został znaleziony" }, { status: 404 });
    }

    const result = await queryOne<{ id: string; invoice_number: string }>(
      `INSERT INTO invoices (
        patient_id, issue_date, due_date, total_amount, tax_amount, status, notes, created_by
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING id, invoice_number`,
      [
        patient_id,
        issue_date || new Date().toISOString().split("T")[0],
        due_date,
        total_amount || 0,
        tax_amount || 0,
        status || "draft",
        notes || null,
        user.id,
      ]
    );

    return NextResponse.json({ success: true, invoice: result });
  } catch (error: any) {
    console.error("Create invoice error:", error);
    if (error.code === "23505") {
      return NextResponse.json({ error: "Faktura z tym numerem już istnieje" }, { status: 409 });
    }
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

