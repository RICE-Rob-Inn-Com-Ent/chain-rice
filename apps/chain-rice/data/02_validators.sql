-- =============================================================================
-- Chain Rice PostgreSQL Database - Validator Tables
-- =============================================================================
-- Core validator management tables and constraints
-- =============================================================================

-- Validators table
CREATE TABLE validators (
    validator_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL UNIQUE,
    bonded VARCHAR(50) NOT NULL,
    stake_amount BIGINT NOT NULL DEFAULT 0,
    token_balance BIGINT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'jailed', 'tombstoned')),
    commission_rate DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    uptime DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    voting_power DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    bitcoin_address VARCHAR(255),
    bitcoin_balance DECIMAL(18,8) NOT NULL DEFAULT 0.00000000,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_activity TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

-- Constraints
CONSTRAINT chk_stake_positive CHECK (stake_amount >= 0),
    CONSTRAINT chk_token_balance_positive CHECK (token_balance >= 0),
    CONSTRAINT chk_commission_rate CHECK (commission_rate >= 0 AND commission_rate <= 100),
    CONSTRAINT chk_uptime CHECK (uptime >= 0 AND uptime <= 100),
    CONSTRAINT chk_voting_power CHECK (voting_power >= 0 AND voting_power <= 100),
    CONSTRAINT chk_bitcoin_balance_positive CHECK (bitcoin_balance >= 0)
);

-- Validator performance history
CREATE TABLE validator_performance_history (
    performance_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    validator_id UUID NOT NULL REFERENCES validators(validator_id) ON DELETE CASCADE,
    uptime DECIMAL(5,2) NOT NULL,
    voting_power DECIMAL(5,2) NOT NULL,
    commission_rate DECIMAL(5,2) NOT NULL,
    stake_amount BIGINT NOT NULL,
    token_balance BIGINT NOT NULL,
    bitcoin_balance DECIMAL(18,8) NOT NULL,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

-- Constraints
CONSTRAINT chk_performance_uptime CHECK (uptime >= 0 AND uptime <= 100),
    CONSTRAINT chk_performance_voting_power CHECK (voting_power >= 0 AND voting_power <= 100),
    CONSTRAINT chk_performance_stake CHECK (stake_amount >= 0),
    CONSTRAINT chk_performance_tokens CHECK (token_balance >= 0),
    CONSTRAINT chk_performance_bitcoin CHECK (bitcoin_balance >= 0)
);