-- =============================================================================
-- Chain Rice PostgreSQL Database - Extensions
-- =============================================================================
-- Required PostgreSQL extensions for Chain Rice platform
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS "pg_trgm";

CREATE EXTENSION IF NOT EXISTS "btree_gin";

CREATE EXTENSION IF NOT EXISTS "btree_gist";