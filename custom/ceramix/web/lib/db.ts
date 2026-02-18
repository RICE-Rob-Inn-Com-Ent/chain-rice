import { Pool } from "pg";

// CRITICAL: This file MUST use DATABASE_URL directly, NEVER use getPool() function
// If you see getPool() being called, it means webpack is using cached old code
// Delete .next directory and restart the dev server

// Create a connection pool
// Force ceramix_user - never use rice_user
// CRITICAL: Log module load time and environment
console.log("🔍 [lib/db.ts] MODULE LOADED at:", new Date().toISOString());
console.log("🔍 [lib/db.ts] process.env.DATABASE_URL at load time:", process.env.DATABASE_URL ? process.env.DATABASE_URL.replace(/:[^:@]+@/, ':****@').substring(0, 80) : "NOT SET");

// CRITICAL: Force DATABASE_URL to be set correctly
// This ensures webpack doesn't use cached old code with getPool()
if (!process.env.DATABASE_URL) {
  console.error("❌ ERROR: DATABASE_URL is not set! Setting default...");
  process.env.DATABASE_URL = "postgresql://ceramix_user:ceramix_password@localhost:5432/ceramix?sslmode=disable";
}

const connectionString = process.env.DATABASE_URL;

// Validate connection string doesn't contain "rice" user
if (connectionString.includes("rice_user") || connectionString.includes("rice_password")) {
  console.error("❌ ERROR: Connection string contains 'rice' user! This should never happen!");
  console.error("Current DATABASE_URL:", connectionString.replace(/:[^:@]+@/, ':****@'));
  throw new Error("Invalid DATABASE_URL: contains 'rice' user instead of 'ceramix_user'");
}

// Log connection string (masked) for debugging - ALWAYS log to help debug
console.log("🔍 [lib/db.ts] Database connection string:", connectionString.replace(/:[^:@]+@/, ':****@'));
console.log("🔍 [lib/db.ts] DATABASE_URL env var:", process.env.DATABASE_URL ? "SET" : "NOT SET");
if (process.env.DATABASE_URL) {
  console.log("🔍 [lib/db.ts] DATABASE_URL preview:", process.env.DATABASE_URL.replace(/:[^:@]+@/, ':****@').substring(0, 80));
}

// Parse connection string to verify it's correct
const parsedUrl = new URL(connectionString);
console.log("🔍 [lib/db.ts] Parsed connection string - user:", parsedUrl.username);
console.log("🔍 [lib/db.ts] Parsed connection string - host:", parsedUrl.hostname);
console.log("🔍 [lib/db.ts] Parsed connection string - database:", parsedUrl.pathname.substring(1));

// CRITICAL: Log if we detect rice user
if (parsedUrl.username.includes("rice")) {
  console.error("❌❌❌ [lib/db.ts] CRITICAL ERROR: Detected 'rice' in username:", parsedUrl.username);
  console.error("❌❌❌ [lib/db.ts] Full connection string (masked):", connectionString.replace(/:[^:@]+@/, ':****@'));
  console.error("❌❌❌ [lib/db.ts] process.env.DATABASE_URL (masked):", process.env.DATABASE_URL?.replace(/:[^:@]+@/, ':****@'));
}

const pool = new Pool({
  connectionString,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});

let legacyHelperPromise: Promise<void> | null = null;

