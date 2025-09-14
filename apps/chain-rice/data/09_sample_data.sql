-- =============================================================================
-- Chain Rice PostgreSQL Database - Sample Data
-- =============================================================================
-- Sample data insertion based on config.yml validators
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