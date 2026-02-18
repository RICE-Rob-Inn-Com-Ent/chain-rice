/**
 * Username Utility Functions (Edge Runtime Compatible)
 * 
 * Functions for validating and working with usernames in URLs.
 * Similar to GitHub's username system.
 */

/**
 * Validate username format
 * Username rules:
 * - 3-50 characters
 * - Alphanumeric + hyphens only
 * - Must start and end with alphanumeric
 * - No consecutive hyphens
 * - Case-insensitive (stored as lowercase)
 */
export function isValidUsername(username: string): boolean {
  if (!username || typeof username !== 'string') {
    return false;
  }
  
  // Must be between 3-50 characters
  if (username.length < 3 || username.length > 50) {
    return false;
  }
  
  // Must match pattern: alphanumeric, can contain hyphens, but not at start/end
  // Must not have consecutive hyphens
  const usernamePattern = /^[a-z0-9]([a-z0-9-]{1,48}[a-z0-9])?$/;
  
  return usernamePattern.test(username.toLowerCase());
}

/**
 * Normalize username (convert to lowercase, trim)
 */
export function normalizeUsername(username: string): string {
  return username.toLowerCase().trim();
}

/**
 * Sanitize username for display (can be used to clean user input)
 */
export function sanitizeUsername(input: string): string {
  return input
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9-]/g, '') // Remove invalid chars
    .replace(/^-+|-+$/g, '') // Remove leading/trailing hyphens
    .replace(/-{2,}/g, '-') // Replace consecutive hyphens with single
    .slice(0, 50); // Max 50 chars
}

/**
 * Get user by username
 * Used for URL routing: /username -> find user and redirect to their dashboard
 */
export async function getUserByUsername(username: string): Promise<{ id: string; username: string; role: string } | null> {
  const { queryOne } = await import("./db");
  const { getRoleFromId } = await import("./user-id-generator");
  
  const user = await queryOne<{ id: string; username: string }>(
    `SELECT id, username FROM users WHERE username = $1 AND active = true`,
    [normalizeUsername(username)]
  );
  
  if (!user) {
    return null;
  }
  
  const role = getRoleFromId(user.id) || "user";
  
  return {
    id: user.id,
    username: user.username,
    role,
  };
}

/**
 * Generate unique username from base text
 * Checks database for uniqueness and appends number if needed
 * Prevents using reserved route prefixes (own, pat, doc, adm, me, etc.)
 */
export async function generateUsername(baseText: string): Promise<string> {
  const { queryOne } = await import("./db");
  
  const sanitized = sanitizeUsername(baseText);
  
  // If empty after sanitization, use 'user'
  let candidate = sanitized || 'user';
  
  // Ensure minimum length
  if (candidate.length < 3) {
    candidate = candidate + '123';
  }
  
  // Reserved route prefixes that cannot be used as usernames
  const reservedPrefixes = ['own', 'pat', 'doc', 'adm', 'me', 'sign-in', 'sign-up', 'login', 'register', 'api', 'admin', '_next'];
  
  // If candidate is a reserved prefix, append a number
  if (reservedPrefixes.includes(candidate.toLowerCase())) {
    candidate = candidate + '1';
  }
  
  // Check if username exists OR is a reserved prefix
  let counter = 0;
  let exists = await queryOne<{ id: string }>(
    `SELECT id FROM users WHERE username = $1`,
    [candidate]
  );
  
  // Also check if it's a reserved prefix
  let isReserved = reservedPrefixes.includes(candidate.toLowerCase());
  
  while (exists || isReserved) {
    counter++;
    const newCandidate = candidate.replace(/\d+$/, '') + counter.toString(); // Replace trailing numbers with new counter
    
    // Prevent infinite loop
    if (counter > 999999) {
      // Fallback: use timestamp
      candidate = 'user' + Date.now().toString();
      break;
    }
    
    candidate = newCandidate.length <= 50 ? newCandidate : newCandidate.slice(0, 50 - counter.toString().length) + counter.toString();
    
    exists = await queryOne<{ id: string }>(
      `SELECT id FROM users WHERE username = $1`,
      [candidate]
    );
    
    isReserved = reservedPrefixes.includes(candidate.toLowerCase());
  }
  
  return candidate;
}

