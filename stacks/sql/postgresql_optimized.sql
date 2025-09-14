-- =============================================================================
-- Chain Rice Database - PostgreSQL Specific Scripts
-- =============================================================================
-- This file contains PostgreSQL-specific SQL statements, optimizations, and features
-- for the Chain Rice e-commerce platform.
--
-- Database: PostgreSQL 14+
-- Version: 1.0.0
-- Author: Chain Rice Development Team
-- =============================================================================

-- =============================================================================
-- PostgreSQL Configuration and Setup
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";
CREATE EXTENSION IF NOT EXISTS "btree_gist";
CREATE EXTENSION IF NOT EXISTS "hstore";

-- Set PostgreSQL session variables for optimal performance
SET work_mem = '256MB';
SET maintenance_work_mem = '1GB';
SET effective_cache_size = '4GB';
SET random_page_cost = 1.1;
SET seq_page_cost = 1.0;

-- =============================================================================
-- PostgreSQL-Specific Data Types and Features
-- =============================================================================

-- Create optimized tables with PostgreSQL-specific features
CREATE TABLE IF NOT EXISTS pg_optimized_users (
    user_id BIGSERIAL PRIMARY KEY,
    user_uuid UUID DEFAULT uuid_generate_v4(),
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(20) CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
    avatar_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    email_verified_at TIMESTAMP WITH TIME ZONE,
    last_login_at TIMESTAMP WITH TIME ZONE,
    preferences HSTORE,  -- PostgreSQL hstore for flexible key-value storage
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- PostgreSQL-specific indexes
    CREATE INDEX idx_pg_users_email_trgm ON pg_optimized_users USING gin (email gin_trgm_ops),
    CREATE INDEX idx_pg_users_username_trgm ON pg_optimized_users USING gin (username gin_trgm_ops),
    CREATE INDEX idx_pg_users_active_created ON pg_optimized_users (is_active, created_at),
    CREATE INDEX idx_pg_users_last_login ON pg_optimized_users (last_login_at),
    CREATE INDEX idx_pg_users_uuid ON pg_optimized_users (user_uuid),
    
    -- PostgreSQL-specific constraints
    CONSTRAINT chk_email_format CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_username_length CHECK (char_length(username) >= 3),
    CONSTRAINT chk_phone_format CHECK (phone IS NULL OR phone ~ '^\+?[1-9]\d{1,14}$')
);

-- Create PostgreSQL-optimized products table with advanced features
CREATE TABLE IF NOT EXISTS pg_optimized_products (
    product_id BIGSERIAL PRIMARY KEY,
    product_uuid UUID DEFAULT uuid_generate_v4(),
    category_id BIGINT NOT NULL,
    brand_id BIGINT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_slug VARCHAR(255) NOT NULL UNIQUE,
    sku VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    short_description VARCHAR(500),
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    compare_price DECIMAL(10, 2) CHECK (compare_price IS NULL OR compare_price > price),
    cost_price DECIMAL(10, 2) CHECK (cost_price IS NULL OR cost_price >= 0),
    weight DECIMAL(8, 3) CHECK (weight IS NULL OR weight > 0),
    dimensions JSONB,  -- PostgreSQL JSONB for better performance
    specifications JSONB,
    tags TEXT[],  -- PostgreSQL array for tags
    inventory_tracking VARCHAR(20) DEFAULT 'product' CHECK (inventory_tracking IN ('none', 'product', 'variant')),
    inventory_quantity INTEGER DEFAULT 0 CHECK (inventory_quantity >= 0),
    low_stock_threshold INTEGER DEFAULT 5 CHECK (low_stock_threshold >= 0),
    allow_backorder BOOLEAN DEFAULT FALSE,
    is_digital BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    meta_title VARCHAR(255),
    meta_description VARCHAR(500),
    search_vector tsvector,  -- PostgreSQL full-text search vector
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- PostgreSQL-specific indexes
    CREATE INDEX idx_pg_products_category_active ON pg_optimized_products (category_id, is_active),
    CREATE INDEX idx_pg_products_brand_active ON pg_optimized_products (brand_id, is_active),
    CREATE INDEX idx_pg_products_slug_trgm ON pg_optimized_products USING gin (product_slug gin_trgm_ops),
    CREATE INDEX idx_pg_products_name_trgm ON pg_optimized_products USING gin (product_name gin_trgm_ops),
    CREATE INDEX idx_pg_products_price_range ON pg_optimized_products USING btree (price),
    CREATE INDEX idx_pg_products_inventory_status ON pg_optimized_products (inventory_quantity, is_active),
    CREATE INDEX idx_pg_products_featured_active ON pg_optimized_products (is_featured, is_active),
    CREATE INDEX idx_pg_products_created_at ON pg_optimized_products (created_at),
    CREATE INDEX idx_pg_products_uuid ON pg_optimized_products (product_uuid),
    
    -- JSONB indexes for PostgreSQL
    CREATE INDEX idx_pg_products_dimensions_weight ON pg_optimized_products USING gin ((dimensions->>'weight')),
    CREATE INDEX idx_pg_products_specs_color ON pg_optimized_products USING gin ((specifications->>'color')),
    
    -- Full-text search index
    CREATE INDEX idx_pg_products_search_vector ON pg_optimized_products USING gin (search_vector),
    
    -- Array indexes
    CREATE INDEX idx_pg_products_tags ON pg_optimized_products USING gin (tags)
);

