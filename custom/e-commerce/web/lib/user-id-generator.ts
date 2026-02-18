/**
 * User ID Generator with Role-based Prefixes for Meowtopia (E-commerce)
 * 
 * Format: PREFIX-YYYYMMDD-HHMMSS-XXXXXX
 * - USR - user (użytkownik)
 * - MGR - manager (zarządca sklepu)
 * - ADM - administrator
 * - OWN - owner (właściciel)
 * - VOL - volunteer (wolontariusz)
 * 
 * Scalable format:
 * - Date: YYYYMMDD (8 digits)
 * - Time: HHMMSS (6 digits) - for millisecond precision
 * - Sequence: XXXXXX (6 digits) - up to 1 million per second
 * 
 * Total capacity: 1 million users per second per role = 86.4 billion per day per role
 */

import { prisma } from "./prisma";

const ROLE_PREFIXES: Record<string, string> = {
  user: "USR",
  customer: "USR",
  klient: "USR",
  manager: "MGR",
  zarządca: "MGR",
  admin: "ADM",
  administrator: "ADM",
  owner: "OWN",
  właściciel: "OWN",
  volunteer: "VOL",
  wolontariusz: "VOL",
  artist: "ART",
  artysta: "ART",
};

// Configuration for ID generation
const SEQUENCE_DIGITS = 6; // 000000-999999 = 1 million per second
const INCLUDE_TIME = true; // Include time for better uniqueness

/**
 * Get prefix for role
 */
export function getRolePrefix(role: string): string {
  const normalizedRole = role.toUpperCase().trim();
  // Map enum values to prefixes
  if (normalizedRole === "USER") return "USR";
  if (normalizedRole === "CUSTOMER") return "USR"; // Legacy support
  if (normalizedRole === "MANAGER") return "MGR";
  if (normalizedRole === "ADMIN") return "ADM";
  if (normalizedRole === "OWNER") return "OWN";
  if (normalizedRole === "VOLUNTEER") return "VOL";
  if (normalizedRole === "ARTIST") return "ART";
  
  // Check if input is already a valid prefix (3 uppercase letters)
  if (/^[A-Z]{3}$/.test(normalizedRole)) {
    const validPrefixes = ["USR", "CUS", "MGR", "ADM", "OWN", "VOL", "ART"];
    if (validPrefixes.includes(normalizedRole)) {
      return normalizedRole;
    }
  }
  
  // Fallback to lowercase mapping
  const normalized = role.toLowerCase().trim();
  return ROLE_PREFIXES[normalized] || "USR";
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
  
  // Get the last ID for this pattern using Prisma
  const lastUser = await prisma.user.findFirst({
    where: {
      id: {
        startsWith: searchPattern.replace("%", ""),
      },
    },
    orderBy: {
      id: "desc",
    },
  });
  
  let sequence = 1;
  if (lastUser?.id) {
    // Extract sequence number from last ID
    const parts = lastUser.id.split("-");
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
 * Accepts both old CUID format and new role-based format for backward compatibility
 */
export function isValidUserId(id: string): boolean {
  // New format with time: PREFIX-YYYYMMDD-HHMMSS-XXXXXX
  const patternWithTime = /^(USR|CUS|MGR|ADM|OWN|VOL|ART)-\d{8}-\d{6}-\d{6}$/;
  // New format without time: PREFIX-YYYYMMDD-XXXXXX
  const patternWithoutTime = /^(USR|CUS|MGR|ADM|OWN|VOL|ART)-\d{8}-\d{6}$/;
  // Old CUID format: starts with 'c' followed by 24 alphanumeric characters
  const cuidPattern = /^c[a-z0-9]{24}$/i;
  
  return patternWithTime.test(id) || patternWithoutTime.test(id) || cuidPattern.test(id);
}

/**
 * Check if user ID is in old CUID format
 */
export function isOldCuidFormat(id: string): boolean {
  const cuidPattern = /^c[a-z0-9]{24}$/i;
  return cuidPattern.test(id);
}

/**
 * Check if user ID is in new role-based format
 */
export function isNewRoleBasedFormat(id: string): boolean {
  const patternWithTime = /^(USR|CUS|MGR|ADM|OWN|VOL|ART)-\d{8}-\d{6}-\d{6}$/;
  const patternWithoutTime = /^(USR|CUS|MGR|ADM|OWN|VOL|ART)-\d{8}-\d{6}$/;
  return patternWithTime.test(id) || patternWithoutTime.test(id);
}

/**
 * Get role from user ID prefix
 * Returns null for old CUID format (role must be fetched from database)
 */
export function getRoleFromId(id: string): string | null {
  // Check if it's old CUID format
  if (isOldCuidFormat(id)) {
    return null; // Role must be fetched from database
  }
  
  const prefix = id.split("-")[0];
  const roleMap: Record<string, string> = {
    USR: "USER",
    CUS: "USER", // Legacy support
    MGR: "MANAGER",
    ADM: "ADMIN",
    OWN: "OWNER",
    VOL: "VOLUNTEER",
    ART: "ARTIST",
  };
  return roleMap[prefix] || "USER";
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
 * Returns null for old CUID format (cannot determine from ID alone)
 */
export function userIdMatchesRole(id: string, role: string): boolean | null {
  // Old CUID format - cannot determine role from ID
  if (isOldCuidFormat(id)) {
    return null; // Must check in database
  }
  
  const expectedPrefix = getRolePrefix(role);
  const actualPrefix = id.split("-")[0];
  return actualPrefix === expectedPrefix;
}


