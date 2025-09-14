-- =============================================================================
-- Chain Rice PostgreSQL Database Schema
-- =============================================================================
-- Comprehensive database schema for Chain Rice blockchain platform
-- Includes validators, Bitcoin balances, transactions, and AI analytics
-- Version: 1.0.0
-- =============================================================================

-- Create database
CREATE DATABASE chain_rice
WITH
    ENCODING = 'UTF8' LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8' TEMPLATE = template0;

-- Connect to the database
\c chain_rice;

-- =============================================================================
-- Extensions
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS "pg_trgm";

CREATE EXTENSION IF NOT EXISTS "btree_gin";

CREATE EXTENSION IF NOT EXISTS "btree_gist";

-- =============================================================================
-- Validator Management Tables
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

-- =============================================================================
-- Bitcoin Management Tables
-- =============================================================================

-- Bitcoin addresses and balances
CREATE TABLE bitcoin_addresses (
    address_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    address VARCHAR(255) NOT NULL UNIQUE,
    validator_id UUID REFERENCES validators(validator_id) ON DELETE SET NULL,
    balance_btc DECIMAL(18,8) NOT NULL DEFAULT 0.00000000,
    balance_satoshis BIGINT NOT NULL DEFAULT 0,
    usd_value DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    confirmations INTEGER NOT NULL DEFAULT 0,
    transaction_count INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

-- Constraints
CONSTRAINT chk_bitcoin_balance_btc CHECK (balance_btc >= 0),
    CONSTRAINT chk_bitcoin_balance_satoshis CHECK (balance_satoshis >= 0),
    CONSTRAINT chk_bitcoin_usd_value CHECK (usd_value >= 0),
    CONSTRAINT chk_bitcoin_confirmations CHECK (confirmations >= 0),
    CONSTRAINT chk_bitcoin_transaction_count CHECK (transaction_count >= 0)
);

-- Bitcoin transactions
CREATE TABLE bitcoin_transactions (
    transaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tx_hash VARCHAR(255) NOT NULL UNIQUE,
    address_id UUID NOT NULL REFERENCES bitcoin_addresses(address_id) ON DELETE CASCADE,
    validator_id UUID REFERENCES validators(validator_id) ON DELETE SET NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('send', 'receive', 'mining', 'fee')),
    amount_btc DECIMAL(18,8) NOT NULL,
    amount_satoshis BIGINT NOT NULL,
    fee_btc DECIMAL(18,8) NOT NULL DEFAULT 0.00000000,
    fee_satoshis BIGINT NOT NULL DEFAULT 0,
    confirmations INTEGER NOT NULL DEFAULT 0,
    block_height BIGINT,
    block_hash VARCHAR(255),
    transaction_time TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

-- Constraints
CONSTRAINT chk_tx_amount_btc CHECK (amount_btc != 0),
    CONSTRAINT chk_tx_amount_satoshis CHECK (amount_satoshis != 0),
    CONSTRAINT chk_tx_fee_btc CHECK (fee_btc >= 0),
    CONSTRAINT chk_tx_fee_satoshis CHECK (fee_satoshis >= 0),
    CONSTRAINT chk_tx_confirmations CHECK (confirmations >= 0)
);

-- Bitcoin price history
CREATE TABLE bitcoin_price_history (
    price_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    price_usd DECIMAL(10,2) NOT NULL,
    price_btc DECIMAL(18,8) NOT NULL DEFAULT 1.00000000,
    market_cap_usd BIGINT,
    volume_24h_usd BIGINT,
    price_change_24h DECIMAL(8,4),
    price_change_percentage_24h DECIMAL(8,4),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

-- Constraints
CONSTRAINT chk_price_usd CHECK (price_usd > 0),
    CONSTRAINT chk_price_btc CHECK (price_btc > 0),
    CONSTRAINT chk_market_cap CHECK (market_cap_usd >= 0),
    CONSTRAINT chk_volume_24h CHECK (volume_24h_usd >= 0)
);

-- =============================================================================
-- AI Analytics Tables
-- =============================================================================