-- =============================================================================
-- PostgreSQL-Specific Functions
-- =============================================================================

-- Function to automatically update search vector
CREATE OR REPLACE FUNCTION update_product_search_vector()
RETURNS TRIGGER AS $$
BEGIN
    NEW.search_vector := 
        setweight(to_tsvector('english', COALESCE(NEW.product_name, '')), 'A') ||
        setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'B') ||
        setweight(to_tsvector('english', COALESCE(NEW.short_description, '')), 'C') ||
        setweight(to_tsvector('english', COALESCE(array_to_string(NEW.tags, ' '), '')), 'D');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate product rating with PostgreSQL features
CREATE OR REPLACE FUNCTION calculate_product_rating(product_id_param BIGINT)
RETURNS DECIMAL(3, 2)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    avg_rating DECIMAL(3, 2) := 0.00;
BEGIN
    SELECT COALESCE(AVG(rating), 0.00) INTO avg_rating
    FROM product_reviews
    WHERE product_id = product_id_param
    AND is_approved = TRUE;
    
    RETURN avg_rating;
END;
$$;

-- Function to get product availability status
CREATE OR REPLACE FUNCTION get_product_availability(product_id_param BIGINT)
RETURNS VARCHAR(20)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    inventory_qty INTEGER;
    low_stock_threshold INTEGER;
    allow_backorder_val BOOLEAN;
BEGIN
    SELECT inventory_quantity, low_stock_threshold, allow_backorder
    INTO inventory_qty, low_stock_threshold, allow_backorder_val
    FROM pg_optimized_products
    WHERE product_id = product_id_param;
    
    IF inventory_qty > low_stock_threshold THEN
        RETURN 'In Stock';
    ELSIF inventory_qty > 0 THEN
        RETURN 'Low Stock';
    ELSIF allow_backorder_val THEN
        RETURN 'Backorder';
    ELSE
        RETURN 'Out of Stock';
    END IF;
END;
$$;

