-- =============================================================================
-- Chain Rice Database - SQLite Specific Scripts
-- =============================================================================
-- This file contains SQLite-specific SQL statements, optimizations, and features
-- for the Chain Rice e-commerce platform.
--
-- Database: SQLite 3.35+
-- Version: 1.0.0
-- Author: Chain Rice Development Team
-- =============================================================================

-- =============================================================================
-- SQLite Configuration and Setup
-- =============================================================================

-- Enable SQLite pragmas for optimal performance
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = 10000;
PRAGMA temp_store = MEMORY;
PRAGMA mmap_size = 268435456;  -- 256MB
PRAGMA optimize;

-- =============================================================================
-- SQLite-Specific Data Types and Features
-- =============================================================================

-- Create optimized tables with SQLite-specific features
CREATE TABLE IF NOT EXISTS sqlite_optimized_users (
    user_id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    email TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    date_of_birth TEXT,  -- SQLite stores dates as TEXT
    gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
    avatar_url TEXT,
    is_active INTEGER DEFAULT 1,  -- SQLite uses INTEGER for boolean
    is_verified INTEGER DEFAULT 0,
    email_verified_at TEXT,
    last_login_at TEXT,
    preferences TEXT,  -- JSON string for preferences
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    
    -- SQLite-specific constraints
    CHECK (length(username) >= 3),
    CHECK (email LIKE '%@%.%'),
    CHECK (phone IS NULL OR phone GLOB '+[0-9]*' OR phone GLOB '[0-9]*')
);

-- Create SQLite-optimized products table
CREATE TABLE IF NOT EXISTS sqlite_optimized_products (
    product_id INTEGER PRIMARY KEY AUTOINCREMENT,
    category_id INTEGER NOT NULL,
    brand_id INTEGER NOT NULL,
    product_name TEXT NOT NULL,
    product_slug TEXT NOT NULL UNIQUE,
    sku TEXT NOT NULL UNIQUE,
    description TEXT,
    short_description TEXT,
    price REAL NOT NULL CHECK (price > 0),
    compare_price REAL CHECK (compare_price IS NULL OR compare_price > price),
    cost_price REAL CHECK (cost_price IS NULL OR cost_price >= 0),
    weight REAL CHECK (weight IS NULL OR weight > 0),
    dimensions TEXT,  -- JSON string
    specifications TEXT,  -- JSON string
    tags TEXT,  -- JSON array as string
    inventory_tracking TEXT DEFAULT 'product' CHECK (inventory_tracking IN ('none', 'product', 'variant')),
    inventory_quantity INTEGER DEFAULT 0 CHECK (inventory_quantity >= 0),
    low_stock_threshold INTEGER DEFAULT 5 CHECK (low_stock_threshold >= 0),
    allow_backorder INTEGER DEFAULT 0,
    is_digital INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    is_featured INTEGER DEFAULT 0,
    meta_title TEXT,
    meta_description TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    
    -- SQLite-specific constraints
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    FOREIGN KEY (brand_id) REFERENCES brands(brand_id)
);

-- =============================================================================
-- SQLite-Specific Indexes
-- =============================================================================

-- Create optimized indexes for SQLite
CREATE INDEX IF NOT EXISTS idx_sqlite_users_email ON sqlite_optimized_users(email);
CREATE INDEX IF NOT EXISTS idx_sqlite_users_username ON sqlite_optimized_users(username);
CREATE INDEX IF NOT EXISTS idx_sqlite_users_active_created ON sqlite_optimized_users(is_active, created_at);
CREATE INDEX IF NOT EXISTS idx_sqlite_users_last_login ON sqlite_optimized_users(last_login_at);

CREATE INDEX IF NOT EXISTS idx_sqlite_products_category_active ON sqlite_optimized_products(category_id, is_active);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_brand_active ON sqlite_optimized_products(brand_id, is_active);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_slug ON sqlite_optimized_products(product_slug);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_sku ON sqlite_optimized_products(sku);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_price_range ON sqlite_optimized_products(price);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_inventory_status ON sqlite_optimized_products(inventory_quantity, is_active);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_featured_active ON sqlite_optimized_products(is_featured, is_active);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_created_at ON sqlite_optimized_products(created_at);

-- Partial indexes for SQLite (using WHERE clause)
CREATE INDEX IF NOT EXISTS idx_sqlite_products_low_stock ON sqlite_optimized_products(inventory_quantity, product_id) 
WHERE inventory_quantity <= 10;

CREATE INDEX IF NOT EXISTS idx_sqlite_products_featured_active_partial ON sqlite_optimized_products(created_at DESC) 
WHERE is_featured = 1 AND is_active = 1;

-- =============================================================================
-- SQLite-Specific Triggers
-- =============================================================================

-- Trigger to automatically update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS tr_sqlite_users_updated_at
    AFTER UPDATE ON sqlite_optimized_users
    FOR EACH ROW
BEGIN
    UPDATE sqlite_optimized_users 
    SET updated_at = datetime('now')
    WHERE user_id = NEW.user_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_sqlite_products_updated_at
    AFTER UPDATE ON sqlite_optimized_products
    FOR EACH ROW
