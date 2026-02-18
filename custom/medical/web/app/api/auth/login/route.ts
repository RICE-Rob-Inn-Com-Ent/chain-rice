import { NextRequest, NextResponse } from "next/server";
import { query, queryOne } from "@/lib/db";
import { verifyPassword, createSession, getSessionCookieMaxAge, generateCSRFToken } from "@/lib/auth";
import { getRoleFromId } from "@/lib/user-id-generator";
import { setRoleSessionCookie, setCSRFToken } from "@/lib/cookie-utils";

export async function POST(request: NextRequest) {
  try {
    // Log request for debugging
    console.log("Login attempt", {
      url: request.url,
      hasBody: !!request.body,
      env: {
        hasDbUrl: !!process.env.DATABASE_URL,
        nodeEnv: process.env.NODE_ENV,
      },
    });

    const { email, password } = await request.json();

    if (!email || !password) {
      return NextResponse.json({ error: "Email i hasło są wymagane" }, { status: 400 });
    }

    // Find user
    const user = await queryOne<{
      id: string;
      email: string;
      username: string | null;
      password_hash: string | null;
      active: boolean;
      two_factor_enabled: boolean;
    }>(
      `SELECT 
        u.id, u.email, u.username, u.password_hash, u.active, 
        COALESCE(u.two_factor_enabled, false) as two_factor_enabled
       FROM users u
       WHERE LOWER(u.email) = $1`,
      [email.toLowerCase()]
    );
    
    // Enhanced logging for debugging
    if (!user) {
      console.error(`[ceramix][auth] User not found: ${email.toLowerCase()}`);
      return NextResponse.json({ error: "Nieprawidłowy email lub hasło" }, { status: 401 });
    }

    if (!user.active) {
      console.error(`[ceramix][auth] User inactive: ${user.email} (${user.id})`);
      return NextResponse.json({ error: "Nieprawidłowy email lub hasło" }, { status: 401 });
    }

    // Check if user has password (not OAuth-only account)
    if (!user.password_hash) {
      console.error(`[ceramix][auth] User has no password hash: ${user.email} (${user.id})`);
      return NextResponse.json(
        { error: "To konto używa logowania OAuth. Zaloguj się przez Google lub GitHub." },
        { status: 401 }
      );
    }

    // Verify password
    const isValid = await verifyPassword(password, user.password_hash);
    if (!isValid) {
      console.error(`[ceramix][auth] Invalid password for user: ${user.email} (${user.id})`);
      return NextResponse.json({ error: "Nieprawidłowy email lub hasło" }, { status: 401 });
    }

    console.log(`[ceramix][auth] Successful login: ${user.email} (${user.id})`);

    // Check if 2FA is enabled
    if (user.two_factor_enabled) {
      // Store temporary session for 2FA verification
      const tempToken = Buffer.from(`${user.id}:${Date.now()}`).toString("base64");
      const cookieStore = await cookies();
      const isProduction = process.env.NODE_ENV === "production";
      cookieStore.set("ceramix_2fa_temp", tempToken, {
        httpOnly: true,
        secure: isProduction,
        sameSite: "lax",
        path: "/",
        domain: isProduction ? ".ceramix.ltd" : undefined,
        maxAge: 300, // 5 minutes
      });

      return NextResponse.json({
        requires2FA: true,
        message: "Wymagana weryfikacja dwuetapowa",
      });
    }

    // Create session
    const sessionToken = await createSession(user.id);

    // Update last login
    await query(
      `UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1`,
      [user.id]
    );

    // Redirect based on username (not role prefix)
    const role = getRoleFromId(user.id) || "user";
    
    // Set role-based session cookie
    await setRoleSessionCookie(role, sessionToken, getSessionCookieMaxAge());
    
    // Generate and set CSRF token
    const csrfToken = generateCSRFToken();
    await setCSRFToken(csrfToken);
    
    // Use username for routing (e.g., /username/dashboard)
    // Fallback to /me if username is missing
    const redirect = user.username ? `/${user.username}/dashboard` : '/me';

    // After login, always redirect to panel subdomain (standardized)
    const panelDomain = process.env.PROJECT_PANEL_DOMAIN || 'panel.ceramix.ltd';
    
    return NextResponse.json({ 
      success: true, 
      redirect,
      usePanelDomain: true,
      panelDomain
    });
  } catch (error: any) {
    console.error("Login error:", error);
    console.error("Error details:", {
      message: error?.message,
      code: error?.code,
      stack: error?.stack,
    });
    
    // Provide more detailed error messages
    let errorMessage = "Wystąpił błąd podczas logowania";
    
    if (error?.code === "ECONNREFUSED" || error?.message?.includes("connect")) {
      errorMessage = "Nie można połączyć się z bazą danych. Sprawdź konfigurację DATABASE_URL.";
    } else if (error?.code === "42P01") {
      errorMessage = "Tabela nie istnieje. Uruchom migracje bazy danych.";
    } else if (error?.message) {
      errorMessage = `Błąd: ${error.message}`;
    }
    
    return NextResponse.json(
      { 
        error: errorMessage,
        details: process.env.NODE_ENV === "development" ? error?.message : undefined 
      },
      { status: 500 }
    );
  }
}

