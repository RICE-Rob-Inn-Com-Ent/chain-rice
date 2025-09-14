-- =============================================================================
-- Chain Rice PostgreSQL Database - Indexes
-- =============================================================================
-- Performance optimization indexes for all tables
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