-- AI analysis results
CREATE TABLE ai_analysis_results (
    analysis_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    analysis_type VARCHAR(50) NOT NULL,
    target_id UUID, -- Can reference validator_id or other entities
    target_type VARCHAR(50), -- 'validator', 'network', 'bitcoin', etc.
    analysis_data JSONB NOT NULL,
    confidence_score DECIMAL(3,2), -- 0.00 to 1.00
    model_version VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

-- Constraints
CONSTRAINT chk_confidence_score CHECK (confidence_score >= 0 AND confidence_score <= 1)
);

-- AI predictions
CREATE TABLE ai_predictions (
    prediction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    prediction_type VARCHAR(50) NOT NULL,
    target_id UUID,
    target_type VARCHAR(50),
    prediction_data JSONB NOT NULL,
    confidence_score DECIMAL(3,2),
    prediction_horizon INTEGER, -- Days ahead
    model_version VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE,

-- Constraints
CONSTRAINT chk_prediction_confidence CHECK (confidence_score >= 0 AND confidence_score <= 1),
    CONSTRAINT chk_prediction_horizon CHECK (prediction_horizon > 0)
);

-- =============================================================================
-- Network Statistics Tables
-- =============================================================================

-- Network statistics
CREATE TABLE network_statistics (
    stats_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    total_validators INTEGER NOT NULL DEFAULT 0,
    active_validators INTEGER NOT NULL DEFAULT 0,
    total_stake BIGINT NOT NULL DEFAULT 0,
    total_tokens BIGINT NOT NULL DEFAULT 0,
    network_uptime DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    total_bitcoin_balance DECIMAL(18,8) NOT NULL DEFAULT 0.00000000,
    bitcoin_usd_value DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    bitcoin_price_change_24h DECIMAL(8,4) NOT NULL DEFAULT 0.0000,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

-- Constraints
CONSTRAINT chk_stats_validators CHECK (total_validators >= 0 AND active_validators >= 0),
    CONSTRAINT chk_stats_stake CHECK (total_stake >= 0),
    CONSTRAINT chk_stats_tokens CHECK (total_tokens >= 0),
    CONSTRAINT chk_stats_uptime CHECK (network_uptime >= 0 AND network_uptime <= 100),
    CONSTRAINT chk_stats_bitcoin_balance CHECK (total_bitcoin_balance >= 0),
    CONSTRAINT chk_stats_bitcoin_usd CHECK (bitcoin_usd_value >= 0)
);

-- =============================================================================
-- Indexes for Performance Optimization
-- =============================================================================

-- Validator indexes
CREATE INDEX idx_validators_name ON validators (name);

CREATE INDEX idx_validators_status ON validators (status);

CREATE INDEX idx_validators_stake_amount ON validators (stake_amount DESC);

CREATE INDEX idx_validators_bitcoin_balance ON validators (bitcoin_balance DESC);

CREATE INDEX idx_validators_voting_power ON validators (voting_power DESC);

CREATE INDEX idx_validators_created_at ON validators (created_at);

-- Validator performance history indexes
CREATE INDEX idx_validator_performance_validator_id ON validator_performance_history (validator_id);

CREATE INDEX idx_validator_performance_recorded_at ON validator_performance_history (recorded_at);

CREATE INDEX idx_validator_performance_uptime ON validator_performance_history (uptime);

-- Bitcoin addresses indexes
CREATE INDEX idx_bitcoin_addresses_address ON bitcoin_addresses (address);

CREATE INDEX idx_bitcoin_addresses_validator_id ON bitcoin_addresses (validator_id);

CREATE INDEX idx_bitcoin_addresses_balance_btc ON bitcoin_addresses (balance_btc DESC);

CREATE INDEX idx_bitcoin_addresses_usd_value ON bitcoin_addresses (usd_value DESC);

CREATE INDEX idx_bitcoin_addresses_is_active ON bitcoin_addresses (is_active);

-- Bitcoin transactions indexes
CREATE INDEX idx_bitcoin_transactions_tx_hash ON bitcoin_transactions (tx_hash);

CREATE INDEX idx_bitcoin_transactions_address_id ON bitcoin_transactions (address_id);

CREATE INDEX idx_bitcoin_transactions_validator_id ON bitcoin_transactions (validator_id);

CREATE INDEX idx_bitcoin_transactions_type ON bitcoin_transactions (transaction_type);