-- Function for advanced product search with PostgreSQL full-text search
CREATE OR REPLACE FUNCTION search_products(
    search_query TEXT,
    category_filter VARCHAR(100) DEFAULT NULL,
    brand_filter VARCHAR(100) DEFAULT NULL,
    price_min DECIMAL(10, 2) DEFAULT NULL,
    price_max DECIMAL(10, 2) DEFAULT NULL,
    tags_filter TEXT[] DEFAULT NULL,
    sort_by VARCHAR(50) DEFAULT 'relevance',
    sort_direction VARCHAR(4) DEFAULT 'DESC',
    page_offset INTEGER DEFAULT 0,
    page_limit INTEGER DEFAULT 20
)
RETURNS TABLE (
    product_id BIGINT,
    product_name VARCHAR(255),
    sku VARCHAR(100),
    price DECIMAL(10, 2),
    inventory_quantity INTEGER,
    is_featured BOOLEAN,
    category_name VARCHAR(100),
    brand_name VARCHAR(100),
    relevance_score REAL,
    availability_status VARCHAR(20)
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.product_id,
        p.product_name,
        p.sku,
        p.price,
        p.inventory_quantity,
        p.is_featured,
        c.category_name,
        b.brand_name,
        CASE 
            WHEN search_query IS NOT NULL AND search_query != '' THEN
                ts_rank(p.search_vector, plainto_tsquery('english', search_query))
            ELSE 0.0
        END as relevance_score,
        get_product_availability(p.product_id) as availability_status
    FROM pg_optimized_products p
    JOIN categories c ON p.category_id = c.category_id
    JOIN brands b ON p.brand_id = b.brand_id
    WHERE p.is_active = TRUE
    AND (search_query IS NULL OR search_query = '' OR p.search_vector @@ plainto_tsquery('english', search_query))
    AND (category_filter IS NULL OR c.category_slug = category_filter)
    AND (brand_filter IS NULL OR b.brand_slug = brand_filter)
    AND (price_min IS NULL OR p.price >= price_min)
    AND (price_max IS NULL OR p.price <= price_max)
    AND (tags_filter IS NULL OR p.tags && tags_filter)
    ORDER BY 
        CASE 
            WHEN sort_by = 'price' AND sort_direction = 'ASC' THEN p.price
        END ASC,
        CASE 
            WHEN sort_by = 'price' AND sort_direction = 'DESC' THEN p.price
        END DESC,
        CASE 
            WHEN sort_by = 'name' AND sort_direction = 'ASC' THEN p.product_name
        END ASC,
        CASE 
            WHEN sort_by = 'name' AND sort_direction = 'DESC' THEN p.product_name
        END DESC,
        CASE 
            WHEN sort_by = 'created' AND sort_direction = 'ASC' THEN p.created_at
        END ASC,
        CASE 
            WHEN sort_by = 'created' AND sort_direction = 'DESC' THEN p.created_at
        END DESC,
        CASE 
            WHEN sort_by = 'relevance' THEN relevance_score
        END DESC
    LIMIT page_limit OFFSET page_offset;
END;
$$;

-- =============================================================================
-- PostgreSQL-Specific Triggers
-- =============================================================================

-- Trigger to automatically update search vector
CREATE TRIGGER tr_product_search_vector_update
    BEFORE INSERT OR UPDATE ON pg_optimized_products
    FOR EACH ROW
    EXECUTE FUNCTION update_product_search_vector();

-- Trigger to log inventory changes with detailed tracking
CREATE OR REPLACE FUNCTION log_inventory_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.inventory_quantity IS DISTINCT FROM NEW.inventory_quantity THEN
        INSERT INTO inventory_change_log (
            product_id,
            old_quantity,
            new_quantity,
            change_amount,
            change_type,
            change_reason,
            created_at
        ) VALUES (
            NEW.product_id,
            OLD.inventory_quantity,
            NEW.inventory_quantity,
            NEW.inventory_quantity - OLD.inventory_quantity,
            CASE 
                WHEN NEW.inventory_quantity > OLD.inventory_quantity THEN 'INCREASE'
                WHEN NEW.inventory_quantity < OLD.inventory_quantity THEN 'DECREASE'
                ELSE 'NO_CHANGE'
            END,
            'automatic_update',
            CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_product_inventory_change_log
    AFTER UPDATE ON pg_optimized_products
    FOR EACH ROW
    EXECUTE FUNCTION log_inventory_changes();

-- =============================================================================
-- PostgreSQL-Specific Views
-- =============================================================================

-- View for product analytics with PostgreSQL-specific functions
CREATE VIEW pg_product_analytics AS
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    p.price,
    p.inventory_quantity,
    get_product_availability(p.product_id) as availability_status,
    calculate_product_rating(p.product_id) as avg_rating,
    c.category_name,
    b.brand_name,
    COALESCE(SUM(oi.total_price), 0) as total_revenue,
    COALESCE(SUM(oi.quantity), 0) as total_sold,
    COALESCE(COUNT(DISTINCT oi.order_id), 0) as order_count,
    COALESCE(AVG(oi.unit_price), 0) as avg_selling_price,
    p.tags,
    p.created_at,
    p.updated_at
FROM pg_optimized_products p
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status IN ('delivered', 'shipped')
GROUP BY p.product_id, p.product_name, p.sku, p.price, p.inventory_quantity, c.category_name, b.brand_name, p.tags, p.created_at, p.updated_at;

-- View for customer analytics with PostgreSQL window functions
CREATE VIEW pg_customer_analytics AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    u.created_at as customer_since,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.total_amount) as lifetime_value,
    AVG(o.total_amount) as avg_order_value,
    MAX(o.created_at) as last_order_date,
    EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - MAX(o.created_at))) as days_since_last_order,
    ROW_NUMBER() OVER (ORDER BY SUM(o.total_amount) DESC) as customer_rank,
    PERCENT_RANK() OVER (ORDER BY SUM(o.total_amount)) as customer_percentile,
    CASE 
        WHEN EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - MAX(o.created_at))) <= 30 THEN 'Active'
        WHEN EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - MAX(o.created_at))) <= 90 THEN 'At Risk'
        WHEN EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - MAX(o.created_at))) <= 180 THEN 'Inactive'
        ELSE 'Lost'
    END as customer_status
