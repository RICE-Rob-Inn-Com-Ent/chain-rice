-- =============================================================================
-- Chain Rice PostgreSQL Database - AI Analytics Tables
-- =============================================================================
-- AI analysis and prediction tables for machine learning integration
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