BEGIN
    UPDATE sqlite_optimized_products 
    SET updated_at = datetime('now')
    WHERE product_id = NEW.product_id;
END;

-- Trigger to log inventory changes
CREATE TRIGGER IF NOT EXISTS tr_sqlite_products_inventory_log
    AFTER UPDATE ON sqlite_optimized_products
    FOR EACH ROW
    WHEN OLD.inventory_quantity IS NOT NEW.inventory_quantity
BEGIN
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
        datetime('now')
    );
END;

-- =============================================================================
-- SQLite-Specific Functions (Using Views and Triggers)
-- =============================================================================

-- Create a view for product availability status
CREATE VIEW IF NOT EXISTS v_product_availability AS
SELECT 
    product_id,
    product_name,
    inventory_quantity,
    low_stock_threshold,
    allow_backorder,
    CASE 
        WHEN inventory_quantity > low_stock_threshold THEN 'In Stock'
        WHEN inventory_quantity > 0 THEN 'Low Stock'
        WHEN allow_backorder = 1 THEN 'Backorder'
        ELSE 'Out of Stock'
    END as availability_status
FROM sqlite_optimized_products;

-- Create a view for product ratings (simulating function)
CREATE VIEW IF NOT EXISTS v_product_ratings AS
SELECT 
    p.product_id,
    p.product_name,
    COALESCE(AVG(pr.rating), 0.0) as avg_rating,
    COUNT(pr.rating) as rating_count
FROM sqlite_optimized_products p
LEFT JOIN product_reviews pr ON p.product_id = pr.product_id AND pr.is_approved = 1
GROUP BY p.product_id, p.product_name;

-- =============================================================================
-- SQLite-Specific Views
-- =============================================================================

-- View for product analytics optimized for SQLite
CREATE VIEW IF NOT EXISTS sqlite_product_analytics AS
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    p.price,
    p.inventory_quantity,
    va.availability_status,
    vr.avg_rating,
    vr.rating_count,
    c.category_name,
    b.brand_name,
    COALESCE(SUM(oi.total_price), 0) as total_revenue,
    COALESCE(SUM(oi.quantity), 0) as total_sold,
    COALESCE(COUNT(DISTINCT oi.order_id), 0) as order_count,
    COALESCE(AVG(oi.unit_price), 0) as avg_selling_price,
    p.created_at,
    p.updated_at
FROM sqlite_optimized_products p
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
LEFT JOIN v_product_availability va ON p.product_id = va.product_id
LEFT JOIN v_product_ratings vr ON p.product_id = vr.product_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status IN ('delivered', 'shipped')
GROUP BY p.product_id, p.product_name, p.sku, p.price, p.inventory_quantity, 
         va.availability_status, vr.avg_rating, vr.rating_count, c.category_name, 
         b.brand_name, p.created_at, p.updated_at;

-- View for customer analytics optimized for SQLite
CREATE VIEW IF NOT EXISTS sqlite_customer_analytics AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    u.created_at as customer_since,
    COUNT(DISTINCT o.order_id) as total_orders,
    COALESCE(SUM(o.total_amount), 0) as lifetime_value,
    COALESCE(AVG(o.total_amount), 0) as avg_order_value,
    MAX(o.created_at) as last_order_date,
    CASE 
        WHEN MAX(o.created_at) IS NOT NULL THEN 
            CAST((julianday('now') - julianday(MAX(o.created_at))) AS INTEGER)
        ELSE NULL
    END as days_since_last_order,
    CASE 
        WHEN MAX(o.created_at) IS NOT NULL AND 
             CAST((julianday('now') - julianday(MAX(o.created_at))) AS INTEGER) <= 30 THEN 'Active'
        WHEN MAX(o.created_at) IS NOT NULL AND 
             CAST((julianday('now') - julianday(MAX(o.created_at))) AS INTEGER) <= 90 THEN 'At Risk'
        WHEN MAX(o.created_at) IS NOT NULL AND 
             CAST((julianday('now') - julianday(MAX(o.created_at))) AS INTEGER) <= 180 THEN 'Inactive'
        ELSE 'Lost'
    END as customer_status
FROM sqlite_optimized_users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE u.is_active = 1
GROUP BY u.user_id, u.username, u.email, u.created_at;

-- =============================================================================
-- SQLite Performance Optimization Queries
-- =============================================================================

-- Query to analyze database size and performance
SELECT 
    name as table_name,
    sql as table_sql,
    (SELECT COUNT(*) FROM sqlite_master WHERE type = 'index' AND tbl_name = name) as index_count
FROM sqlite_master 
WHERE type = 'table' 
AND name NOT LIKE 'sqlite_%'
ORDER BY name;

-- Query to get table sizes (approximate)
SELECT 
    name as table_name,
    (SELECT COUNT(*) FROM sqlite_master WHERE type = 'index' AND tbl_name = name) as index_count,
    'Run: SELECT COUNT(*) FROM ' || name || ';' as row_count_query
