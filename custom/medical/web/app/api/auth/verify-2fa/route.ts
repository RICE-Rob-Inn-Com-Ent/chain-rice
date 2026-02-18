import { NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { query, queryOne } from "@/lib/db";
import { createSession, verify2FAToken, verifyBackupCode, getSessionCookieMaxAge, generateCSRFToken } from "@/lib/auth";
import { setRoleSessionCookie, setCSRFToken } from "@/lib/cookie-utils";
import { getRoleFromId } from "@/lib/user-id-generator";

export async function POST(request: NextRequest) {
  try {
    const { email, code, isBackupCode } = await request.json();

    if (!email || !code) {
      return NextResponse.json({ error: "Email i kod są wymagane" }, { status: 400 });
    }

    // Get temp token
    const cookieStore = await cookies();
    const tempToken = cookieStore.get("ceramix_2fa_temp")?.value;

    if (!tempToken) {
      return NextResponse.json({ error: "Sesja wygasła. Zaloguj się ponownie." }, { status: 401 });
    }

    // Decode temp token to get user ID
    const decoded = Buffer.from(tempToken, "base64").toString("utf-8");
    const [userId] = decoded.split(":");

    // Verify user
    const user = await queryOne<{
      id: string;
      email: string;
      role: string;
      active: boolean;
      two_factor_enabled: boolean;
      two_factor_secret: string;
    }>(
      `SELECT id, email, role, active, two_factor_enabled, two_factor_secret 
       FROM users 
       WHERE id = $1 AND email = $2 AND active = true`,
      [userId, email.toLowerCase()]
    );

    if (!user || !user.two_factor_enabled) {
      return NextResponse.json({ error: "Nieprawidłowy użytkownik" }, { status: 401 });
    }

    // Verify 2FA code
    let isValid = false;
    if (isBackupCode) {
      isValid = await verifyBackupCode(user.id, code);
    } else {
      isValid = await verify2FAToken(user.id, code);
    }

    if (!isValid) {
      return NextResponse.json({ error: "Nieprawidłowy kod weryfikacyjny" }, { status: 401 });
    }

    // Create session
    const sessionToken = await createSession(user.id);

    // Update last login
    await query(
      `UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1`,
      [user.id]
    );

    // Delete temp token
    cookieStore.delete("ceramix_2fa_temp");

    // Redirect based on username (not role prefix)
    const role = getRoleFromId(user.id) || "user";
    
    // Set role-based session cookie
    await setRoleSessionCookie(role, sessionToken, getSessionCookieMaxAge());
    const csrfToken = generateCSRFToken();
    await setCSRFToken(csrfToken);
    
    // Use username for routing (e.g., /username/dashboard)
    // Fallback to /me if username is missing
    const redirect = user.username ? `/${user.username}/dashboard` : '/me';

    // After 2FA verification, always redirect to panel subdomain (standardized)
    const panelDomain = process.env.PROJECT_PANEL_DOMAIN || 'panel.ceramix.ltd';
    
    return NextResponse.json({ 
      success: true, 
      redirect,
      usePanelDomain: true,
      panelDomain
    });
  } catch (error) {
    console.error("2FA verification error:", error);
    return NextResponse.json({ error: "Wystąpił błąd podczas weryfikacji" }, { status: 500 });
  }
}

