import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { query, queryOne } from "@/lib/db";
import { isOwner } from "@/lib/rbac";

// PUT - Aktualizuj lokalizację
export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await getCurrentUser();
    if (!user || !isOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { name, address, city, postal_code, phone, email, active, opening_hours } = body;

    if (!name || name.trim() === "") {
      return NextResponse.json(
        { error: "Nazwa lokalizacji jest wymagana" },
        { status: 400 }
      );
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

    const result = await queryOne(
      `UPDATE clinic_locations
       SET name = $1, address = $2, city = $3, postal_code = $4, phone = $5, email = $6, active = $7, opening_hours = $8, updated_at = CURRENT_TIMESTAMP
       WHERE id = $9 AND owner_id = $10
       RETURNING *`,
      [
        name.trim(),
        address || null,
        city || null,
        postal_code || null,
        phone || null,
        email || null,
        active !== undefined ? active : true,
        opening_hours ? JSON.stringify(opening_hours) : null,
        params.id,
        user.id,
      ]
    );

    if (!result) {
      return NextResponse.json(
        { error: "Lokalizacja nie znaleziona" },
        { status: 404 }
      );
    }

    return NextResponse.json({ success: true, location: result });
  } catch (error: any) {
    console.error("Update location error:", error);
    if (error.code === "23505") {
      return NextResponse.json(
        { error: "Lokalizacja o tej nazwie już istnieje" },
        { status: 409 }
      );
    }
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// DELETE - Usuń lokalizację
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await getCurrentUser();
    if (!user || !isOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    await query(
      `DELETE FROM clinic_locations WHERE id = $1 AND owner_id = $2`,
      [params.id, user.id]
    );

    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error("Delete location error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

