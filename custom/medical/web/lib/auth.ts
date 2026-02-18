import { cookies } from "next/headers";
import bcrypt from "bcryptjs";
import { query, queryOne } from "./db";
import crypto from "crypto";
import { getRoleFromId, getRolePrefix } from "./user-id-generator";

// Session management
const SESSION_SECRET = process.env.SESSION_SECRET || "ceramix-session-secret-change-in-production";

// CSRF token generation
export function generateCSRFToken(): string {
  return crypto.randomBytes(32).toString("hex");
}

// Calculate time until end of day (midnight)
function getEndOfDay(): Date {
  const now = new Date();
  const endOfDay = new Date(now);
  endOfDay.setHours(23, 59, 59, 999); // Set to 23:59:59.999
  return endOfDay;
}

// Calculate maxAge in seconds until end of day (for cookies)
export function getSessionCookieMaxAge(): number {
  const now = new Date();
  const endOfDay = new Date(now);
  endOfDay.setHours(23, 59, 59, 999);
  const secondsUntilMidnight = Math.floor((endOfDay.getTime() - now.getTime()) / 1000);
  return Math.max(secondsUntilMidnight, 60); // At least 1 minute
}

export interface User {
  id: string;
  username: string;
  email: string;
  display_name: string;
  first_name?: string;
  last_name?: string;
  avatar_url?: string;
  role: string;
  active: boolean;
  email_verified: boolean;
  created_at: Date;
  last_login_at?: Date;
}

// Password hashing
export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12);
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

// Session management
export async function createSession(userId: string): Promise<string> {
  const sessionToken = crypto.randomBytes(32).toString("hex");
  const expiresAt = getEndOfDay(); // Session expires at end of day

  await query(
    `INSERT INTO sessions (user_id, session_token, refresh_token, session_type, expires_at, created_at, last_activity)
     VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
     ON CONFLICT (session_token) DO UPDATE SET expires_at = $5, last_activity = CURRENT_TIMESTAMP`,
    [
      userId,
      sessionToken,
      crypto.randomBytes(32).toString("hex"), // refresh token
      "web",
      expiresAt,
    ]
  );

  return sessionToken;
}

export async function getSession(sessionToken: string): Promise<{ userId: string; expiresAt: Date } | null> {
  const session = await queryOne<{
    user_id: string;
    expires_at: Date;
    revoked: boolean;
  }>(
    `SELECT user_id, expires_at, revoked 
     FROM sessions 
     WHERE session_token = $1 AND revoked = false AND expires_at > CURRENT_TIMESTAMP`,
    [sessionToken]
  );

  if (!session) {
    return null;
  }

  // Update last activity
  await query(
    `UPDATE sessions SET last_activity = CURRENT_TIMESTAMP WHERE session_token = $1`,
    [sessionToken]
  );

  return {
    userId: session.user_id,
    expiresAt: session.expires_at,
  };
}

export async function deleteSession(sessionToken: string): Promise<void> {
  await query(
    `UPDATE sessions SET revoked = true WHERE session_token = $1`,
    [sessionToken]
  );
}

// 2FA functions
export async function verify2FAToken(userId: string, token: string): Promise<boolean> {
  // This would integrate with otplib - simplified for now
  const user = await queryOne<{ two_factor_secret: string }>(
    `SELECT two_factor_secret FROM users WHERE id = $1`,
    [userId]
  );

  if (!user || !user.two_factor_secret) {
    return false;
  }

  // TODO: Implement TOTP verification with otplib
  // For now, return false
  return false;
}

export async function verifyBackupCode(userId: string, code: string): Promise<boolean> {
  const result = await queryOne<{ id: string }>(
    `SELECT id FROM mfa_backup_codes 
     WHERE user_id = $1 AND code = $2 AND used = false`,
    [userId, code]
  );

  if (result) {
    await query(
      `UPDATE mfa_backup_codes SET used = true WHERE user_id = $1 AND code = $2`,
      [userId, code]
    );
    return true;
  }

  return false;
}