async function ensureLegacyHelpers(): Promise<void> {
  if (!legacyHelperPromise) {
    legacyHelperPromise = (async () => {
      console.log("🔧 [lib/db.ts] Ensuring legacy helper functions exist");
      await pool.query(`
        CREATE OR REPLACE FUNCTION get_patient_number(user_uuid VARCHAR(50))
        RETURNS TEXT AS $$
        DECLARE
          result TEXT;
          has_users_patient_number BOOLEAN;
          has_patients_table BOOLEAN;
          has_patients_user_id BOOLEAN;
          has_patients_patient_number BOOLEAN;
        BEGIN
          SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'patient_number'
          ) INTO has_users_patient_number;

          IF has_users_patient_number THEN
            SELECT patient_number INTO result FROM users WHERE id::text = user_uuid LIMIT 1;
            IF result IS NOT NULL THEN
              RETURN result;
            END IF;
          END IF;

          SELECT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'patients'
          ) INTO has_patients_table;

          IF has_patients_table THEN
            SELECT EXISTS (
              SELECT 1 FROM information_schema.columns 
              WHERE table_schema = 'public' AND table_name = 'patients' AND column_name = 'patient_number'
            ) INTO has_patients_patient_number;

            IF has_patients_patient_number THEN
              SELECT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_schema = 'public' AND table_name = 'patients' AND column_name = 'user_id'
              ) INTO has_patients_user_id;

              IF has_patients_user_id THEN
                SELECT patient_number
                INTO result
                FROM patients
                WHERE user_id::text = user_uuid
                ORDER BY created_at DESC
                LIMIT 1;
                IF result IS NOT NULL THEN
                  RETURN result;
                END IF;
              END IF;

              -- Fallback: match by primary id if schemas shared UUIDs
              SELECT patient_number
              INTO result
              FROM patients
              WHERE id::text = user_uuid
              ORDER BY created_at DESC
              LIMIT 1;
              IF result IS NOT NULL THEN
                RETURN result;
              END IF;
            END IF;
          END IF;

          RETURN NULL;
        END;
        $$ LANGUAGE plpgsql STABLE;
      `);

      await pool.query(`
        CREATE OR REPLACE FUNCTION get_user_phone(user_uuid VARCHAR(50))
        RETURNS TEXT AS $$
        DECLARE
          result TEXT;
          has_users_phone BOOLEAN;
          has_patients_table BOOLEAN;
          has_patients_user_id BOOLEAN;
          has_patients_phone BOOLEAN;
        BEGIN
          SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'phone'
          ) INTO has_users_phone;

          IF has_users_phone THEN
            SELECT phone INTO result FROM users WHERE id::text = user_uuid LIMIT 1;
            IF result IS NOT NULL THEN
              RETURN result;
            END IF;
          END IF;

          SELECT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = 'patients'
          ) INTO has_patients_table;

          IF has_patients_table THEN
            SELECT EXISTS (
              SELECT 1 FROM information_schema.columns 
              WHERE table_schema = 'public' AND table_name = 'patients' AND column_name = 'phone'
            ) INTO has_patients_phone;

            IF has_patients_phone THEN
              SELECT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_schema = 'public' AND table_name = 'patients' AND column_name = 'user_id'
              ) INTO has_patients_user_id;

              IF has_patients_user_id THEN
                SELECT phone
                INTO result
                FROM patients
                WHERE user_id::text = user_uuid
                ORDER BY created_at DESC
                LIMIT 1;
                IF result IS NOT NULL THEN
                  RETURN result;
                END IF;
              END IF;

              -- Fallback: match by patient primary id
              SELECT phone
              INTO result
              FROM patients
              WHERE id::text = user_uuid
              ORDER BY created_at DESC
              LIMIT 1;
              IF result IS NOT NULL THEN
                RETURN result;
              END IF;
            END IF;
          END IF;

          RETURN NULL;
        END;
        $$ LANGUAGE plpgsql STABLE;
      `);

      await pool.query(`
        DROP FUNCTION IF EXISTS get_user_text_field(UUID, TEXT);
      `);

      await pool.query(`
        CREATE OR REPLACE FUNCTION get_user_text_field(user_uuid VARCHAR(50), target_column TEXT)
        RETURNS TEXT AS $$
        DECLARE
          result TEXT;
          column_exists BOOLEAN;
        BEGIN
          EXECUTE $sql$
            SELECT EXISTS (
              SELECT 1 FROM information_schema.columns 
              WHERE table_schema = 'public' AND table_name = 'users' AND column_name = $1
            )
          $sql$
          INTO column_exists
          USING target_column;

          IF NOT column_exists THEN
            RETURN NULL;
          END IF;

          EXECUTE format('SELECT %I::TEXT FROM users WHERE id::text = $1 LIMIT 1', target_column)
          INTO result
          USING user_uuid;

          RETURN result;
        EXCEPTION
          WHEN undefined_column THEN
            RETURN NULL;
        END;
        $$ LANGUAGE plpgsql STABLE;
      `);

      // Create get_user_phone_verified function to safely get phone_verified status
      await pool.query(`
        DROP FUNCTION IF EXISTS get_user_phone_verified(UUID);
      `);

      await pool.query(`
        CREATE OR REPLACE FUNCTION get_user_phone_verified(user_uuid VARCHAR(50))
        RETURNS BOOLEAN AS $$
        DECLARE
          result BOOLEAN;
          column_exists BOOLEAN;
        BEGIN
          -- Check if phone_verified column exists
          SELECT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'users' 
            AND column_name = 'phone_verified'
          ) INTO column_exists;

          IF NOT column_exists THEN
            RETURN false;
          END IF;

          -- Get phone_verified value
          SELECT COALESCE(phone_verified, false)
          INTO result
          FROM users
          WHERE id::text = user_uuid
          LIMIT 1;

          RETURN COALESCE(result, false);
        EXCEPTION
          WHEN undefined_column THEN
            RETURN false;
        END;
        $$ LANGUAGE plpgsql STABLE;
      `);
      
      // Create verification_codes table if it doesn't exist
      await pool.query(`
        CREATE TABLE IF NOT EXISTS verification_codes (
          id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
          user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
          code VARCHAR(10) NOT NULL,
          type VARCHAR(20) NOT NULL CHECK (type IN ('email', 'sms')),
          expires_at TIMESTAMP NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          UNIQUE(user_id, type)
        );
        CREATE INDEX IF NOT EXISTS idx_verification_codes_user_id ON verification_codes(user_id);
        CREATE INDEX IF NOT EXISTS idx_verification_codes_expires_at ON verification_codes(expires_at);
      `);
      
      // Note: phone_verified column should be added via migration
      // We'll handle it gracefully in queries using COALESCE
      
      console.log("✅ [lib/db.ts] Legacy helper functions ready");
    })().catch((err) => {
      legacyHelperPromise = null;
      console.error("❌ [lib/db.ts] Failed to ensure legacy helpers:", err);
      throw err;
    });
  }
  return legacyHelperPromise;
}

// Test connection on startup
pool.on("connect", () => {
  console.log("Connected to PostgreSQL database");
});

pool.on("error", (err) => {
  console.error("Unexpected error on idle client", err);
  process.exit(-1);
});

// Query helper functions
export async function query<T = any>(text: string, params?: any[]): Promise<any> {
  const start = Date.now();
  try {
    await ensureLegacyHelpers();
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    if (process.env.NODE_ENV === "development") {
      console.log("Executed query", { text, duration, rows: res.rowCount });
    }
    return res;
  } catch (error: any) {
    console.error("Query error", { 
      text: text.substring(0, 100), 
      error: error?.message,
      code: error?.code,
      detail: error?.detail 
    });
    throw error;
  }
}

export async function queryOne<T = any>(text: string, params?: any[]): Promise<T | null> {
  const result = await query<T>(text, params);
  return result.rows[0] || null;
}

export async function queryMany<T = any>(text: string, params?: any[]): Promise<T[]> {
  const result = await query<T>(text, params);
  return result.rows || [];
}

// Transaction helper
export async function transaction<T>(callback: (client: any) => Promise<T>): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const result = await callback(client);
    await client.query("COMMIT");
    return result;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

export default pool;

