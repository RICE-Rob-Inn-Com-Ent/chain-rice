-- =============================================================================
-- PostgreSQL E-commerce Database - Middle Average Implementation
-- =============================================================================
-- This file demonstrates PostgreSQL-specific features and optimizations for a
-- middle-average e-commerce database implementation.
--
-- Database: PostgreSQL 14+
-- Features: JSONB, Arrays, Full-Text Search, Window Functions, CTEs
-- Author: Chain Rice Development Team
-- =============================================================================

-- =============================================================================
-- PostgreSQL Configuration and Extensions
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
-- Core Tables with PostgreSQL Features
-- =============================================================================

-- Users table with PostgreSQL-specific optimizations
CREATE TABLE users (
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
    tags TEXT[],  -- PostgreSQL array for user tags
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- PostgreSQL-specific indexes
    CREATE INDEX idx_pg_users_email_trgm ON users USING gin (email gin_trgm_ops),
    CREATE INDEX idx_pg_users_username_trgm ON users USING gin (username gin_trgm_ops),
    CREATE INDEX idx_pg_users_active_created ON users (is_active, created_at),
    CREATE INDEX idx_pg_users_last_login ON users (last_login_at),
    CREATE INDEX idx_pg_users_uuid ON users (user_uuid),
    CREATE INDEX idx_pg_users_tags ON users USING gin (tags),
    
    -- PostgreSQL-specific constraints
    CONSTRAINT chk_email_format CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_username_length CHECK (char_length(username) >= 3),
    CONSTRAINT chk_phone_format CHECK (phone IS NULL OR phone ~ '^\+?[1-9]\d{1,14}$')
);

-- Products table with PostgreSQL JSONB and advanced features
CREATE TABLE products (
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
    
    -- Foreign keys
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
    FOREIGN KEY (brand_id) REFERENCES brands(brand_id) ON DELETE RESTRICT,
    
    -- PostgreSQL-specific indexes
    CREATE INDEX idx_pg_products_category_active ON products (category_id, is_active),
    CREATE INDEX idx_pg_products_brand_active ON products (brand_id, is_active),
    CREATE INDEX idx_pg_products_slug_trgm ON products USING gin (product_slug gin_trgm_ops),
    CREATE INDEX idx_pg_products_name_trgm ON products USING gin (product_name gin_trgm_ops),
    CREATE INDEX idx_pg_products_price_range ON products USING btree (price),
    CREATE INDEX idx_pg_products_inventory_status ON products (inventory_quantity, is_active),
    CREATE INDEX idx_pg_products_featured_active ON products (is_featured, is_active),
    CREATE INDEX idx_pg_products_created_at ON products (created_at),
    CREATE INDEX idx_pg_products_uuid ON products (product_uuid),
    
    -- JSONB indexes for PostgreSQL
    CREATE INDEX idx_pg_products_dimensions_weight ON products USING gin ((dimensions->>'weight')),
    CREATE INDEX idx_pg_products_specs_color ON products USING gin ((specifications->>'color')),
    
    -- Full-text search index
    CREATE INDEX idx_pg_products_search_vector ON products USING gin (search_vector),
    
    -- Array indexes
    CREATE INDEX idx_pg_products_tags ON products USING gin (tags)
);

-- Categories table with hierarchical structure
CREATE TABLE categories (
    category_id BIGSERIAL PRIMARY KEY,
    parent_category_id BIGINT NULL,
    category_name VARCHAR(100) NOT NULL,
    category_slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    image_url VARCHAR(500),
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    meta_title VARCHAR(255),
    meta_description VARCHAR(500),
    category_path VARCHAR(500),  -- Will be populated by trigger
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Self-referencing foreign key for hierarchy
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    
    -- PostgreSQL-specific indexes
    CREATE INDEX idx_pg_categories_parent ON categories (parent_category_id),
    CREATE INDEX idx_pg_categories_slug ON categories (category_slug),
    CREATE INDEX idx_pg_categories_active ON categories (is_active),
    CREATE INDEX idx_pg_categories_sort ON categories (sort_order),
    CREATE INDEX idx_pg_categories_path ON categories (category_path),
    
    -- Full-text search index
    CREATE INDEX idx_pg_categories_search ON categories USING gin (to_tsvector('english', category_name || ' ' || COALESCE(description, ''))),
    
    -- PostgreSQL-specific constraints
    CONSTRAINT chk_category_name_length CHECK (char_length(category_name) >= 2)
);