FROM pg_optimized_users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE u.is_active = TRUE
GROUP BY u.user_id, u.username, u.email, u.created_at;

-- =============================================================================
-- PostgreSQL Performance Optimization
-- =============================================================================

-- Create partial indexes for specific conditions
CREATE INDEX idx_pg_products_low_stock ON pg_optimized_products (inventory_quantity, product_id)
WHERE inventory_quantity <= 10;

CREATE INDEX idx_pg_products_featured_active ON pg_optimized_products (created_at DESC)
WHERE is_featured = TRUE AND is_active = TRUE;

-- Create expression indexes
CREATE INDEX idx_pg_products_price_discount ON pg_optimized_products ((price - COALESCE(compare_price, price)));

-- Create covering indexes for frequently accessed columns
CREATE INDEX idx_pg_products_covering ON pg_optimized_products (
    product_id, product_name, sku, price, inventory_quantity, is_active, is_featured
) INCLUDE (category_id, brand_id);

-- =============================================================================
-- PostgreSQL Monitoring and Maintenance
-- =============================================================================

-- Query to analyze table sizes and storage usage
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as index_size,
    pg_stat_get_tuples_returned(c.oid) as tuples_returned,
    pg_stat_get_tuples_fetched(c.oid) as tuples_fetched
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Query to identify slow queries
SELECT 
    query,
    calls,
    total_time,
    mean_time,
    rows,
    100.0 * shared_blks_hit / nullif(shared_blks_hit + shared_blks_read, 0) AS hit_percent
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY total_time DESC
LIMIT 10;

-- Query to check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch,
    idx_tup_read + idx_tup_fetch as total_usage
FROM pg_stat_user_indexes
ORDER BY total_usage DESC;

-- =============================================================================
-- PostgreSQL Backup and Recovery Procedures
-- =============================================================================

-- Function to create automated backup
CREATE OR REPLACE FUNCTION create_automated_backup()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    backup_file TEXT;
    backup_path TEXT;
    backup_command TEXT;
BEGIN
    backup_path := '/var/backups/postgresql/chain_rice/';
    backup_file := backup_path || 'chain_rice_backup_' || to_char(CURRENT_TIMESTAMP, 'YYYYMMDD_HH24MISS') || '.sql';
    
    -- Create backup using pg_dump (this would be called from application)
    backup_command := 'pg_dump --host=localhost --port=5432 --username=chain_rice --dbname=chain_rice --file=' || backup_file || ' --verbose --no-password';
    
    -- Log backup creation
    INSERT INTO backup_log (
        backup_type,
        backup_file,
        backup_size,
        created_at
    ) VALUES (
        'automated',
        backup_file,
        0, -- Size would be calculated after backup
        CURRENT_TIMESTAMP
    );
    
    RETURN 'Backup initiated: ' || backup_file;
END;
$$;

-- =============================================================================
-- PostgreSQL Advanced Features
-- =============================================================================

-- Create materialized view for product search performance
CREATE MATERIALIZED VIEW mv_product_search_cache AS
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    p.price,
    p.inventory_quantity,
    p.is_featured,
    c.category_name,
    b.brand_name,
    p.search_vector,
    p.tags,
    get_product_availability(p.product_id) as availability_status,
    calculate_product_rating(p.product_id) as avg_rating
FROM pg_optimized_products p
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
WHERE p.is_active = TRUE;

-- Create index on materialized view
CREATE INDEX idx_mv_product_search_vector ON mv_product_search_cache USING gin (search_vector);
CREATE INDEX idx_mv_product_tags ON mv_product_search_cache USING gin (tags);

-- Function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_product_search_cache()
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_product_search_cache;
END;
$$;

-- =============================================================================
-- End of PostgreSQL Specific Script
-- =============================================================================
