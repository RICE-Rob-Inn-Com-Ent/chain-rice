/**
 * User ID Utility Functions (Edge Runtime Compatible)
 * 
 * These functions are used in middleware and must be compatible with Edge Runtime.
 * They do NOT require database access and are pure functions.
 */

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














































