-- Ceramix Database Migrations
-- OAuth Accounts Table

CREATE TABLE IF NOT EXISTS oauth_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL,
    provider_id VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    display_name VARCHAR(255),
    avatar_url TEXT,
    access_token TEXT,
    refresh_token TEXT,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(provider, provider_id)
);

-- Indexes for OAuth accounts
CREATE INDEX IF NOT EXISTS idx_oauth_accounts_user_id ON oauth_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_oauth_accounts_provider ON oauth_accounts(provider, provider_id);

-- Make password_hash nullable for OAuth users
DO $$ 
BEGIN
    ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
EXCEPTION
    WHEN OTHERS THEN
        -- Column might not exist or already nullable
        NULL;
END $$;

-- Add two_factor_enabled and two_factor_secret to users if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'two_factor_enabled'
    ) THEN
        ALTER TABLE users ADD COLUMN two_factor_enabled BOOLEAN DEFAULT false;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'two_factor_secret'
    ) THEN
        ALTER TABLE users ADD COLUMN two_factor_secret VARCHAR(255);
    END IF;
END $$;

-- Add role column to users if not exists (for backward compatibility)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = 'role'
    ) THEN
        ALTER TABLE users ADD COLUMN role VARCHAR(50) DEFAULT 'user';
    END IF;
END $$;

-- MFA Backup Codes table
CREATE TABLE IF NOT EXISTS mfa_backup_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(255) NOT NULL,
    used BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, code)
);

CREATE INDEX IF NOT EXISTS idx_mfa_backup_codes_user_id ON mfa_backup_codes(user_id);

-- Trigger for oauth_accounts updated_at
CREATE TRIGGER update_oauth_accounts_updated_at BEFORE UPDATE ON oauth_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