// Get current user from session (using role-based cookies)
export async function getCurrentUser(): Promise<User | null> {
  const cookieStore = await cookies();
  
  // Check all role-based session cookies
  const roleCookieMap: Record<string, string> = {
    'owner_session': 'owner',
    'doctor_session': 'doctor',
    'admin_session': 'admin',
    'patient_session': 'patient',
  };
  
  let sessionToken: string | undefined;
  let foundCookieName: string | undefined;
  
  // Try role-based cookies first
  for (const [cookieName] of Object.entries(roleCookieMap)) {
    const cookie = cookieStore.get(cookieName);
    if (cookie?.value) {
      sessionToken = cookie.value;
      foundCookieName = cookieName;
      console.log(`[getCurrentUser] Found ${cookieName} cookie`);
      break;
    }
  }
  
  // Fallback: legacy ceramix_session (migration)
  if (!sessionToken) {
    const legacyCookie = cookieStore.get("ceramix_session");
    if (legacyCookie?.value) {
      sessionToken = legacyCookie.value;
      foundCookieName = 'ceramix_session';
      console.log(`[getCurrentUser] Found legacy ceramix_session cookie`);
    }
  }

  if (!sessionToken) {
    console.log(`[getCurrentUser] No session token found`);
    return null;
  }
  
  console.log(`[getCurrentUser] Using cookie: ${foundCookieName}, token: ${sessionToken.substring(0, 20)}...`);

  const session = await getSession(sessionToken);
  if (!session) {
    return null;
  }

  const user = await queryOne<User>(
    `SELECT 
      u.id, u.username, u.email, u.display_name, u.first_name, u.last_name, 
      u.avatar_url, u.active, u.email_verified, u.created_at, u.last_login_at
     FROM users u
     WHERE u.id::text = $1 AND u.active = true`,
    [session.userId]
  );

  if (user) {
    // Add role from ID prefix
    user.role = getRoleFromId(user.id) || "user";
  }

  return user;
}

// OAuth account linking
export async function createOAuthAccount(
  provider: string,
  providerId: string,
  email: string,
  displayName: string,
  avatarUrl?: string
): Promise<User> {
  // Check if user already exists
  let user = await queryOne<User>(
    `SELECT 
      u.id, u.username, u.email, u.display_name, u.first_name, u.last_name, 
      u.avatar_url, u.active, u.email_verified, u.created_at, u.last_login_at
     FROM users u
     WHERE u.email = $1`,
    [email.toLowerCase()]
  );
  
  if (user) {
    // Add role from ID prefix
    user.role = getRoleFromId(user.id) || "user";
  }

  if (!user) {
    // Generate username from email (part before @) or display name
    const { generateUsername } = await import("./username-utils");
    const username = await generateUsername(email.split('@')[0] || displayName);
    
    // Create new user without password (OAuth only)
    const result = await queryOne<{ id: string }>(
      `INSERT INTO users (username, email, display_name, avatar_url, email_verified, active, account_state, password_hash)
       VALUES ($1, $2, $3, $4, true, true, 'ACTIVE', NULL)
       RETURNING id`,
      [username, email.toLowerCase(), displayName, avatarUrl]
    );

    if (!result) {
      throw new Error("Failed to create user");
    }

    // Create OAuth account link
    await query(
      `INSERT INTO oauth_accounts (user_id, provider, provider_id, email, display_name, avatar_url)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (provider, provider_id) DO UPDATE SET email = $4, display_name = $5, avatar_url = $6`,
      [result.id, provider, providerId, email.toLowerCase(), displayName, avatarUrl]
    );

    // Role is now in ID prefix - generate new ID with 'user' role
    const { generateUserId } = await import("./user-id-generator");
    const newUserId = await generateUserId("user");
    
    // Update user ID to have correct role prefix
    await query(
      `UPDATE users SET id = $1 WHERE id::text = $2`,
      [newUserId, result.id]
    );

    user = await queryOne<User>(
      `SELECT 
        u.id, u.username, u.email, u.display_name, u.first_name, u.last_name, 
        u.avatar_url, u.active, u.email_verified, u.created_at, u.last_login_at
       FROM users u
       WHERE u.id::text = $1`,
      [newUserId]
    ) as User;
    
    if (user) {
      user.role = getRoleFromId(user.id) || "user";
    }
  } else {
    // Link OAuth account to existing user
    await query(
      `INSERT INTO oauth_accounts (user_id, provider, provider_id, email, display_name, avatar_url)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (provider, provider_id) DO UPDATE SET email = $4, display_name = $5, avatar_url = $6`,
      [user.id, provider, providerId, email.toLowerCase(), displayName, avatarUrl]
    );
  }

  return user!;
}

export async function findOAuthAccount(provider: string, providerId: string): Promise<User | null> {
  const result = await queryOne<{ user_id: string }>(
    `SELECT user_id FROM oauth_accounts WHERE provider = $1 AND provider_id = $2`,
    [provider, providerId]
  );

  if (!result) {
    return null;
  }

  const foundUser = await queryOne<User>(
    `SELECT 
      u.id, u.username, u.email, u.display_name, u.first_name, u.last_name, 
      u.avatar_url, u.active, u.email_verified, u.created_at, u.last_login_at
     FROM users u
     WHERE u.id::text = $1 AND u.active = true`,
    [result.user_id]
  );
  
  if (foundUser) {
    foundUser.role = getRoleFromId(foundUser.id) || "user";
  }
  
  return foundUser;
}

/**
 * Get role-based redirect path for a user
 * Always returns username-based URL (GitHub style)
 * Example: /username
 * @deprecated Use user.username directly instead
 */
export function getRoleBasedRedirectPath(userId: string): string {
  // This function is deprecated - use user.username directly
  // Kept for backward compatibility but should be removed
  throw new Error("getRoleBasedRedirectPath is deprecated. Use user.username directly.");
}

