-- =============================================================================
-- SQLite E-commerce Database - Middle Average Implementation
-- =============================================================================
-- This file demonstrates SQLite-specific features and optimizations for a
-- middle-average e-commerce database implementation.
--
-- Database: SQLite 3.35+
-- Features: FTS5, Partial Indexes, JSON Functions, Virtual Tables
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
-- Core Tables with SQLite Features
-- =============================================================================

-- Users table with SQLite-specific optimizations
CREATE TABLE users (
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
    tags TEXT,  -- JSON array as string
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    
    -- SQLite-specific constraints
    CHECK (length(username) >= 3),
    CHECK (email LIKE '%@%.%'),
    CHECK (phone IS NULL OR phone GLOB '+[0-9]*' OR phone GLOB '[0-9]*')
);

-- Products table with SQLite features
CREATE TABLE products (
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

-- Categories table with hierarchical structure
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY AUTOINCREMENT,
    parent_category_id INTEGER NULL,
    category_name TEXT NOT NULL,
    category_slug TEXT NOT NULL UNIQUE,
    description TEXT,
    image_url TEXT,
    sort_order INTEGER DEFAULT 0,
    is_active INTEGER DEFAULT 1,
    meta_title TEXT,
    meta_description TEXT,
    category_path TEXT,  -- Will be populated by trigger
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    
    -- Self-referencing foreign key for hierarchy
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id),
    
    -- SQLite-specific constraints
    CHECK (length(category_name) >= 2)
);

-- Brands table
CREATE TABLE brands (
    brand_id INTEGER PRIMARY KEY AUTOINCREMENT,
    brand_name TEXT NOT NULL UNIQUE,
    brand_slug TEXT NOT NULL UNIQUE,
    description TEXT,
    logo_url TEXT,
    website_url TEXT,
    is_active INTEGER DEFAULT 1,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now'))
);

-- Orders table with SQLite features
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    order_number TEXT NOT NULL UNIQUE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded')),
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded', 'partially_refunded')),
    shipping_status TEXT DEFAULT 'pending' CHECK (shipping_status IN ('pending', 'shipped', 'delivered', 'returned')),
    subtotal REAL NOT NULL CHECK (subtotal >= 0),
    tax_amount REAL DEFAULT 0 CHECK (tax_amount >= 0),
    shipping_amount REAL DEFAULT 0 CHECK (shipping_amount >= 0),
    discount_amount REAL DEFAULT 0 CHECK (discount_amount >= 0),
    total_amount REAL NOT NULL CHECK (total_amount >= 0),
    currency TEXT DEFAULT 'USD',
    notes TEXT,
    shipping_address TEXT,  -- JSON string for flexible address storage
    billing_address TEXT,
    shipped_at TEXT,
    delivered_at TEXT,
    created_at TEXT DEFAULT (datetime('now')),
    updated_at TEXT DEFAULT (datetime('now')),
    
    -- Foreign key
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Order items table
CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    variant_id INTEGER NULL,
    product_name TEXT NOT NULL,
    product_sku TEXT NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price REAL NOT NULL CHECK (unit_price > 0),
    total_price REAL NOT NULL CHECK (total_price > 0),
    created_at TEXT DEFAULT (datetime('now')),
    
    -- Foreign keys
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- =============================================================================
-- SQLite-Specific Indexes
-- =============================================================================

-- Create optimized indexes for SQLite
CREATE INDEX IF NOT EXISTS idx_sqlite_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_sqlite_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_sqlite_users_active_created ON users(is_active, created_at);
CREATE INDEX IF NOT EXISTS idx_sqlite_users_last_login ON users(last_login_at);

CREATE INDEX IF NOT EXISTS idx_sqlite_products_category_active ON products(category_id, is_active);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_brand_active ON products(brand_id, is_active);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_slug ON products(product_slug);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_sku ON products(sku);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_price_range ON products(price);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_inventory_status ON products(inventory_quantity, is_active);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_featured_active ON products(is_featured, is_active);
CREATE INDEX IF NOT EXISTS idx_sqlite_products_created_at ON products(created_at);

CREATE INDEX IF NOT EXISTS idx_sqlite_categories_parent ON categories(parent_category_id);
CREATE INDEX IF NOT EXISTS idx_sqlite_categories_slug ON categories(category_slug);
CREATE INDEX IF NOT EXISTS idx_sqlite_categories_active ON categories(is_active);
CREATE INDEX IF NOT EXISTS idx_sqlite_categories_sort ON categories(sort_order);

CREATE INDEX IF NOT EXISTS idx_sqlite_brands_slug ON brands(brand_slug);
CREATE INDEX IF NOT EXISTS idx_sqlite_brands_active ON brands(is_active);