-- Brands table
CREATE TABLE brands (
    brand_id BIGSERIAL PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL UNIQUE,
    brand_slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    logo_url VARCHAR(500),
    website_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- PostgreSQL-specific indexes
    CREATE INDEX idx_pg_brands_slug ON brands (brand_slug),
    CREATE INDEX idx_pg_brands_active ON brands (is_active),
    
    -- Full-text search index
    CREATE INDEX idx_pg_brands_search ON brands USING gin (to_tsvector('english', brand_name || ' ' || COALESCE(description, '')))
);

-- Orders table with PostgreSQL features
CREATE TABLE orders (
    order_id BIGSERIAL PRIMARY KEY,
    order_uuid UUID DEFAULT uuid_generate_v4(),
    user_id BIGINT NOT NULL,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded')),
    payment_status VARCHAR(20) DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded', 'partially_refunded')),
    shipping_status VARCHAR(20) DEFAULT 'pending' CHECK (shipping_status IN ('pending', 'shipped', 'delivered', 'returned')),
    subtotal DECIMAL(10, 2) NOT NULL CHECK (subtotal >= 0),
    tax_amount DECIMAL(10, 2) DEFAULT 0 CHECK (tax_amount >= 0),
    shipping_amount DECIMAL(10, 2) DEFAULT 0 CHECK (shipping_amount >= 0),
    discount_amount DECIMAL(10, 2) DEFAULT 0 CHECK (discount_amount >= 0),
    total_amount DECIMAL(10, 2) NOT NULL CHECK (total_amount >= 0),
    currency VARCHAR(3) DEFAULT 'USD',
    notes TEXT,
    shipping_address JSONB,  -- PostgreSQL JSONB for flexible address storage
    billing_address JSONB,
    shipped_at TIMESTAMP WITH TIME ZONE,
    delivered_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    
    -- PostgreSQL-specific indexes
    CREATE INDEX idx_pg_orders_user ON orders (user_id),
    CREATE INDEX idx_pg_orders_number ON orders (order_number),
    CREATE INDEX idx_pg_orders_status ON orders (status),
    CREATE INDEX idx_pg_orders_payment_status ON orders (payment_status),
    CREATE INDEX idx_pg_orders_shipping_status ON orders (shipping_status),
    CREATE INDEX idx_pg_orders_created_at ON orders (created_at),
    CREATE INDEX idx_pg_orders_total ON orders (total_amount),
    CREATE INDEX idx_pg_orders_user_status ON orders (user_id, status),
    CREATE INDEX idx_pg_orders_status_created ON orders (status, created_at),
    CREATE INDEX idx_pg_orders_uuid ON orders (order_uuid),
    
    -- JSONB indexes
    CREATE INDEX idx_pg_orders_shipping_country ON orders USING gin ((shipping_address->>'country')),
    CREATE INDEX idx_pg_orders_billing_country ON orders USING gin ((billing_address->>'country'))
);

