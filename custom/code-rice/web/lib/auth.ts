import { cookies } from "next/headers";
import bcrypt from "bcryptjs";
import crypto from "crypto";
import { query, queryOne } from "./db";
import { getRoleFromId } from "./user-id-generator";

const SESSION_COOKIE = "code_rice_session";

export interface User {
  id: string;
  email: string;
  display_name: string;
  first_name: string | null;
  last_name: string | null;
  avatar_url: string | null;
  role: string;
  active: boolean;
  email_verified: boolean;
  created_at: Date;
  last_login_at: Date | null;
}

function getEndOfDay(): Date {
  const now = new Date();
  const end = new Date(now);
  end.setHours(23, 59, 59, 999);
  return end;
}

export function getSessionCookieMaxAge(): number {
  const now = new Date();
  const end = getEndOfDay();
  return Math.max(Math.floor((end.getTime() - now.getTime()) / 1000), 300);
}

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12);
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

async function getUserRole(userId: string): Promise<string> {
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

export async function createSession(userId: string): Promise<string> {
  const token = crypto.randomBytes(32).toString("hex");
  const refreshToken = crypto.randomBytes(32).toString("hex");
  const expiresAt = getEndOfDay();

  await query(
    `INSERT INTO sessions (user_id, session_token, refresh_token, session_type, expires_at, created_at, last_activity)
     VALUES ($1, $2, $3, 'web', $4, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
    [userId, token, refreshToken, expiresAt],
  );

  return token;
}

export async function deleteSession(sessionToken: string): Promise<void> {
  await query(`UPDATE sessions SET revoked = true WHERE session_token = $1`, [sessionToken]);
}

export async function getSession(sessionToken: string): Promise<{ userId: string } | null> {
  const session = await queryOne<{ user_id: string }>(
    `SELECT user_id FROM sessions 
     WHERE session_token = $1 AND revoked = false AND expires_at > CURRENT_TIMESTAMP`,
    [sessionToken],
  );
  return session ? { userId: session.user_id } : null;
}

export async function getCurrentUser(): Promise<User | null> {
  const cookieStore = await cookies();
  const sessionToken = cookieStore.get(SESSION_COOKIE)?.value;
  if (!sessionToken) {
    return null;
  }

  const session = await getSession(sessionToken);
  if (!session) {
    return null;
  }

  const user = await queryOne<User>(
    `SELECT 
      u.id,
      u.email,
      u.display_name,
      u.first_name,
      u.last_name,
      u.avatar_url,
      u.active,
      u.email_verified,
      u.created_at,
      u.last_login_at
     FROM users u
     WHERE u.id::text = $1 AND u.active = true`,
    [session.userId],
  );

  if (!user) {
    return null;
  }

  const role = await getUserRole(user.id);
  return { ...user, role };
}

export async function attachSessionCookie(userId: string): Promise<void> {
  const token = await createSession(userId);
  const cookieStore = await cookies();
  cookieStore.set(SESSION_COOKIE, token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: getSessionCookieMaxAge(),
    path: "/",
  });
}

export async function clearSessionCookie(): Promise<void> {
  const cookieStore = await cookies();
  const token = cookieStore.get(SESSION_COOKIE)?.value;
  if (token) {
    await deleteSession(token);
  }
  cookieStore.set(SESSION_COOKIE, "", { maxAge: 0, path: "/" });
}

/**
 * Get role-based redirect path for a user
 * Owners/admins go to GiPT console, others use user ID-based URL (GitHub style)
 */
export async function getRoleBasedRedirectPath(userId: string): Promise<string> {
  let role = getRoleFromId(userId);
  
  // If role can't be determined from ID (e.g., old UUID format), check database
  if (!role) {
    role = await getUserRole(userId);
  }
  
  // Case-insensitive role check
  const roleLower = (role || "").toLowerCase();
  const isGiptUser = roleLower === "owner" || roleLower === "admin" || 
                     role === "OWN" || role === "ADM";
  
  // Owners and admins go directly to GiPT console
  if (isGiptUser) {
    return "/admin/dashboard";
  }
  
  // Everyone else uses user ID-based URL
  return `/${userId}`;
}


