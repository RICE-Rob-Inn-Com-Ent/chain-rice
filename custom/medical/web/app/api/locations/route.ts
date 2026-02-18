import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { query, queryMany, queryOne } from "@/lib/db";
import { isOwner } from "@/lib/rbac";

type ClinicLocation = {
  id: string;
  owner_id: string;
  name: string;
  address: string | null;
  city: string | null;
  postal_code: string | null;
  phone: string | null;
  email: string | null;
  active: boolean;
  opening_hours: any | null;
  created_at: string;
  updated_at: string;
};

// GET - Lista lokalizacji dla zalogowanego ownera
export async function GET(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || !isOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Ensure opening_hours column exists
    await query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name = 'clinic_locations' AND column_name = 'opening_hours'
        ) THEN
          ALTER TABLE clinic_locations 
          ADD COLUMN opening_hours JSONB;
        END IF;
      END $$;
    `);

    const locations = await queryMany<ClinicLocation>(
      `SELECT id, owner_id, name, address, city, postal_code, phone, email, active, opening_hours, created_at, updated_at
       FROM clinic_locations
       WHERE owner_id = $1
       ORDER BY name ASC`,
      [user.id]
    );

    return NextResponse.json({ locations });
  } catch (error: any) {
    console.error("Get locations error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST - Utwórz nową lokalizację
export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || !isOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { name, address, city, postal_code, phone, email, opening_hours } = body;

    if (!name || name.trim() === "") {
      return NextResponse.json(
        { error: "Nazwa lokalizacji jest wymagana" },
        { status: 400 }
      );
    }

    // Ensure table exists
    await query(`
      CREATE TABLE IF NOT EXISTS clinic_locations (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        owner_id VARCHAR(50) NOT NULL,
        name VARCHAR(100) NOT NULL,
        address TEXT,
        city VARCHAR(100),
        postal_code VARCHAR(20),
        phone VARCHAR(20),
        email VARCHAR(255),
        active BOOLEAN DEFAULT true,
        opening_hours JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(owner_id, name)
      );
      CREATE INDEX IF NOT EXISTS idx_clinic_locations_owner_id ON clinic_locations(owner_id);
    `);

    // Ensure opening_hours column exists for existing tables
    await query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name = 'clinic_locations' AND column_name = 'opening_hours'
        ) THEN
          ALTER TABLE clinic_locations 
          ADD COLUMN opening_hours JSONB;
        END IF;
      END $$;
    `);

    const result = await queryOne<ClinicLocation>(
      `INSERT INTO clinic_locations (owner_id, name, address, city, postal_code, phone, email, opening_hours)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [
        user.id,
        name.trim(),
        address || null,
        city || null,
        postal_code || null,
        phone || null,
        email || null,
        opening_hours ? JSON.stringify(opening_hours) : null,
      ]
    );

    return NextResponse.json({ success: true, location: result });
  } catch (error: any) {
    console.error("Create location error:", error);
    if (error.code === "23505") {
      return NextResponse.json(
        { error: "Lokalizacja o tej nazwie już istnieje" },
        { status: 409 }
      );
    }
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