-- Order items table
CREATE TABLE order_items (
    item_id BIGSERIAL PRIMARY KEY,
    order_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    variant_id BIGINT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_sku VARCHAR(100) NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price > 0),
    total_price DECIMAL(10, 2) NOT NULL CHECK (total_price > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign keys
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
    
    -- PostgreSQL-specific indexes
    CREATE INDEX idx_pg_order_items_order ON order_items (order_id),
    CREATE INDEX idx_pg_order_items_product ON order_items (product_id),
    CREATE INDEX idx_pg_order_items_variant ON order_items (variant_id),
    CREATE INDEX idx_pg_order_items_product_order ON order_items (product_id, order_id)
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

-- Function to calculate product rating
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
    FROM products
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
    FROM products p
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
    BEFORE INSERT OR UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_product_search_vector();

-- Trigger to log inventory changes with detailed tracking
CREATE OR REPLACE FUNCTION log_inventory_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.inventory_quantity IS DISTINCT FROM NEW.inventory_quantity THEN
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
            CURRENT_TIMESTAMP
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_product_inventory_change_log
    AFTER UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION log_inventory_changes();

-- =============================================================================
-- PostgreSQL-Specific Views with Window Functions
-- =============================================================================

-- Product analytics view with PostgreSQL window functions
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
    -- PostgreSQL window functions
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(oi.total_price), 0) DESC) as revenue_rank,
    RANK() OVER (ORDER BY COALESCE(SUM(oi.total_price), 0) DESC) as revenue_rank_with_ties,
    DENSE_RANK() OVER (ORDER BY COALESCE(SUM(oi.total_price), 0) DESC) as revenue_dense_rank,
    PERCENT_RANK() OVER (ORDER BY COALESCE(SUM(oi.total_price), 0)) as revenue_percentile,
    LAG(COALESCE(SUM(oi.total_price), 0)) OVER (ORDER BY p.product_id) as prev_product_revenue,
    LEAD(COALESCE(SUM(oi.total_price), 0)) OVER (ORDER BY p.product_id) as next_product_revenue,
    p.created_at,
    p.updated_at
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status IN ('delivered', 'shipped')
GROUP BY p.product_id, p.product_name, p.sku, p.price, p.inventory_quantity, c.category_name, b.brand_name, p.tags, p.created_at, p.updated_at;

-- Customer analytics view with PostgreSQL window functions
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
    -- PostgreSQL window functions for customer segmentation
    ROW_NUMBER() OVER (ORDER BY SUM(o.total_amount) DESC) as customer_rank,
    PERCENT_RANK() OVER (ORDER BY SUM(o.total_amount)) as customer_percentile,
    NTILE(4) OVER (ORDER BY SUM(o.total_amount) DESC) as customer_quartile,
    CASE 
        WHEN EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - MAX(o.created_at))) <= 30 THEN 'Active'
        WHEN EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - MAX(o.created_at))) <= 90 THEN 'At Risk'
        WHEN EXTRACT(DAYS FROM (CURRENT_TIMESTAMP - MAX(o.created_at))) <= 180 THEN 'Inactive'
        ELSE 'Lost'
    END as customer_status
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE u.is_active = TRUE
GROUP BY u.user_id, u.username, u.email, u.created_at;

-- =============================================================================
-- PostgreSQL Performance Optimization
-- =============================================================================

-- Create partial indexes for specific conditions
CREATE INDEX idx_pg_products_low_stock ON products (inventory_quantity, product_id)
WHERE inventory_quantity <= 10;

CREATE INDEX idx_pg_products_featured_active ON products (created_at DESC)
WHERE is_featured = TRUE AND is_active = TRUE;

-- Create expression indexes
CREATE INDEX idx_pg_products_price_discount ON products ((price - COALESCE(compare_price, price)));

-- Create covering indexes for frequently accessed columns
CREATE INDEX idx_pg_products_covering ON products (
    product_id, product_name, sku, price, inventory_quantity, is_active, is_featured
) INCLUDE (category_id, brand_id);

-- =============================================================================
-- Sample Data Insertion
-- =============================================================================

