import { NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { createOAuthAccount, findOAuthAccount, createSession, getSessionCookieMaxAge, generateCSRFToken } from "@/lib/auth";
import { query } from "@/lib/db";
import { setRoleSessionCookie, setCSRFToken } from "@/lib/cookie-utils";
import { getRoleFromId } from "@/lib/user-id-generator";

export const dynamic = 'force-dynamic';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const code = searchParams.get("code");
    const state = searchParams.get("state");
    const error = searchParams.get("error");

    // Get base URL without port (Traefik handles routing on standard ports 80/443)
    let baseUrl = process.env.NEXT_PUBLIC_BASE_URL || "http://ceramix.ltd";
    // Remove port from baseUrl if present (except for localhost in development)
    if (!baseUrl.includes('localhost')) {
      baseUrl = baseUrl.replace(/^(https?:\/\/[^:]+):\d+/, '$1');
    }
    
    if (error) {
      return NextResponse.redirect(`${baseUrl}/sign-in?error=${encodeURIComponent(error)}`);
    }

    if (!code) {
      return NextResponse.redirect(`${baseUrl}/sign-in?error=missing_code`);
    }

    // Parse state to get redirect URI
    let redirectUri = `${baseUrl}/account`;
    if (state) {
      try {
        const stateData = JSON.parse(Buffer.from(state, "base64").toString());
        redirectUri = stateData.redirectUri || `${baseUrl}/account`;
      } catch (e) {
        // Invalid state, use default
      }
    }

    // Exchange code for access token
    const clientId = process.env.GOOGLE_CLIENT_ID;
    const clientSecret = process.env.GOOGLE_CLIENT_SECRET;
    const redirectUrl = `${baseUrl}/api/auth/oauth/google/callback`;

    if (!clientId || !clientSecret) {
      return NextResponse.redirect(`${baseUrl}/sign-in?error=oauth_not_configured`);
    }

    // Exchange authorization code for tokens
    const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        code,
        client_id: clientId,
        client_secret: clientSecret,
        redirect_uri: redirectUrl,
        grant_type: "authorization_code",
      }),
    });

    if (!tokenResponse.ok) {
      const errorData = await tokenResponse.text();
      console.error("Google token exchange error:", errorData);
      return NextResponse.redirect(`${baseUrl}/sign-in?error=token_exchange_failed`);
    }

    const tokens = await tokenResponse.json();
    const accessToken = tokens.access_token;

    // Get user info from Google
    const userInfoResponse = await fetch("https://www.googleapis.com/oauth2/v2/userinfo", {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    });

    if (!userInfoResponse.ok) {
      return NextResponse.redirect(`${baseUrl}/sign-in?error=user_info_failed`);
    }

    const userInfo = await userInfoResponse.json();

    // Find or create user
    let user = await findOAuthAccount("google", userInfo.id);

    if (!user) {
      user = await createOAuthAccount(
        "google",
        userInfo.id,
        userInfo.email,
        userInfo.name || userInfo.email,
        userInfo.picture
      );
    } else {
      // Update OAuth account info
      await query(
        `UPDATE oauth_accounts SET display_name = $1, avatar_url = $2 WHERE provider = 'google' AND provider_id = $3`,
        [userInfo.name || userInfo.email, userInfo.picture, userInfo.id]
      );
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
    const csrfToken = generateCSRFToken();
    await setCSRFToken(csrfToken);
    
    // Always redirect to panel subdomain after OAuth login (standardized)
    const panelDomain = process.env.PROJECT_PANEL_DOMAIN || 'panel.ceramix.ltd';
    const protocol = baseUrl.startsWith('https') ? 'https' : 'http';
    // Fallback to /me if username is missing
    redirectUri = user.username 
      ? `${protocol}://${panelDomain}/${user.username}/dashboard`
      : `${protocol}://${panelDomain}/me`;

    return NextResponse.redirect(redirectUri);
  } catch (error) {
    console.error("Google OAuth callback error:", error);
    // Get base URL without port (Traefik handles routing on standard ports 80/443)
    let baseUrl = process.env.NEXT_PUBLIC_BASE_URL || "http://ceramix.ltd";
    // Remove port from baseUrl if present (except for localhost in development)
    if (!baseUrl.includes('localhost')) {
      baseUrl = baseUrl.replace(/^(https?:\/\/[^:]+):\d+/, '$1');
    }
    return NextResponse.redirect(`${baseUrl}/sign-in?error=oauth_error`);
  }
}

