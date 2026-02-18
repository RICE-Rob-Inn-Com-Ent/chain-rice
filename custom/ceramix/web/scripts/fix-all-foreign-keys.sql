-- Fix all foreign key columns to use VARCHAR(50) for user_id
-- This ensures compatibility with new role-based user IDs

BEGIN;

-- Step 1: Remove orphaned sessions (sessions with user_id that doesn't exist in users)
DELETE FROM sessions 
WHERE user_id::text NOT IN (SELECT id::text FROM users);

-- Step 2: Fix sessions table
ALTER TABLE sessions DROP CONSTRAINT IF EXISTS sessions_user_id_fkey;
ALTER TABLE sessions ALTER COLUMN user_id TYPE VARCHAR(50) USING user_id::text;
ALTER TABLE sessions 
  ADD CONSTRAINT sessions_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Step 3: Fix oauth_accounts table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'oauth_accounts') THEN
        -- Remove orphaned oauth accounts
        DELETE FROM oauth_accounts 
        WHERE user_id::text NOT IN (SELECT id::text FROM users);
        
        -- Change column type if needed
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'oauth_accounts' 
            AND column_name = 'user_id'
            AND data_type = 'uuid'
        ) THEN
            ALTER TABLE oauth_accounts DROP CONSTRAINT IF EXISTS oauth_accounts_user_id_fkey;
            ALTER TABLE oauth_accounts ALTER COLUMN user_id TYPE VARCHAR(50) USING user_id::text;
            ALTER TABLE oauth_accounts 
                ADD CONSTRAINT oauth_accounts_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        END IF;
    END IF;
END $$;

-- Step 4: Fix mfa_backup_codes table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'mfa_backup_codes') THEN
        DELETE FROM mfa_backup_codes 
        WHERE user_id::text NOT IN (SELECT id::text FROM users);
        
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'mfa_backup_codes' 
            AND column_name = 'user_id'
            AND data_type = 'uuid'
        ) THEN
            ALTER TABLE mfa_backup_codes DROP CONSTRAINT IF EXISTS mfa_backup_codes_user_id_fkey;
            ALTER TABLE mfa_backup_codes ALTER COLUMN user_id TYPE VARCHAR(50) USING user_id::text;
            ALTER TABLE mfa_backup_codes 
                ADD CONSTRAINT mfa_backup_codes_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        END IF;
    END IF;
END $$;

-- Step 5: Fix verification_codes table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'verification_codes') THEN
        DELETE FROM verification_codes 
        WHERE user_id::text NOT IN (SELECT id::text FROM users);
        
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'verification_codes' 
            AND column_name = 'user_id'
            AND data_type = 'uuid'
        ) THEN
            ALTER TABLE verification_codes DROP CONSTRAINT IF EXISTS verification_codes_user_id_fkey;
            ALTER TABLE verification_codes ALTER COLUMN user_id TYPE VARCHAR(50) USING user_id::text;
            ALTER TABLE verification_codes 
                ADD CONSTRAINT verification_codes_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;
        END IF;
    END IF;
END $$;

COMMIT;






















































