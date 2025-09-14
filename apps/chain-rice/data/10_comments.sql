-- =============================================================================
-- Chain Rice PostgreSQL Database - Comments and Documentation
-- =============================================================================
-- Database and table comments for documentation
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