CREATE INDEX IF NOT EXISTS idx_sqlite_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_sqlite_orders_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_sqlite_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_sqlite_orders_payment_status ON orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_sqlite_orders_shipping_status ON orders(shipping_status);
CREATE INDEX IF NOT EXISTS idx_sqlite_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_sqlite_orders_total ON orders(total_amount);
CREATE INDEX IF NOT EXISTS idx_sqlite_orders_user_status ON orders(user_id, status);
CREATE INDEX IF NOT EXISTS idx_sqlite_orders_status_created ON orders(status, created_at);

CREATE INDEX IF NOT EXISTS idx_sqlite_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_sqlite_order_items_product ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_sqlite_order_items_variant ON order_items(variant_id);
CREATE INDEX IF NOT EXISTS idx_sqlite_order_items_product_order ON order_items(product_id, order_id);

-- Partial indexes for SQLite (using WHERE clause)
CREATE INDEX IF NOT EXISTS idx_sqlite_products_low_stock ON products(inventory_quantity, product_id) 
WHERE inventory_quantity <= 10;

CREATE INDEX IF NOT EXISTS idx_sqlite_products_featured_active_partial ON products(created_at DESC) 
WHERE is_featured = 1 AND is_active = 1;

-- =============================================================================
-- SQLite-Specific Triggers
-- =============================================================================

-- Trigger to automatically update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS tr_sqlite_users_updated_at
    AFTER UPDATE ON users
    FOR EACH ROW
BEGIN
    UPDATE users 
    SET updated_at = datetime('now')
    WHERE user_id = NEW.user_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_sqlite_products_updated_at
    AFTER UPDATE ON products
    FOR EACH ROW
BEGIN
    UPDATE products 
    SET updated_at = datetime('now')
    WHERE product_id = NEW.product_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_sqlite_categories_updated_at
    AFTER UPDATE ON categories
    FOR EACH ROW
BEGIN
    UPDATE categories 
    SET updated_at = datetime('now')
    WHERE category_id = NEW.category_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_sqlite_brands_updated_at
    AFTER UPDATE ON brands
    FOR EACH ROW
BEGIN
    UPDATE brands 
    SET updated_at = datetime('now')
    WHERE brand_id = NEW.brand_id;
END;

CREATE TRIGGER IF NOT EXISTS tr_sqlite_orders_updated_at
    AFTER UPDATE ON orders
    FOR EACH ROW
BEGIN
    UPDATE orders 
    SET updated_at = datetime('now')
    WHERE order_id = NEW.order_id;
END;

-- Trigger to log inventory changes
CREATE TRIGGER IF NOT EXISTS tr_sqlite_products_inventory_log
    AFTER UPDATE ON products
    FOR EACH ROW
    WHEN OLD.inventory_quantity IS NOT NEW.inventory_quantity
BEGIN
    INSERT INTO inventory_log (
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
FROM products;

-- Create a view for product ratings (simulating function)
CREATE VIEW IF NOT EXISTS v_product_ratings AS
SELECT 
    p.product_id,
    p.product_name,
    COALESCE(AVG(pr.rating), 0.0) as avg_rating,
    COUNT(pr.rating) as rating_count
FROM products p
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
FROM products p
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
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE u.is_active = 1
GROUP BY u.user_id, u.username, u.email, u.created_at;

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
    content='products',
    content_rowid='product_id'
);

-- Create triggers to maintain FTS table
CREATE TRIGGER IF NOT EXISTS tr_fts_products_insert
    AFTER INSERT ON products
    FOR EACH ROW
BEGIN
    INSERT INTO fts_products(product_id, product_name, description, short_description, tags)
    VALUES(NEW.product_id, NEW.product_name, NEW.description, NEW.short_description, NEW.tags);
END;

CREATE TRIGGER IF NOT EXISTS tr_fts_products_update
    AFTER UPDATE ON products
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
    AFTER DELETE ON products
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
    (SELECT COUNT(*) FROM users) as row_count,
    (SELECT COUNT(*) FROM users WHERE is_active = 1) as active_count
UNION ALL
SELECT 
    'Products' as table_name,
    (SELECT COUNT(*) FROM products) as row_count,
    (SELECT COUNT(*) FROM products WHERE is_active = 1) as active_count
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
FROM products
WHERE inventory_quantity <= low_stock_threshold
ORDER BY inventory_quantity ASC;

-- =============================================================================
-- Sample Data Insertion
-- =============================================================================

-- Insert sample categories
INSERT INTO categories (parent_category_id, category_name, category_slug, description, sort_order, is_active) VALUES
(NULL, 'Electronics', 'electronics', 'Electronic devices and gadgets', 1, 1),
(NULL, 'Clothing', 'clothing', 'Fashion and apparel', 2, 1),
(NULL, 'Home & Garden', 'home-garden', 'Home improvement and garden supplies', 3, 1),
(1, 'Smartphones', 'smartphones', 'Mobile phones and accessories', 1, 1),
(1, 'Laptops', 'laptops', 'Portable computers and accessories', 2, 1),
(2, 'Men''s Clothing', 'mens-clothing', 'Men''s fashion and apparel', 1, 1);

