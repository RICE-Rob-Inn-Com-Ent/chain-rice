import { queryOne } from "./db";
// Import Edge Runtime safe functions for internal use
import { isOldUuidFormat } from "./user-id-utils";
// Re-export Edge Runtime safe functions from user-id-utils
export {
  isValidUserId,
  isNewRoleBasedFormat,
  isOldUuidFormat,
  getRoleFromId,
} from "./user-id-utils";

const ROLE_PREFIXES: Record<string, string> = {
  developer: "DEV",
  dev: "DEV",
  programista: "DEV",
  admin: "ADM",
  administrator: "ADM",
  manager: "MGR",
  zarządca: "MGR",
  owner: "OWN",
  właściciel: "OWN",
  superadmin: "ADM", // legacy, maps to ADM
  user: "USR",
};

const SEQUENCE_DIGITS = 6; // 000000-999999 = 1 million per second
const INCLUDE_TIME = true; // Include time for better uniqueness

export function getRolePrefix(role: string): string {
  const normalized = role.toLowerCase().trim();
  return ROLE_PREFIXES[normalized] || "USR";
}

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

  const lastId = await queryOne<{ id: string }>(
    `SELECT id::text AS id FROM users WHERE id::text LIKE $1 ORDER BY id::text DESC LIMIT 1`,
    [searchPattern],
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
    await new Promise(resolve => setTimeout(resolve, 1));
    return generateUserId(role); // Retry with new timestamp
  }
  
  if (INCLUDE_TIME) {
    return `${prefix}-${dateStr}-${timeStr}-${sequenceStr}`;
  } else {
    return `${prefix}-${dateStr}-${sequenceStr}`;
  }
}

// Functions isValidUserId, isNewRoleBasedFormat, isOldUuidFormat, getRoleFromId
// are now exported from ./user-id-utils.ts (Edge Runtime safe)

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


