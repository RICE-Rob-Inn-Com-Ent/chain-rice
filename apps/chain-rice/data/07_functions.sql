-- =============================================================================
-- Chain Rice PostgreSQL Database - Functions and Procedures
-- =============================================================================
-- Database functions for automated operations and data management
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

-- Trigger function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;