-- Insert sample brands
INSERT INTO brands (brand_name, brand_slug, description, is_active) VALUES
('Apple', 'apple', 'Technology company known for innovative products', 1),
('Samsung', 'samsung', 'Global technology leader in electronics', 1),
('Nike', 'nike', 'Athletic footwear and apparel company', 1),
('Adidas', 'adidas', 'German multinational sportswear company', 1);

-- Insert sample users
INSERT INTO users (username, email, password_hash, first_name, last_name, phone, date_of_birth, gender, is_active, is_verified, preferences, tags) VALUES
('john_doe', 'john.doe@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'John', 'Doe', '+1234567890', '1990-05-15', 'male', 1, 1, '{"newsletter": true, "language": "en", "currency": "USD"}', '["premium", "tech-savvy"]'),
('jane_smith', 'jane.smith@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'Jane', 'Smith', '+1234567891', '1985-08-22', 'female', 1, 1, '{"newsletter": false, "language": "en", "currency": "USD"}', '["fashion", "loyal"]'),
('mike_wilson', 'mike.wilson@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'Mike', 'Wilson', '+1234567892', '1992-12-10', 'male', 1, 0, '{"newsletter": true, "language": "en", "currency": "USD"}', '["new-customer", "budget-conscious"]');

-- Insert sample products
INSERT INTO products (category_id, brand_id, product_name, product_slug, sku, description, short_description, price, compare_price, inventory_quantity, is_active, is_featured, dimensions, specifications, tags) VALUES
(4, 1, 'iPhone 15 Pro', 'iphone-15-pro', 'IPH15PRO-128', 'Latest iPhone with advanced camera system and A17 Pro chip', 'iPhone 15 Pro 128GB', 999.00, 1099.00, 50, 1, 1, '{"length": 14.67, "width": 7.15, "height": 0.83}', '{"color": "Space Black", "storage": "128GB", "camera": "48MP"}', '["smartphone", "premium", "apple"]'),
(4, 2, 'Samsung Galaxy S24', 'samsung-galaxy-s24', 'SGS24-256', 'Premium Android smartphone with AI features', 'Galaxy S24 256GB', 799.00, 899.00, 75, 1, 1, '{"length": 14.7, "width": 7.0, "height": 0.78}', '{"color": "Phantom Black", "storage": "256GB", "camera": "50MP"}', '["smartphone", "android", "samsung"]'),
(5, 1, 'MacBook Pro 16"', 'macbook-pro-16', 'MBP16-M3', 'Professional laptop with M3 chip and Liquid Retina XDR display', 'MacBook Pro 16" M3 512GB', 2499.00, 2699.00, 25, 1, 1, '{"length": 35.57, "width": 24.81, "height": 1.68}', '{"color": "Space Gray", "storage": "512GB", "processor": "M3"}', '["laptop", "professional", "apple"]'),
(6, 3, 'Nike Air Max 270', 'nike-air-max-270', 'NIKE-AM270-BLK', 'Comfortable running shoes with Max Air cushioning', 'Nike Air Max 270 Black', 150.00, 180.00, 200, 1, 0, '{"length": 32, "width": 12, "height": 10}', '{"color": "Black", "size": "10", "material": "Mesh"}', '["shoes", "running", "nike"]');

-- Insert sample orders
INSERT INTO orders (user_id, order_number, status, payment_status, shipping_status, subtotal, tax_amount, shipping_amount, total_amount, currency, shipping_address, billing_address) VALUES
(1, 'ORD-2024-001', 'delivered', 'paid', 'delivered', 999.00, 79.92, 9.99, 1088.91, 'USD', '{"street": "123 Main St", "city": "New York", "state": "NY", "zip": "10001", "country": "USA"}', '{"street": "123 Main St", "city": "New York", "state": "NY", "zip": "10001", "country": "USA"}'),
(2, 'ORD-2024-002', 'shipped', 'paid', 'shipped', 799.00, 63.92, 9.99, 872.91, 'USD', '{"street": "456 Oak Ave", "city": "Los Angeles", "state": "CA", "zip": "90210", "country": "USA"}', '{"street": "456 Oak Ave", "city": "Los Angeles", "state": "CA", "zip": "90210", "country": "USA"}'),
(3, 'ORD-2024-003', 'processing', 'paid', 'pending', 150.00, 12.00, 9.99, 171.99, 'USD', '{"street": "789 Pine St", "city": "Chicago", "state": "IL", "zip": "60601", "country": "USA"}', '{"street": "789 Pine St", "city": "Chicago", "state": "IL", "zip": "60601", "country": "USA"}');

-- Insert sample order items
INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price, total_price) VALUES
(1, 1, 'iPhone 15 Pro', 'IPH15PRO-128', 1, 999.00, 999.00),
(2, 2, 'Samsung Galaxy S24', 'SGS24-256', 1, 799.00, 799.00),
(3, 4, 'Nike Air Max 270', 'NIKE-AM270-BLK', 1, 150.00, 150.00);

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
-- End of SQLite E-commerce Database
-- =============================================================================
