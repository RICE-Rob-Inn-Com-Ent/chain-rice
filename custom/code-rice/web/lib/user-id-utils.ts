/**
 * Pure utility functions for user ID parsing - safe for Edge Runtime
 * These functions don't require database access and can be used in middleware
 */

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
  const patternWithTime = /^(DEV|ADM|MGR|OWN|USR)-\d{8}-\d{6}-\d{6}$/;
  const patternWithoutTime = /^(DEV|ADM|MGR|OWN|USR)-\d{8}-\d{6}$/;
  return patternWithTime.test(id) || patternWithoutTime.test(id);
}

/**
 * Validate user ID format
 * Accepts both old UUID format and new role-based format for backward compatibility
 */
export function isValidUserId(id: string): boolean {
  // New format with time: PREFIX-YYYYMMDD-HHMMSS-XXXXXX
  const patternWithTime = /^(DEV|ADM|MGR|OWN|USR)-\d{8}-\d{6}-\d{6}$/;
  // New format without time: PREFIX-YYYYMMDD-XXXXXX
  const patternWithoutTime = /^(DEV|ADM|MGR|OWN|USR)-\d{8}-\d{6}$/;
  // Old UUID format: 8-4-4-4-12 hex digits
  const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  
  return patternWithTime.test(id) || patternWithoutTime.test(id) || uuidPattern.test(id);
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
  
  if (!id.includes("-")) {
    return null;
  }
  
  const prefix = id.split("-")[0];
  const map: Record<string, string> = {
    DEV: "developer",
    ADM: "admin",
    MGR: "manager",
    OWN: "owner",
    USR: "user",
  };
  return map[prefix] || null;
}






