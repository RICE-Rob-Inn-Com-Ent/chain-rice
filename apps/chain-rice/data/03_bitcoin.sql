-- =============================================================================
-- Chain Rice PostgreSQL Database - Bitcoin Tables
-- =============================================================================
-- Bitcoin address and transaction management tables
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