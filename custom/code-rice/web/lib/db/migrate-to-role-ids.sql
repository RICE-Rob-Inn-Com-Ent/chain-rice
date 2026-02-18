-- Migration: Change users.id from UUID to TEXT to support role-prefixed IDs
-- This migration allows user IDs in format: OWN-20251123-143025-000001
-- Uses CASCADE to drop constraints automatically, no owner privileges needed

BEGIN;

-- Step 1: Drop foreign key constraints with CASCADE (safer, no owner needed)
ALTER TABLE IF EXISTS user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_fkey CASCADE;
ALTER TABLE IF EXISTS user_roles DROP CONSTRAINT IF EXISTS user_roles_granted_by_fkey CASCADE;
ALTER TABLE IF EXISTS sessions DROP CONSTRAINT IF EXISTS sessions_user_id_fkey CASCADE;
ALTER TABLE IF EXISTS oauth_accounts DROP CONSTRAINT IF EXISTS oauth_accounts_user_id_fkey CASCADE;
ALTER TABLE IF EXISTS mfa_backup_codes DROP CONSTRAINT IF EXISTS mfa_backup_codes_user_id_fkey CASCADE;

-- Step 2: Update foreign key tables to use TEXT first (convert UUID to text)
ALTER TABLE IF EXISTS user_roles ALTER COLUMN user_id TYPE TEXT USING user_id::TEXT;
ALTER TABLE IF EXISTS user_roles ALTER COLUMN granted_by TYPE TEXT USING granted_by::TEXT;
ALTER TABLE IF EXISTS sessions ALTER COLUMN user_id TYPE TEXT USING user_id::TEXT;
ALTER TABLE IF EXISTS oauth_accounts ALTER COLUMN user_id TYPE TEXT USING user_id::TEXT;
ALTER TABLE IF EXISTS mfa_backup_codes ALTER COLUMN user_id TYPE TEXT USING user_id::TEXT;

-- Step 3: Change users.id column type to TEXT
ALTER TABLE IF EXISTS users ALTER COLUMN id TYPE TEXT USING id::TEXT;

-- Step 4: Recreate foreign key constraints (only if tables exist)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_roles') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                       WHERE constraint_name = 'user_roles_user_id_fkey' 
                       AND table_name = 'user_roles') THEN
            ALTER TABLE user_roles 
                ADD CONSTRAINT user_roles_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        END IF;
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_roles' AND column_name = 'granted_by') THEN
            IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                           WHERE constraint_name = 'user_roles_granted_by_fkey' 
                           AND table_name = 'user_roles') THEN
                ALTER TABLE user_roles 
                    ADD CONSTRAINT user_roles_granted_by_fkey 
                    FOREIGN KEY (granted_by) REFERENCES users(id) ON DELETE SET NULL;
            END IF;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'sessions') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                       WHERE constraint_name = 'sessions_user_id_fkey' 
                       AND table_name = 'sessions') THEN
            ALTER TABLE sessions 
                ADD CONSTRAINT sessions_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'oauth_accounts') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                       WHERE constraint_name = 'oauth_accounts_user_id_fkey' 
                       AND table_name = 'oauth_accounts') THEN
            ALTER TABLE oauth_accounts 
                ADD CONSTRAINT oauth_accounts_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        END IF;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mfa_backup_codes') THEN
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                       WHERE constraint_name = 'mfa_backup_codes_user_id_fkey' 
                       AND table_name = 'mfa_backup_codes') THEN
            ALTER TABLE mfa_backup_codes 
                ADD CONSTRAINT mfa_backup_codes_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        END IF;
    END IF;
END $$;

-- Step 5: Ensure indexes exist
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(active);

COMMIT;

