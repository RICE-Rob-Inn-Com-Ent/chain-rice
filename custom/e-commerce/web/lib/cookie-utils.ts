import { cookies } from "next/headers";

/**
 * Cookie configuration helper
 * Ensures consistent cookie settings across the application
 */
export interface CookieOptions {
  httpOnly?: boolean;
  secure?: boolean;
  sameSite?: "strict" | "lax" | "none";
  maxAge?: number;
  path?: string;
  domain?: string;
}

export function getCookieDomain(): string | undefined {
  // Set domain with leading dot to allow cookie sharing between base and panel subdomains
  // e.g., .meowtopia.ltd works for both meowtopia.ltd and panel.meowtopia.ltd
  const projectDomain = process.env.PROJECT_DOMAIN || 'meowtopia.ltd';
  
  // For localhost, don't set domain (browser handles it)
  if (projectDomain.includes('localhost')) {
    return undefined;
  }
  
  // For production domains, use .domain.ltd format for subdomain sharing
  return `.${projectDomain}`;
}

export function getDefaultCookieOptions(): CookieOptions {
  // In development, use lax security
  // In production with HTTPS, use secure
  const isProduction = process.env.NODE_ENV === "production";
  const isSecure = process.env.NEXT_PUBLIC_USE_HTTPS === "true" || isProduction;
  
  return {
    httpOnly: true,
    secure: isSecure,
    sameSite: "lax",
    path: "/",
    // Set domain with leading dot for subdomain sharing
    // This ensures cookies work on both meowtopia.ltd and panel.meowtopia.ltd
    domain: getCookieDomain(),
  };
}

/**
 * Get role-based session cookie name
 * Mapping:
 * - OWNER → own
 * - VOLUNTEER → vol
 * - MANAGER → man_session
 * - ADMIN → adm_session
 * - USER → user_session
 */
export function getRoleSessionCookieName(role: string): string {
  const roleMap: Record<string, string> = {
    owner: 'own',
    volunteer: 'vol',
    manager: 'man_session',
    admin: 'adm_session',
    user: 'user_session',
    customer: 'cus-session', // CUSTOMER uses cus-session
    superadmin: 'adm_session', // SUPERADMIN uses admin session
  };
  
  const normalizedRole = role.toLowerCase();
  return roleMap[normalizedRole] || 'user_session';
}

/**
 * Get all possible role session cookie names (for checking/migration)
 */
export function getAllRoleSessionCookieNames(): string[] {
  return ['own', 'vol', 'man_session', 'adm_session', 'user_session'];
}

/**
 * Get session cookie max age in seconds
 * Default: 30 days
 */
export function getSessionCookieMaxAge(): number {
  return 60 * 60 * 24 * 30; // 30 days
}

/**
 * Set role-based session cookie
 * @param role - User role (owner, volunteer, manager, admin, user, etc.)
 * @param sessionToken - Session token
 * @param maxAge - Cookie max age in seconds
 */
export async function setRoleSessionCookie(role: string, sessionToken: string, maxAge: number) {
  const cookieStore = await cookies();
  const cookieName = getRoleSessionCookieName(role);
  const cookieOptions = getDefaultCookieOptions();
  
  console.log(`[setRoleSessionCookie] Setting ${cookieName} for role ${role}, domain: ${cookieOptions.domain}, maxAge: ${maxAge}`);
  
  // Delete old next-auth.session-token cookie if exists (migration)
  cookieStore.delete('next-auth.session-token');
  
  // Delete all other role sessions (user can only have one active session)
  const allRoleCookies = getAllRoleSessionCookieNames();
  for (const cookieNameToDelete of allRoleCookies) {
    if (cookieNameToDelete !== cookieName) {
      cookieStore.delete(cookieNameToDelete);
    }
  }
  
  // Set new role-based session cookie
  cookieStore.set(cookieName, sessionToken, {
    ...cookieOptions,
    maxAge,
  });
  
  console.log(`[setRoleSessionCookie] Cookie ${cookieName} set successfully`);
}

/**
 * Set CSRF token cookie
 * @param token - CSRF token
 */
export async function setCSRFToken(token: string) {
  const cookieStore = await cookies();
  const cookieOptions = getDefaultCookieOptions();
  
  // Delete old CSRF token from any domain first
  const allCookies = await cookies();
  try {
    allCookies.delete("meowtopia-csrf");
    allCookies.delete("next-auth.csrf-token");
  } catch (e) {
    // Ignore if cookie doesn't exist
  }
  
  cookieStore.set("meowtopia-csrf", token, {
    ...cookieOptions,
    httpOnly: false, // CSRF token must be readable by JavaScript
    maxAge: 60 * 60 * 24, // 24 hours
    domain: cookieOptions.domain, // Use same domain as session cookies (.meowtopia.ltd)
  });
  
  console.log(`[setCSRFToken] CSRF token set with domain: ${cookieOptions.domain}`);
}

/**
 * Get CSRF token from cookie
 */
export async function getCSRFToken(): Promise<string | undefined> {
  const cookieStore = await cookies();
  return cookieStore.get("meowtopia-csrf")?.value;
}

/**
 * Get session cookie from any role (for backward compatibility and checking)
 * Returns the first found role session cookie
 */
export async function getAnyRoleSessionCookie(): Promise<{ cookieName: string; token: string; role: string } | null> {
  const cookieStore = await cookies();
  
  // Check all role-based cookies
  const roleMap: Record<string, string> = {
    'own': 'owner',
    'vol': 'volunteer',
    'man_session': 'manager',
    'adm_session': 'admin',
    'user_session': 'user',
  };
  
  for (const [cookieName, role] of Object.entries(roleMap)) {
    const cookie = cookieStore.get(cookieName);
    if (cookie?.value) {
      return { cookieName, token: cookie.value, role };
    }
  }
  
  // Fallback: check legacy next-auth.session-token (migration)
  const legacyCookie = cookieStore.get('next-auth.session-token');
  if (legacyCookie?.value) {
    return { cookieName: 'next-auth.session-token', token: legacyCookie.value, role: 'user' };
  }
  
  return null;
}

/**
 * Delete all session cookies (for logout)
 */
export async function deleteAllSessionCookies() {
  const cookieStore = await cookies();
  
  // Delete all role-based cookies
  getAllRoleSessionCookieNames().forEach(cookieName => {
    cookieStore.delete(cookieName);
  });
  
  // Delete legacy cookie
  cookieStore.delete('next-auth.session-token');
  
  // Delete CSRF token
  cookieStore.delete('meowtopia-csrf');
}