CREATE INDEX idx_bitcoin_transactions_time ON bitcoin_transactions (transaction_time);

CREATE INDEX idx_bitcoin_transactions_block_height ON bitcoin_transactions (block_height);

-- Bitcoin price history indexes
CREATE INDEX idx_bitcoin_price_recorded_at ON bitcoin_price_history (recorded_at);

CREATE INDEX idx_bitcoin_price_usd ON bitcoin_price_history (price_usd);

-- AI analytics indexes
CREATE INDEX idx_ai_analysis_type ON ai_analysis_results (analysis_type);

CREATE INDEX idx_ai_analysis_target_id ON ai_analysis_results (target_id);

CREATE INDEX idx_ai_analysis_target_type ON ai_analysis_results (target_type);

CREATE INDEX idx_ai_analysis_created_at ON ai_analysis_results (created_at);

-- AI predictions indexes
CREATE INDEX idx_ai_predictions_type ON ai_predictions (prediction_type);

CREATE INDEX idx_ai_predictions_target_id ON ai_predictions (target_id);

CREATE INDEX idx_ai_predictions_created_at ON ai_predictions (created_at);

CREATE INDEX idx_ai_predictions_expires_at ON ai_predictions (expires_at);

-- Network statistics indexes
CREATE INDEX idx_network_stats_recorded_at ON network_statistics (recorded_at);

-- =============================================================================
-- Views for Common Queries
-- =============================================================================

-- Validator overview view
CREATE VIEW validator_overview AS
SELECT
    v.validator_id,
    v.name,
    v.bonded,
    v.stake_amount,
    v.token_balance,
    v.status,
    v.commission_rate,
    v.uptime,
    v.voting_power,
    v.bitcoin_balance,
    v.bitcoin_address,
    ba.usd_value as bitcoin_usd_value,
    v.last_activity,
    v.created_at,
    v.updated_at
FROM
    validators v
    LEFT JOIN bitcoin_addresses ba ON v.validator_id = ba.validator_id
    AND ba.is_active = TRUE;

-- Network summary view
CREATE VIEW network_summary AS
SELECT
    COUNT(*) as total_validators,
    COUNT(
        CASE
            WHEN status = 'active' THEN 1
        END
    ) as active_validators,
    SUM(stake_amount) as total_stake,
    SUM(token_balance) as total_tokens,
    AVG(uptime) as avg_uptime,
    SUM(bitcoin_balance) as total_bitcoin_balance,
    SUM(ba.usd_value) as total_bitcoin_usd_value
FROM
    validators v
    LEFT JOIN bitcoin_addresses ba ON v.validator_id = ba.validator_id
    AND ba.is_active = TRUE;

-- Bitcoin balance summary view
CREATE VIEW bitcoin_balance_summary AS
SELECT ba.address, v.name as validator_name, ba.balance_btc, ba.balance_satoshis, ba.usd_value, ba.confirmations, ba.transaction_count, ba.updated_at
FROM
    bitcoin_addresses ba
    LEFT JOIN validators v ON ba.validator_id = v.validator_id
WHERE
    ba.is_active = TRUE
ORDER BY ba.usd_value DESC;

-- =============================================================================
-- Functions and Procedures
-- =============================================================================

-- Function to update validator statistics
CREATE OR REPLACE FUNCTION update_validator_stats()
RETURNS VOID AS $$
BEGIN
    INSERT INTO network_statistics (
        total_validators,
        active_validators,
        total_stake,
        total_tokens,
        network_uptime,
        total_bitcoin_balance,
        bitcoin_usd_value
    )
    SELECT 
        COUNT(*),
        COUNT(CASE WHEN status = 'active' THEN 1 END),
        SUM(stake_amount),
        SUM(token_balance),
        AVG(uptime),
        SUM(bitcoin_balance),
        SUM(ba.usd_value)
    FROM validators v
    LEFT JOIN bitcoin_addresses ba ON v.validator_id = ba.validator_id AND ba.is_active = TRUE;
END;
$$ LANGUAGE plpgsql;