FROM sqlite_master 
WHERE type = 'table' 
AND name NOT LIKE 'sqlite_%'
ORDER BY name;

-- Query to check index usage (SQLite 3.32+)
SELECT 
    name as index_name,
    tbl_name as table_name,
    sql as index_sql
FROM sqlite_master 
WHERE type = 'index' 
AND name NOT LIKE 'sqlite_%'
ORDER BY tbl_name, name;

-- =============================================================================
-- SQLite Backup and Maintenance
-- =============================================================================

-- Create backup table for critical data
CREATE TABLE IF NOT EXISTS backup_users AS 
SELECT * FROM sqlite_optimized_users WHERE 0;  -- Empty table with same structure

CREATE TABLE IF NOT EXISTS backup_products AS 
SELECT * FROM sqlite_optimized_products WHERE 0;

-- Function to backup critical tables (using triggers)
CREATE TRIGGER IF NOT EXISTS tr_backup_users_insert
    AFTER INSERT ON sqlite_optimized_users
    FOR EACH ROW
BEGIN
    INSERT INTO backup_users SELECT * FROM sqlite_optimized_users WHERE user_id = NEW.user_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_backup_users_update
    AFTER UPDATE ON sqlite_optimized_users
    FOR EACH ROW
BEGIN
    UPDATE backup_users SET 
        username = NEW.username,
        email = NEW.email,
        password_hash = NEW.password_hash,
        first_name = NEW.first_name,
        last_name = NEW.last_name,
        phone = NEW.phone,
        date_of_birth = NEW.date_of_birth,
        gender = NEW.gender,
        avatar_url = NEW.avatar_url,
        is_active = NEW.is_active,
        is_verified = NEW.is_verified,
        email_verified_at = NEW.email_verified_at,
        last_login_at = NEW.last_login_at,
        preferences = NEW.preferences,
        created_at = NEW.created_at,
        updated_at = NEW.updated_at
    WHERE user_id = NEW.user_id;
END;

-- =============================================================================
-- SQLite Advanced Features
-- =============================================================================

-- Create FTS (Full-Text Search) virtual table for products
CREATE VIRTUAL TABLE IF NOT EXISTS fts_products USING fts5(
    product_id,
    product_name,
    description,
    short_description,
    tags,
    content='sqlite_optimized_products',
    content_rowid='product_id'
);

-- Create triggers to maintain FTS table
CREATE TRIGGER IF NOT EXISTS tr_fts_products_insert
    AFTER INSERT ON sqlite_optimized_products
    FOR EACH ROW
BEGIN
    INSERT INTO fts_products(product_id, product_name, description, short_description, tags)
    VALUES(NEW.product_id, NEW.product_name, NEW.description, NEW.short_description, NEW.tags);
END;

CREATE TRIGGER IF NOT EXISTS tr_fts_products_update
    AFTER UPDATE ON sqlite_optimized_products
    FOR EACH ROW
BEGIN
    UPDATE fts_products SET 
        product_name = NEW.product_name,
        description = NEW.description,
        short_description = NEW.short_description,
        tags = NEW.tags
    WHERE product_id = NEW.product_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_fts_products_delete
    AFTER DELETE ON sqlite_optimized_products
    FOR EACH ROW
BEGIN
    DELETE FROM fts_products WHERE product_id = OLD.product_id;
END;

-- =============================================================================
-- SQLite Utility Functions
-- =============================================================================

-- Create a view for database statistics
CREATE VIEW IF NOT EXISTS v_database_stats AS
SELECT 
    'Users' as table_name,
    (SELECT COUNT(*) FROM sqlite_optimized_users) as row_count,
    (SELECT COUNT(*) FROM sqlite_optimized_users WHERE is_active = 1) as active_count
UNION ALL
SELECT 
    'Products' as table_name,
    (SELECT COUNT(*) FROM sqlite_optimized_products) as row_count,
    (SELECT COUNT(*) FROM sqlite_optimized_products WHERE is_active = 1) as active_count
UNION ALL
SELECT 
    'Orders' as table_name,
    (SELECT COUNT(*) FROM orders) as row_count,
    (SELECT COUNT(*) FROM orders WHERE status IN ('delivered', 'shipped')) as active_count;

-- Create a view for inventory alerts
CREATE VIEW IF NOT EXISTS v_inventory_alerts AS
SELECT 
    product_id,
    product_name,
    sku,
    inventory_quantity,
    low_stock_threshold,
    CASE 
        WHEN inventory_quantity = 0 THEN 'Out of Stock'
        WHEN inventory_quantity <= low_stock_threshold THEN 'Low Stock'
        ELSE 'In Stock'
    END as alert_level,
    created_at
FROM sqlite_optimized_products
WHERE inventory_quantity <= low_stock_threshold
ORDER BY inventory_quantity ASC;

-- =============================================================================
-- SQLite Maintenance Procedures
-- =============================================================================

-- Analyze and optimize database
ANALYZE;

-- Vacuum database to reclaim space
VACUUM;

-- Reindex all indexes
REINDEX;

-- =============================================================================
-- End of SQLite Specific Script
-- =============================================================================