-- Insert sample categories
INSERT INTO categories (parent_category_id, category_name, category_slug, description, sort_order, is_active) VALUES
(NULL, 'Electronics', 'electronics', 'Electronic devices and gadgets', 1, TRUE),
(NULL, 'Clothing', 'clothing', 'Fashion and apparel', 2, TRUE),
(NULL, 'Home & Garden', 'home-garden', 'Home improvement and garden supplies', 3, TRUE),
(1, 'Smartphones', 'smartphones', 'Mobile phones and accessories', 1, TRUE),
(1, 'Laptops', 'laptops', 'Portable computers and accessories', 2, TRUE),
(2, 'Men''s Clothing', 'mens-clothing', 'Men''s fashion and apparel', 1, TRUE);

-- Insert sample brands
INSERT INTO brands (brand_name, brand_slug, description, is_active) VALUES
('Apple', 'apple', 'Technology company known for innovative products', TRUE),
('Samsung', 'samsung', 'Global technology leader in electronics', TRUE),
('Nike', 'nike', 'Athletic footwear and apparel company', TRUE),
('Adidas', 'adidas', 'German multinational sportswear company', TRUE);

-- Insert sample users
INSERT INTO users (username, email, password_hash, first_name, last_name, phone, date_of_birth, gender, is_active, is_verified, preferences, tags) VALUES
('john_doe', 'john.doe@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'John', 'Doe', '+1234567890', '1990-05-15', 'male', TRUE, TRUE, 'newsletter=>true, language=>en, currency=>USD', ARRAY['premium', 'tech-savvy']),
('jane_smith', 'jane.smith@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'Jane', 'Smith', '+1234567891', '1985-08-22', 'female', TRUE, TRUE, 'newsletter=>false, language=>en, currency=>USD', ARRAY['fashion', 'loyal']),
('mike_wilson', 'mike.wilson@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'Mike', 'Wilson', '+1234567892', '1992-12-10', 'male', TRUE, FALSE, 'newsletter=>true, language=>en, currency=>USD', ARRAY['new-customer', 'budget-conscious']);

-- Insert sample products
INSERT INTO products (category_id, brand_id, product_name, product_slug, sku, description, short_description, price, compare_price, inventory_quantity, is_active, is_featured, dimensions, specifications, tags) VALUES
(4, 1, 'iPhone 15 Pro', 'iphone-15-pro', 'IPH15PRO-128', 'Latest iPhone with advanced camera system and A17 Pro chip', 'iPhone 15 Pro 128GB', 999.00, 1099.00, 50, TRUE, TRUE, '{"length": 14.67, "width": 7.15, "height": 0.83}', '{"color": "Space Black", "storage": "128GB", "camera": "48MP"}', ARRAY['smartphone', 'premium', 'apple']),
(4, 2, 'Samsung Galaxy S24', 'samsung-galaxy-s24', 'SGS24-256', 'Premium Android smartphone with AI features', 'Galaxy S24 256GB', 799.00, 899.00, 75, TRUE, TRUE, '{"length": 14.7, "width": 7.0, "height": 0.78}', '{"color": "Phantom Black", "storage": "256GB", "camera": "50MP"}', ARRAY['smartphone', 'android', 'samsung']),
(5, 1, 'MacBook Pro 16"', 'macbook-pro-16', 'MBP16-M3', 'Professional laptop with M3 chip and Liquid Retina XDR display', 'MacBook Pro 16" M3 512GB', 2499.00, 2699.00, 25, TRUE, TRUE, '{"length": 35.57, "width": 24.81, "height": 1.68}', '{"color": "Space Gray", "storage": "512GB", "processor": "M3"}', ARRAY['laptop', 'professional', 'apple']),
(6, 3, 'Nike Air Max 270', 'nike-air-max-270', 'NIKE-AM270-BLK', 'Comfortable running shoes with Max Air cushioning', 'Nike Air Max 270 Black', 150.00, 180.00, 200, TRUE, FALSE, '{"length": 32, "width": 12, "height": 10}', '{"color": "Black", "size": "10", "material": "Mesh"}', ARRAY['shoes', 'running', 'nike']);

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
-- End of PostgreSQL E-commerce Database
-- =============================================================================
