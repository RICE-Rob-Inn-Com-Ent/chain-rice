/**
 * User ID Generator with Role-based Prefixes
 * 
 * Format: PREFIX-YYYYMMDD-HHMMSS-XXXXXX
 * - PAT - patient (pacjent)
 * - DOC - doctor (lekarz)
 * - ADM - administrator
 * - OWN - owner (właściciel placówki)
 * - SUP - superadmin (legacy, use OWN instead)
 * - USR - user (default)
 * 
 * Scalable format:
 * - Date: YYYYMMDD (8 digits)
 * - Time: HHMMSS (6 digits) - for millisecond precision
 * - Sequence: XXXXXX (6 digits) - up to 1 million per second
 * 
 * Total capacity: 1 million users per second per role = 86.4 billion per day per role
 */

import { queryOne } from "./db";

const ROLE_PREFIXES: Record<string, string> = {
  patient: "PAT",
  doctor: "DOC",
  dentist: "DOC", // lekarz dentysta też DOC
  lekarz: "DOC",
  admin: "ADM",
  administrator: "ADM",
  owner: "OWN",
  właściciel: "OWN",
  superadmin: "SUP", // legacy, maps to SUP for backward compatibility
  superadministrator: "SUP", // legacy
  user: "USR",
};

// Configuration for ID generation
const SEQUENCE_DIGITS = 6; // 000000-999999 = 1 million per second
const INCLUDE_TIME = true; // Include time for better uniqueness

/**
 * Get prefix for role
 */
export function getRolePrefix(role: string): string {
  const normalizedRole = role.toLowerCase().trim();
  return ROLE_PREFIXES[normalizedRole] || "USR";
}

/**
 * Generate user ID with role-based prefix
 * Format: PREFIX-YYYYMMDD-HHMMSS-XXXXXX (with time)
 * Format: PREFIX-YYYYMMDD-XXXXXX (without time)
 */
export async function generateUserId(role: string = "user"): Promise<string> {
  const prefix = getRolePrefix(role);
  const date = new Date();
  const dateStr = date.toISOString().slice(0, 10).replace(/-/g, ""); // YYYYMMDD
  
  let timeStr = "";
  let searchPattern = `${prefix}-${dateStr}-%`;
  
  if (INCLUDE_TIME) {
    // Include time (HHMMSS) for better uniqueness
    const hours = date.getUTCHours().toString().padStart(2, "0");
    const minutes = date.getUTCMinutes().toString().padStart(2, "0");
    const seconds = date.getUTCSeconds().toString().padStart(2, "0");
    timeStr = `${hours}${minutes}${seconds}`;
    searchPattern = `${prefix}-${dateStr}-${timeStr}-%`;
  }
  
  // Get the last number for this second (or day if no time)
  // Cast to text to support both UUID and VARCHAR columns
  const lastId = await queryOne<{ id: string }>(
    `SELECT id::text as id FROM users 
     WHERE id::text LIKE $1 
     ORDER BY id::text DESC 
     LIMIT 1`,
    [searchPattern]
  );
  
  let sequence = 1;
  if (lastId?.id) {
    // Extract sequence number from last ID
    const parts = lastId.id.split("-");
    if (INCLUDE_TIME && parts.length === 4) {
      // Format: PREFIX-YYYYMMDD-HHMMSS-XXXXXX
      const lastSequence = parseInt(parts[3], 10);
      if (!isNaN(lastSequence)) {
        sequence = lastSequence + 1;
      }
    } else if (!INCLUDE_TIME && parts.length === 3) {
      // Format: PREFIX-YYYYMMDD-XXXXXX
      const lastSequence = parseInt(parts[2], 10);
      if (!isNaN(lastSequence)) {
        sequence = lastSequence + 1;
      }
    }
  }
  
  // Format sequence with configured digits
  const sequenceStr = sequence.toString().padStart(SEQUENCE_DIGITS, "0");
  
  // Check if sequence exceeds maximum
  const maxSequence = Math.pow(10, SEQUENCE_DIGITS) - 1;
  if (sequence > maxSequence) {
    // If we exceed max for this second, wait a millisecond and try again
    // In practice, this should never happen with 6 digits (1 million per second)
    await new Promise(resolve => setTimeout(resolve, 1));
    return generateUserId(role); // Retry with new timestamp
  }
  
  if (INCLUDE_TIME) {
    return `${prefix}-${dateStr}-${timeStr}-${sequenceStr}`;
  } else {
    return `${prefix}-${dateStr}-${sequenceStr}`;
  }
}

