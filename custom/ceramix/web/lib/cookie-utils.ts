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
  // e.g., .ceramix.ltd works for both ceramix.ltd and panel.ceramix.ltd
  const projectDomain = process.env.PROJECT_DOMAIN || 'ceramix.ltd';
  
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
    // This ensures cookies work on both ceramix.ltd and panel.ceramix.ltd
    domain: getCookieDomain(),
  };
}

/**
 * Get role-based session cookie name
 * e.g., "owner_session", "doctor_session", "patient_session"
 */
export function getRoleSessionCookieName(role: string): string {
  const roleMap: Record<string, string> = {
    owner: 'owner_session',
    doctor: 'doctor_session',
    admin: 'admin_session',
    patient: 'patient_session',
    superadmin: 'admin_session', // legacy -> admin
    user: 'patient_session', // fallback -> patient
  };
  
  const normalizedRole = role.toLowerCase();
  return roleMap[normalizedRole] || 'patient_session';
}

/**
 * Get all possible role session cookie names (for checking/migration)
 */
export function getAllRoleSessionCookieNames(): string[] {
  return ['owner_session', 'doctor_session', 'admin_session', 'patient_session'];
}

/**
 * Set role-based session cookie
 * @param role - User role (owner, doctor, admin, patient, etc.)
 * @param sessionToken - Session token
 * @param maxAge - Cookie max age in seconds
 */
export async function setRoleSessionCookie(role: string, sessionToken: string, maxAge: number) {
  const cookieStore = await cookies();
  const cookieName = getRoleSessionCookieName(role);
  const cookieOptions = getDefaultCookieOptions();
  
  console.log(`[setRoleSessionCookie] Setting ${cookieName} for role ${role}, domain: ${cookieOptions.domain}, maxAge: ${maxAge}`);
  
  // Delete old ceramix_session cookie if exists (migration)
  cookieStore.delete('ceramix_session');
  
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
 * Legacy function - now uses role-based cookies
 * @deprecated Use setRoleSessionCookie instead
 */
export async function setSessionCookie(sessionToken: string, maxAge: number) {
  // This should not be called directly anymore
  // But keeping for backward compatibility during migration
  console.warn('setSessionCookie is deprecated. Use setRoleSessionCookie instead.');
  // Default to patient_session for legacy calls
  await setRoleSessionCookie('patient', sessionToken, maxAge);
}

export async function setCSRFToken(token: string) {
  const cookieStore = await cookies();
  const cookieOptions = getDefaultCookieOptions();
  
  // Delete old CSRF token from any domain first
  const allCookies = await cookies();
  try {
    allCookies.delete("ceramix_csrf");
  } catch (e) {
    // Ignore if cookie doesn't exist
  }
  
  cookieStore.set("ceramix_csrf", token, {
    ...cookieOptions,
    httpOnly: false, // CSRF token must be readable by JavaScript
    maxAge: 60 * 60 * 24, // 24 hours
    domain: cookieOptions.domain, // Use same domain as session cookies (.ceramix.ltd)
  });
  
  console.log(`[setCSRFToken] CSRF token set with domain: ${cookieOptions.domain}`);
}

export async function getCSRFToken(): Promise<string | undefined> {
  const cookieStore = await cookies();
  return cookieStore.get("ceramix_csrf")?.value;
}

/**
 * Get session cookie from any role (for backward compatibility and checking)
 * Returns the first found role session cookie
 */
export async function getAnyRoleSessionCookie(): Promise<{ cookieName: string; token: string; role: string } | null> {
  const cookieStore = await cookies();
  
  // Check all role-based cookies
  const roleMap: Record<string, string> = {
    'owner_session': 'owner',
    'doctor_session': 'doctor',
    'admin_session': 'admin',
    'patient_session': 'patient',
  };
  
  for (const [cookieName, role] of Object.entries(roleMap)) {
    const cookie = cookieStore.get(cookieName);
    if (cookie?.value) {
      return { cookieName, token: cookie.value, role };
    }
  }
  
  // Fallback: check legacy ceramix_session (migration)
  const legacyCookie = cookieStore.get('ceramix_session');
  if (legacyCookie?.value) {
    return { cookieName: 'ceramix_session', token: legacyCookie.value, role: 'patient' };
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
  cookieStore.delete('ceramix_session');
}