-- Function to record validator performance history
CREATE OR REPLACE FUNCTION record_validator_performance(p_validator_id UUID)
RETURNS VOID AS $$
BEGIN
    INSERT INTO validator_performance_history (
        validator_id,
        uptime,
        voting_power,
        commission_rate,
        stake_amount,
        token_balance,
        bitcoin_balance
    )
    SELECT 
        validator_id,
        uptime,
        voting_power,
        commission_rate,
        stake_amount,
        token_balance,
        bitcoin_balance
    FROM validators
    WHERE validator_id = p_validator_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Triggers
-- =============================================================================

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to relevant tables
CREATE TRIGGER update_validators_updated_at
    BEFORE UPDATE ON validators
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bitcoin_addresses_updated_at
    BEFORE UPDATE ON bitcoin_addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- Sample Data Insertion
-- =============================================================================

-- Insert sample validators based on config.yml
INSERT INTO
    validators (
        name,
        bonded,
        stake_amount,
        token_balance,
        status,
        commission_rate,
        uptime,
        voting_power,
        bitcoin_address,
        bitcoin_balance
    )
VALUES (
        'alice',
        '100000000stake',
        100000000,
        20000,
        'active',
        5.0,
        99.8,
        25.0,
        'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
        0.12500000
    ),
    (
        'validator1',
        '200000000stake',
        200000000,
        10000,
        'active',
        3.5,
        99.9,
        50.0,
        'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4',
        0.25000000
    ),
    (
        'validator2',
        '100000000stake',
        100000000,
        15000,
        'active',
        4.2,
        99.7,
        25.0,
        'bc1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qccfmv3',
        0.07500000
    );

-- Insert corresponding bitcoin addresses
INSERT INTO
    bitcoin_addresses (
        address,
        validator_id,
        balance_btc,
        balance_satoshis,
        usd_value,
        confirmations,
        transaction_count
    )
VALUES (
        'bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh',
        (
            SELECT validator_id
            FROM validators
            WHERE
                name = 'alice'
        ),
        0.12500000,
        12500000,
        1875.00,
        6,
        15
    ),
    (
        'bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4',
        (
            SELECT validator_id
            FROM validators
            WHERE
                name = 'validator1'
        ),
        0.25000000,
        25000000,
        3750.00,
        6,
        23
    ),
    (
        'bc1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3qccfmv3',
        (
            SELECT validator_id
            FROM validators
            WHERE
                name = 'validator2'
        ),
        0.07500000,
        7500000,
        1125.00,
        6,
        8
    );

-- Insert initial network statistics
SELECT update_validator_stats ();

-- =============================================================================
-- Comments and Documentation
-- =============================================================================

COMMENT ON DATABASE chain_rice IS 'Chain Rice blockchain platform database with validator management and Bitcoin integration';

COMMENT ON
TABLE validators IS 'Core validator information and performance metrics';

COMMENT ON
TABLE bitcoin_addresses IS 'Bitcoin addresses and current balances for validators';

COMMENT ON
TABLE bitcoin_transactions IS 'Historical Bitcoin transactions for all addresses';

COMMENT ON
TABLE ai_analysis_results IS 'AI-powered analysis results for various entities';

COMMENT ON
TABLE ai_predictions IS 'AI predictions for future trends and events';

COMMENT ON
TABLE network_statistics IS 'Network-wide statistics and metrics';

-- =============================================================================
-- Grant Permissions (adjust as needed for your environment)
-- =============================================================================

-- Create application user
-- CREATE USER chain_rice_app WITH PASSWORD 'your_secure_password';
-- GRANT CONNECT ON DATABASE chain_rice TO chain_rice_app;
-- GRANT USAGE ON SCHEMA public TO chain_rice_app;
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO chain_rice_app;
-- GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO chain_rice_app;

-- =============================================================================
-- Database Setup Complete
-- =============================================================================

\echo 'Chain Rice PostgreSQL database setup completed successfully!'
\echo 'Database: chain_rice'
\echo 'Tables created: validators, bitcoin_addresses, bitcoin_transactions, ai_analysis_results, ai_predictions, network_statistics'
\echo 'Views created: validator_overview, network_summary, bitcoin_balance_summary'
\echo 'Functions created: update_validator_stats(), record_validator_performance()'
\echo 'Sample data inserted for validators: alice, validator1, validator2'