/**
 * Validate user ID format
 * Accepts both old UUID format and new role-based format for backward compatibility
 */
export function isValidUserId(id: string): boolean {
  // New format with time: PREFIX-YYYYMMDD-HHMMSS-XXXXXX
  const patternWithTime = /^(PAT|DOC|ADM|OWN|SUP|USR)-\d{8}-\d{6}-\d{6}$/;
  // New format without time: PREFIX-YYYYMMDD-XXXXXX
  const patternWithoutTime = /^(PAT|DOC|ADM|OWN|SUP|USR)-\d{8}-\d{6}$/;
  // Old UUID format: 8-4-4-4-12 hex digits
  const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  
  return patternWithTime.test(id) || patternWithoutTime.test(id) || uuidPattern.test(id);
}

/**
 * Check if user ID is in old UUID format
 */
export function isOldUuidFormat(id: string): boolean {
  const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidPattern.test(id);
}

/**
 * Check if user ID is in new role-based format
 */
export function isNewRoleBasedFormat(id: string): boolean {
  const patternWithTime = /^(PAT|DOC|ADM|OWN|SUP|USR)-\d{8}-\d{6}-\d{6}$/;
  const patternWithoutTime = /^(PAT|DOC|ADM|OWN|SUP|USR)-\d{8}-\d{6}$/;
  return patternWithTime.test(id) || patternWithoutTime.test(id);
}

/**
 * Get role from user ID prefix
 * Returns null for old UUID format (role must be fetched from database)
 */
export function getRoleFromId(id: string): string | null {
  // Check if it's old UUID format
  if (isOldUuidFormat(id)) {
    return null; // Role must be fetched from database
  }
  
  const prefix = id.split("-")[0];
  const roleMap: Record<string, string> = {
    PAT: "patient",
    DOC: "doctor",
    ADM: "admin",
    OWN: "owner",
    SUP: "superadmin", // legacy
    USR: "user",
  };
  return roleMap[prefix] || "user";
}

/**
 * Get capacity information
 */
export function getCapacityInfo() {
  const maxPerSecond = Math.pow(10, SEQUENCE_DIGITS) - 1;
  const maxPerDay = maxPerSecond * 86400; // seconds in a day
  const maxPerYear = maxPerDay * 365;
  
  return {
    sequenceDigits: SEQUENCE_DIGITS,
    includeTime: INCLUDE_TIME,
    maxPerSecond: maxPerSecond.toLocaleString(),
    maxPerDay: maxPerDay.toLocaleString(),
    maxPerYear: maxPerYear.toLocaleString(),
    format: INCLUDE_TIME 
      ? `PREFIX-YYYYMMDD-HHMMSS-${"X".repeat(SEQUENCE_DIGITS)}`
      : `PREFIX-YYYYMMDD-${"X".repeat(SEQUENCE_DIGITS)}`,
  };
}

/**
 * Check if user ID matches role
 * Returns null for old UUID format (cannot determine from ID alone)
 */
export function userIdMatchesRole(id: string, role: string): boolean | null {
  // Old UUID format - cannot determine role from ID
  if (isOldUuidFormat(id)) {
    return null; // Must check in database
  }
  
  const expectedPrefix = getRolePrefix(role);
  const actualPrefix = id.split("-")[0];
  return actualPrefix === expectedPrefix;
}

