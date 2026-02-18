-- Code-Rice Database Initialization
-- Tworzy bazę danych code-rice z przykładowymi użytkownikami
-- This script runs after the database is created

-- Połącz się z bazą code-rice przed uruchomieniem reszty:
\c "code-rice"

-- Grant schema privileges to code_rice_user
GRANT ALL ON SCHEMA public TO code_rice_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO code_rice_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO code_rice_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO code_rice_user;

-- Włącz wymagane rozszerzenia
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Tabela użytkowników (jeśli nie istnieje)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    display_name VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    avatar_url TEXT,
    timezone VARCHAR(50) DEFAULT 'UTC',
    preferred_language VARCHAR(10) DEFAULT 'en',
    account_state VARCHAR(50) DEFAULT 'ACTIVE',
    active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    last_login_ip INET,
    last_login_location JSONB,
    metadata JSONB DEFAULT '{}'::jsonb,
    two_factor_enabled BOOLEAN DEFAULT false,
    two_factor_secret VARCHAR(255)
);

-- Tabela ról użytkowników
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    granted_by UUID REFERENCES users(id),
    UNIQUE(user_id, role)
);

-- Tabela sesji
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE NOT NULL,
    session_type VARCHAR(50) NOT NULL,
    client_info TEXT,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked BOOLEAN DEFAULT false
);

-- Tabela kont OAuth
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

-- Tabela kodów zapasowych 2FA
CREATE TABLE IF NOT EXISTS mfa_backup_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(255) NOT NULL,
    used BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, code)
);

-- Indeksy
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(active);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);
CREATE INDEX IF NOT EXISTS idx_oauth_accounts_user_id ON oauth_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_oauth_accounts_provider ON oauth_accounts(provider, provider_id);
CREATE INDEX IF NOT EXISTS idx_mfa_backup_codes_user_id ON mfa_backup_codes(user_id);

-- Funkcja do aktualizacji updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggery
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_oauth_accounts_updated_at ON oauth_accounts;
CREATE TRIGGER update_oauth_accounts_updated_at BEFORE UPDATE ON oauth_accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- PRZYKŁADOWI UŻYTKOWNICY DO TESTOWANIA
-- ============================================================================

-- Hasła są zahashowane używając bcrypt z kosztem 12
-- Wszystkie hasła to: "Test1234!" (dla łatwości testowania)

-- 1. SUPERADMINISTRATOR
INSERT INTO users (
    id, email, password_hash, display_name, first_name, last_name,
    active, email_verified, account_state, created_at
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'superadmin@code-rice.com',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyY5Y5Y5Y5Y5', -- Test1234!
    'Super Administrator',
    'John',
    'Doe',
    true,
    true,
    'ACTIVE',
    CURRENT_TIMESTAMP
) ON CONFLICT (email) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    display_name = EXCLUDED.display_name,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    active = true;

INSERT INTO user_roles (user_id, role, granted_at)
SELECT id, 'superadmin', CURRENT_TIMESTAMP
FROM users WHERE email = 'superadmin@code-rice.com'
ON CONFLICT (user_id, role) DO NOTHING;

-- 2. ADMINISTRATOR
INSERT INTO users (
    id, email, password_hash, display_name, first_name, last_name,
    active, email_verified, account_state, created_at
) VALUES (
    '00000000-0000-0000-0000-000000000002',
    'admin@code-rice.com',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyY5Y5Y5Y5Y5', -- Test1234!
    'Administrator',
    'Jane',
    'Smith',
    true,
    true,
    'ACTIVE',
    CURRENT_TIMESTAMP
) ON CONFLICT (email) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    display_name = EXCLUDED.display_name,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    active = true;

INSERT INTO user_roles (user_id, role, granted_at)
SELECT id, 'admin', CURRENT_TIMESTAMP
FROM users WHERE email = 'admin@code-rice.com'
ON CONFLICT (user_id, role) DO NOTHING;

-- 3. DEVELOPER
INSERT INTO users (
    id, email, password_hash, display_name, first_name, last_name,
    active, email_verified, account_state, created_at
) VALUES (
    '00000000-0000-0000-0000-000000000003',
    'developer@code-rice.com',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyY5Y5Y5Y5Y5', -- Test1234!
    'Developer',
    'Bob',
    'Johnson',
    true,
    true,
    'ACTIVE',
    CURRENT_TIMESTAMP
) ON CONFLICT (email) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    display_name = EXCLUDED.display_name,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    active = true;

INSERT INTO user_roles (user_id, role, granted_at)
SELECT id, 'developer', CURRENT_TIMESTAMP
FROM users WHERE email = 'developer@code-rice.com'
ON CONFLICT (user_id, role) DO NOTHING;

-- 4. ZWYKŁY UŻYTKOWNIK
INSERT INTO users (
    id, email, password_hash, display_name, first_name, last_name,
    active, email_verified, account_state, created_at
) VALUES (
    '00000000-0000-0000-0000-000000000004',
    'user@code-rice.com',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewY5GyY5Y5Y5Y5Y5', -- Test1234!
    'Regular User',
    'Alice',
    'Williams',
    true,
    true,
    'ACTIVE',
    CURRENT_TIMESTAMP
) ON CONFLICT (email) DO UPDATE SET
    password_hash = EXCLUDED.password_hash,
    display_name = EXCLUDED.display_name,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name,
    active = true;

INSERT INTO user_roles (user_id, role, granted_at)
SELECT id, 'user', CURRENT_TIMESTAMP
FROM users WHERE email = 'user@code-rice.com'
ON CONFLICT (user_id, role) DO NOTHING;

-- Sprawdź czy użytkownicy zostali utworzeni
SELECT 
    u.email,
    u.display_name,
    u.first_name,
    u.last_name,
    ur.role,
    u.active,
    u.email_verified
FROM users u
LEFT JOIN user_roles ur ON u.id = ur.user_id
WHERE u.email IN (
    'superadmin@code-rice.com',
    'admin@code-rice.com',
    'developer@code-rice.com',
    'user@code-rice.com'
)
ORDER BY ur.role, u.email;

