-- =============================================================================
-- Chain Rice PostgreSQL Database Setup
-- =============================================================================
-- Main setup script that creates database and runs all components
-- Version: 1.0.0
-- =============================================================================

-- Create database
CREATE DATABASE chain_rice
WITH
    ENCODING = 'UTF8' LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8' TEMPLATE = template0;

-- Connect to the database
\c chain_rice;

-- Run all database components in order
\i 01_extensions.sql
\i 02_validators.sql
\i 03_bitcoin.sql
\i 04_ai_analytics.sql
\i 05_indexes.sql
\i 06_views.sql
\i 07_functions.sql
\i 08_triggers.sql
\i 09_sample_data.sql
\i 10_comments.sql

-- Setup complete message
\echo '🍚 Chain Rice PostgreSQL database setup completed successfully!'
\echo 'Database: chain_rice'
\echo 'Tables created: validators, bitcoin_addresses, bitcoin_transactions, ai_analysis_results, ai_predictions, network_statistics'
\echo 'Views created: validator_overview, network_summary, bitcoin_balance_summary'
\echo 'Functions created: update_validator_stats(), record_validator_performance()'
\echo 'Sample data inserted for validators: alice, validator1, validator2'