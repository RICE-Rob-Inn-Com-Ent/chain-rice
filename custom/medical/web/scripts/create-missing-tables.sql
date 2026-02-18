-- Create missing tables for authentication
-- This ensures all required tables exist with correct types

BEGIN;

-- OAuth accounts table
CREATE TABLE IF NOT EXISTS oauth_accounts (
    id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    provider_id VARCHAR(255) NOT NULL,
    email VARCHAR(255),
    display_name VARCHAR(255),
    avatar_url TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(provider, provider_id)
);

-- MFA backup codes table
CREATE TABLE IF NOT EXISTS mfa_backup_codes (
    id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(255) NOT NULL,
    used BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Verification codes table
CREATE TABLE IF NOT EXISTS verification_codes (
    id VARCHAR(50) PRIMARY KEY DEFAULT gen_random_uuid()::text,
    user_id VARCHAR(50) REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(255) NOT NULL,
    type VARCHAR(50) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Fix sessions table if user_id is still UUID
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'sessions' 
        AND column_name = 'user_id'
        AND data_type = 'uuid'
    ) THEN
        ALTER TABLE sessions DROP CONSTRAINT IF EXISTS sessions_user_id_fkey;
        ALTER TABLE sessions ALTER COLUMN user_id TYPE VARCHAR(50) USING user_id::text;
        ALTER TABLE sessions 
            ADD CONSTRAINT sessions_user_id_fkey 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Fix oauth_accounts if user_id is UUID
DO $$
BEGIN
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
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_oauth_accounts_user_id ON oauth_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_oauth_accounts_provider ON oauth_accounts(provider, provider_id);

COMMIT;




















