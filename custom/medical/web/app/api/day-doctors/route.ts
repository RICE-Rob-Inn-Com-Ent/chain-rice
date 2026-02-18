import { NextRequest, NextResponse } from "next/server";
import { query, queryMany, queryOne } from "@/lib/db";
import { getCurrentUser } from "@/lib/auth";
import { isAdminOrOwner } from "@/lib/rbac";

// Ensure the day_doctors table exists
async function ensureDayDoctorsTable() {
  await query(`
    CREATE TABLE IF NOT EXISTS day_doctors (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      date DATE NOT NULL,
      dentist_id UUID NOT NULL,
      start_time TIME,
      end_time TIME,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(date, dentist_id)
    );
    CREATE INDEX IF NOT EXISTS idx_day_doctors_date ON day_doctors(date);
    CREATE INDEX IF NOT EXISTS idx_day_doctors_dentist_id ON day_doctors(dentist_id);
  `);
  
  // Add start_time, end_time, and location_id columns if they don't exist (for existing tables)
  await query(`
    DO $$ 
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                     WHERE table_name = 'day_doctors' AND column_name = 'start_time') THEN
        ALTER TABLE day_doctors ADD COLUMN start_time TIME;
      END IF;
      IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                     WHERE table_name = 'day_doctors' AND column_name = 'end_time') THEN
        ALTER TABLE day_doctors ADD COLUMN end_time TIME;
      END IF;
      IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                     WHERE table_name = 'day_doctors' AND column_name = 'location_id') THEN
        ALTER TABLE day_doctors ADD COLUMN location_id UUID REFERENCES clinic_locations(id) ON DELETE SET NULL;
        CREATE INDEX IF NOT EXISTS idx_day_doctors_location ON day_doctors(location_id);
      END IF;
    END $$;
  `);
}

export async function GET(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || !isAdminOrOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const date = searchParams.get("date");

    if (!date) {
      return NextResponse.json({ error: "Missing date parameter" }, { status: 400 });
    }

    await ensureDayDoctorsTable();

    const locationId = searchParams.get("location_id");

    // Only return dentists that are active (both dentist.active and user.active if user_id exists)
    let sql = `SELECT dd.dentist_id::text as dentist_id, dd.start_time, dd.end_time 
       FROM day_doctors dd
       JOIN dentists d ON dd.dentist_id = d.id
       LEFT JOIN users u ON d.user_id = u.id
       WHERE dd.date = $1 
         AND d.active = true
         AND (d.user_id IS NULL OR u.active = true)`;
    
    const params: any[] = [date];
    let paramIndex = 2;

    // Filtruj po lokalizacji jeśli podana
    if (locationId) {
      sql += ` AND (dd.location_id = $${paramIndex} OR dd.location_id IS NULL)`;
      params.push(locationId);
      paramIndex++;
    }

    sql += ` ORDER BY dd.created_at ASC`;

    const result = await queryMany<{ dentist_id: string; start_time: string | null; end_time: string | null }>(
      sql,
      params
    );

    return NextResponse.json({ 
      dentistIds: result.map((row) => row.dentist_id),
      schedules: result.map((row) => ({
        dentist_id: row.dentist_id,
        start_time: row.start_time,
        end_time: row.end_time,
      }))
    });
  } catch (error) {
    console.error("Error fetching day doctors:", error);
    return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || !isAdminOrOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { date, dentistId, startTime, endTime, location_id } = await request.json();

    if (!date || !dentistId) {
      return NextResponse.json({ error: "Missing date or dentistId" }, { status: 400 });
    }

    // Check if dentist exists and is active
    const dentistCheck = await queryOne<{ dentist_active: boolean; user_active: boolean | null; user_id: string | null }>(
      `SELECT d.active as dentist_active, u.active as user_active, d.user_id
       FROM dentists d
       LEFT JOIN users u ON d.user_id = u.id
       WHERE d.id = $1`,
      [dentistId]
    );

    if (!dentistCheck) {
      return NextResponse.json({ error: "Dentysta nie został znaleziony" }, { status: 404 });
    }

    // Check if dentist is active
    if (!dentistCheck.dentist_active) {
      return NextResponse.json({ 
        error: "Nie można dodać nieaktywnego dentysty. Aktywuj dentystę w ustawieniach." 
      }, { status: 400 });
    }

    // If dentist has user_id, check if user is active
    if (dentistCheck.user_id && dentistCheck.user_active === false) {
      return NextResponse.json({ 
        error: "Nie można dodać dentysty z nieaktywnym kontem użytkownika. Najpierw aktywuj konto użytkownika w ustawieniach." 
      }, { status: 400 });
    }

    await ensureDayDoctorsTable();

    // Jeśli istnieje już rekord dla tego dnia i dentysty, zaktualizuj go
    // W przeciwnym razie utwórz nowy z location_id
    await query(
      `INSERT INTO day_doctors (date, dentist_id, start_time, end_time, location_id) 
       VALUES ($1, $2, $3, $4, $5) 
       ON CONFLICT (date, dentist_id) 
       DO UPDATE SET start_time = EXCLUDED.start_time, end_time = EXCLUDED.end_time, location_id = EXCLUDED.location_id`,
      [date, dentistId, startTime || null, endTime || null, location_id || null]
    );

    return NextResponse.json({ message: "Doctor added to day successfully" });
  } catch (error) {
    console.error("Error adding doctor to day:", error);
    return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || !isAdminOrOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const date = searchParams.get("date");
    const dentistId = searchParams.get("dentistId");

    if (!date || !dentistId) {
      return NextResponse.json({ error: "Missing date or dentistId" }, { status: 400 });
    }

    await ensureDayDoctorsTable();

    await query(
      `DELETE FROM day_doctors WHERE date = $1 AND dentist_id = $2`,
      [date, dentistId]
    );

    return NextResponse.json({ message: "Doctor removed from day successfully" });
  } catch (error) {
    console.error("Error removing doctor from day:", error);
    return NextResponse.json({ error: "Internal Server Error" }, { status: 500 });
  }
}

