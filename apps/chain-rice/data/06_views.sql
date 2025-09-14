-- =============================================================================
-- Chain Rice PostgreSQL Database - Views
-- =============================================================================
-- Pre-defined views for common queries and reporting
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