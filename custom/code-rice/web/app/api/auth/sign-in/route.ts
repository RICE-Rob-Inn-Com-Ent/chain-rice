import { cookies } from "next/headers";
import { NextRequest, NextResponse } from "next/server";
import { query, queryOne } from "@/lib/db";
import { attachSessionCookie, verifyPassword, getRoleBasedRedirectPath } from "@/lib/auth";
import { getRoleFromId } from "@/lib/user-id-generator";

async function fetchUserRole(userId: string): Promise<string> {
  const inferred = getRoleFromId(userId);
  if (inferred) {
    return inferred;
  }

  const row = await queryOne<{ role: string }>(
    `SELECT role FROM user_roles WHERE user_id::text = $1 ORDER BY granted_at DESC LIMIT 1`,
    [userId],
  );

  return row?.role || "user";
}

export async function POST(request: NextRequest) {
  try {
    const { email, password } = await request.json();

    if (!email || !password) {
      return NextResponse.json({ error: "Email i hasło są wymagane" }, { status: 400 });
    }

    const user = await queryOne<{
      id: string;
      email: string;
      password_hash: string | null;
      active: boolean;
      two_factor_enabled: boolean;
    }>(
      `SELECT 
        u.id,
        u.email,
        u.password_hash,
        u.active,
        COALESCE(u.two_factor_enabled, false) AS two_factor_enabled
       FROM users u
       WHERE LOWER(u.email) = $1`,
      [email.toLowerCase()],
    );

    // Enhanced logging for debugging
    if (!user) {
      console.error(`[code-rice][auth] User not found: ${email.toLowerCase()}`);
      return NextResponse.json({ error: "Nieprawidłowy email lub hasło" }, { status: 401 });
    }

    if (!user.active) {
      console.error(`[code-rice][auth] User inactive: ${user.email} (${user.id})`);
      return NextResponse.json({ error: "Nieprawidłowy email lub hasło" }, { status: 401 });
    }

    if (!user.password_hash) {
      console.error(`[code-rice][auth] User has no password hash: ${user.email} (${user.id})`);
      return NextResponse.json({ error: "Nieprawidłowy email lub hasło" }, { status: 401 });
    }

    const isValid = await verifyPassword(password, user.password_hash);
    if (!isValid) {
      console.error(`[code-rice][auth] Invalid password for user: ${user.email} (${user.id})`);
      return NextResponse.json({ error: "Nieprawidłowy email lub hasło" }, { status: 401 });
    }

    console.log(`[code-rice][auth] Successful login: ${user.email} (${user.id})`);

    // Placeholder for 2FA support – currently disabled
    if (user.two_factor_enabled) {
      const tempToken = Buffer.from(`${user.id}:${Date.now()}`).toString("base64");
      const cookieStore = await cookies();
      cookieStore.set("code_rice_2fa_temp", tempToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === "production",
        sameSite: "lax",
        maxAge: 300,
      });

      return NextResponse.json({
        requires2FA: true,
        message: "Weryfikacja dwuetapowa jest tymczasowo niedostępna",
      });
    }

    await attachSessionCookie(user.id);

    await query(
      `UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id::text = $1`,
      [user.id],
    );

    const role = await fetchUserRole(user.id);
    let redirect = await getRoleBasedRedirectPath(user.id);

    // FORCE owners/admins to /admin/dashboard - ignore getRoleBasedRedirectPath result
    const roleLower = (role || "").toLowerCase();
    const isOwner = roleLower === "owner" || user.id.startsWith("OWN-");
    const isAdmin = roleLower === "admin" || roleLower === "superadmin" || user.id.startsWith("ADM-");
    
    if (isOwner || isAdmin) {
      redirect = "/admin/dashboard";
      console.log(`[code-rice][auth] ⚡ FORCING owner/admin redirect to /admin/dashboard`);
    }

    console.log(`[code-rice][auth] ===== LOGIN RESPONSE =====`);
    console.log(`[code-rice][auth] User: ${user.email} (${user.id})`);
    console.log(`[code-rice][auth] Role: ${role} (lower: ${roleLower})`);
    console.log(`[code-rice][auth] IsOwner: ${isOwner}, IsAdmin: ${isAdmin}`);
    console.log(`[code-rice][auth] Final redirect: ${redirect}`);
    console.log(`[code-rice][auth] =========================`);

    return NextResponse.json({ 
      success: true, 
      redirect, 
      role,
      userId: user.id, // Include user ID so client can check format
      email: user.email
    });
  } catch (error) {
    console.error("[code-rice][auth] login error", error);
    return NextResponse.json(
      { error: "Wystąpił błąd podczas logowania" },
      { status: 500 },
    );
  }
}


