-- =============================================================================
-- Chain Rice PostgreSQL Database - Triggers
-- =============================================================================
-- Database triggers for automated data management
-- =============================================================================

-- Apply triggers to relevant tables
CREATE TRIGGER update_validators_updated_at
    BEFORE UPDATE ON validators
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_bitcoin_addresses_updated_at
    BEFORE UPDATE ON bitcoin_addresses
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();