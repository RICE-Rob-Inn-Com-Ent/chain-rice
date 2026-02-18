import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { query, queryOne } from "@/lib/db";
import { hashPassword } from "@/lib/auth";
import { upsertPatientProfile, PatientProfilePayload } from "@/lib/patient-profiles";
import { generateUserId, getRoleFromId } from "@/lib/user-id-generator";
import { generateUsername } from "@/lib/username-utils";
import { isOwner } from "@/lib/rbac";

// GET - Lista użytkowników (tylko owner)
export async function GET(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || !isOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const search = searchParams.get("search") || "";
    const role = searchParams.get("role");

    let sql = `
      SELECT 
        u.id, u.username, u.email, u.display_name, u.first_name, u.last_name,
        u.avatar_url, u.active, u.email_verified, u.created_at, u.last_login_at
      FROM users u
      WHERE 1=1
    `;
    const params: any[] = [];
    let paramIndex = 1;

    if (search) {
      sql += ` AND (
        u.email ILIKE $${paramIndex} OR 
        u.display_name ILIKE $${paramIndex} OR 
        u.first_name ILIKE $${paramIndex} OR 
        u.last_name ILIKE $${paramIndex}
      )`;
      params.push(`%${search}%`);
      paramIndex++;
    }

    if (role) {
      // Filter by role prefix in ID
      const { getRolePrefix } = await import("@/lib/user-id-generator");
      const rolePrefix = getRolePrefix(role);
      sql += ` AND u.id::text LIKE $${paramIndex}`;
      params.push(`${rolePrefix}-%`);
      paramIndex++;
    }

    sql += ` ORDER BY u.created_at DESC LIMIT 100`;

    const users = await query(sql, params);

    // Add role from ID prefix to each user
    const usersWithRoles = users.rows.map((user: any) => ({
      ...user,
      role: getRoleFromId(user.id) || "user",
    }));

    return NextResponse.json({ users: usersWithRoles });
  } catch (error: any) {
    console.error("Get users error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST - Utwórz użytkownika (tylko owner)
export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || !isOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { email, password, displayName, firstName, lastName, phone, role = "user", patientProfile } = body;

    if (!email || !password || !displayName) {
      return NextResponse.json(
        { error: "Email, hasło i nazwa wyświetlana są wymagane" },
        { status: 400 }
      );
    }

    const passwordHash = await hashPassword(password);
    
    // Generate role-based user ID
    const userId = await generateUserId(role);
    
    // Generate username from email (part before @) or display name
    const username = await generateUsername(email.split('@')[0] || displayName);

    const result = await queryOne<{ id: string }>(
      `INSERT INTO users (id, username, email, password_hash, display_name, first_name, last_name, phone, active, email_verified, account_state)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, false, 'ACTIVE')
       RETURNING id`,
      [userId, username, email.toLowerCase(), passwordHash, displayName, firstName || null, lastName || null, phone || null]
    );

    if (!result) {
      return NextResponse.json({ error: "Failed to create user" }, { status: 500 });
    }

    // Zapisz profil pacjenta jeśli podany
    if (patientProfile) {
      try {
        console.log("Saving patient profile for user:", result.id, "Profile data:", JSON.stringify(patientProfile, null, 2));
        await upsertPatientProfile(result.id, patientProfile as PatientProfilePayload);
        console.log("Patient profile saved successfully");
      } catch (error) {
        console.error("Error saving patient profile:", error);
        // Don't fail the user creation if profile save fails
      }
    }

    // Role is now in ID prefix - no need to insert into user_roles
    // ID was already generated with correct prefix based on role

    return NextResponse.json({ success: true, userId: result.id });
  } catch (error: any) {
    console.error("Create user error:", error);
    if (error.code === "23505") {
      return NextResponse.json({ error: "Użytkownik z tym emailem już istnieje" }, { status: 409 });
    }
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

