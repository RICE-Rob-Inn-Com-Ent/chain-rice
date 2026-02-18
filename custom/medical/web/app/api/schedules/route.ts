import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { query, queryMany, queryOne } from "@/lib/db";

async function ensureStaffSchedulesTable() {
  await query(`
    CREATE TABLE IF NOT EXISTS staff_schedules (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      staff_type VARCHAR(20) NOT NULL CHECK (staff_type IN ('dentist', 'admin')),
      staff_id VARCHAR(50) NOT NULL,
      day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
      start_time TIME NOT NULL,
      end_time TIME NOT NULL,
      location VARCHAR(100),
      notes TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    CREATE INDEX IF NOT EXISTS idx_staff_schedules_staff_id ON staff_schedules(staff_id);
  `);

  await query(`
    DO $$
    DECLARE
      col_type TEXT;
    BEGIN
      SELECT data_type INTO col_type
      FROM information_schema.columns
      WHERE table_name = 'staff_schedules' AND column_name = 'staff_id';

      IF col_type = 'uuid' THEN
        EXECUTE 'ALTER TABLE staff_schedules ALTER COLUMN staff_id TYPE VARCHAR(50) USING staff_id::text';
      END IF;
    END $$;
  `);
}

async function resolveDentistId(staffId: string): Promise<string | null> {
  const foundById = await queryOne<{ id: string }>(
    `SELECT id FROM dentists WHERE id = $1 LIMIT 1`,
    [staffId]
  );
  if (foundById?.id) {
    return foundById.id;
  }

  const foundByUser = await queryOne<{ id: string }>(
    `SELECT id FROM dentists WHERE user_id = $1 LIMIT 1`,
    [staffId]
  );
  if (foundByUser?.id) {
    return foundByUser.id;
  }

  const fallback = await queryOne<{
    id: string;
    first_name: string | null;
    last_name: string | null;
    email: string | null;
    phone: string | null;
  }>(
    `SELECT u.id,
            u.first_name,
            u.last_name,
            u.email,
            u.phone
     FROM users u
    WHERE u.id::text = $1 AND u.id::text LIKE 'DOC-%'
     LIMIT 1`,
    [staffId]
  );

  if (!fallback?.id) {
    return null;
  }

  const licenseNumber = `AUTO-${fallback.id.replace(/-/g, "").slice(0, 8).toUpperCase()}`;

  const created = await queryOne<{ id: string }>(
    `INSERT INTO dentists (
        id,
        license_number,
        user_id,
        first_name,
        last_name,
        email,
        phone,
        specialization,
        clinic_location,
        bio,
        active
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, ARRAY['stomatologia zachowawcza'], 'ceramix', 'Profil utworzony automatycznie', true)
      ON CONFLICT (id) DO UPDATE SET
        license_number = EXCLUDED.license_number,
        user_id = EXCLUDED.user_id,
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        email = EXCLUDED.email,
        phone = EXCLUDED.phone,
        specialization = EXCLUDED.specialization,
        clinic_location = EXCLUDED.clinic_location,
        bio = EXCLUDED.bio,
        active = true
      RETURNING id`,
    [
      fallback.id,
      licenseNumber,
      fallback.id,
      fallback.first_name || "Dentysta",
      fallback.last_name || "",
      fallback.email,
      fallback.phone,
    ]
  );

  return created?.id ?? null;
}

export async function GET() {
  await ensureStaffSchedulesTable();
  const schedules = await queryMany(
    `SELECT 
      ss.id,
      ss.staff_type,
      ss.staff_id,
      ss.day_of_week,
      ss.start_time,
      ss.end_time,
      ss.location,
      ss.notes,
      CASE WHEN ss.staff_type = 'dentist'
        THEN CONCAT(d.first_name, ' ', d.last_name)
        ELSE u.display_name
      END AS staff_name
     FROM staff_schedules ss
     LEFT JOIN dentists d ON (d.id::text = ss.staff_id OR d.user_id = ss.staff_id) AND ss.staff_type = 'dentist'
     LEFT JOIN users u ON u.id = ss.staff_id AND ss.staff_type = 'admin'
     ORDER BY ss.day_of_week, ss.start_time`
  );
  return NextResponse.json({ schedules });
}

export async function POST(request: NextRequest) {
  const user = await getCurrentUser();
  if (!user || (user.role !== "admin" && user.role !== "owner")) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const { staff_type, staff_id, day_of_week, start_time, end_time, location, notes } = body;

  if (!staff_type || !staff_id || day_of_week === undefined || !start_time || !end_time) {
    return NextResponse.json({ error: "Brakuje wymaganych pól" }, { status: 400 });
  }

  if (staff_type !== "dentist" && staff_type !== "admin") {
    return NextResponse.json({ error: "Nieprawidłowy typ personelu" }, { status: 400 });
  }

  await ensureStaffSchedulesTable();

  let resolvedStaffId = staff_id;

  if (staff_type === "dentist") {
    const dentistId = await resolveDentistId(staff_id);
    if (!dentistId) {
      return NextResponse.json({ error: "Nie znaleziono dentysty" }, { status: 400 });
    }
    resolvedStaffId = dentistId;
  } else {
    const adminUser = await queryOne(
      `SELECT u.id
       FROM users u
      WHERE u.id::text = $1 AND (u.id::text LIKE 'ADM-%' OR u.id::text LIKE 'SUP-%')
       LIMIT 1`,
      [staff_id]
    );
    if (!adminUser) {
      return NextResponse.json({ error: "Nie znaleziono administratora" }, { status: 400 });
    }
  }

  const schedule = await queryOne(
    `INSERT INTO staff_schedules (
      staff_type,
      staff_id,
      day_of_week,
      start_time,
      end_time,
      location,
      notes
    ) VALUES ($1, $2, $3, $4, $5, $6, $7)
    RETURNING *`,
    [staff_type, resolvedStaffId, day_of_week, start_time, end_time, location || null, notes || null]
  );

  return NextResponse.json({ schedule }, { status: 201 });
}

