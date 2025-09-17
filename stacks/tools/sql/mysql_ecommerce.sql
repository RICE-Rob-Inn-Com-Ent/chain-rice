-- =============================================================================
-- MySQL E-commerce Database - Middle Average Implementation
-- =============================================================================
-- This file demonstrates MySQL-specific features and optimizations for a
-- middle-average e-commerce database implementation.
--
-- Database: MySQL 8.0+
-- Features: JSON, Window Functions, CTEs, Generated Columns
-- Author: Chain Rice Development Team
-- =============================================================================

-- =============================================================================
-- MySQL Configuration
-- =============================================================================

-- Enable MySQL-specific features
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';
SET innodb_lock_wait_timeout = 50;

-- =============================================================================
-- Core Tables with MySQL Features
-- =============================================================================

-- Users table with MySQL-specific optimizations
CREATE TABLE users (
    user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    gender ENUM('male', 'female', 'other', 'prefer_not_to_say'),
    avatar_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    email_verified_at TIMESTAMP NULL,
    last_login_at TIMESTAMP NULL,
    preferences JSON,  -- MySQL JSON support
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- MySQL-specific indexes
    INDEX idx_users_email_hash (email(191)),  -- Partial index for long emails
    INDEX idx_users_username_hash (username),
    INDEX idx_users_active_created (is_active, created_at),
    INDEX idx_users_last_login (last_login_at),
    
    -- JSON index for preferences
    INDEX idx_users_preferences ((CAST(preferences->'$.newsletter' AS CHAR(10)))),
    
    -- MySQL-specific constraints
    CONSTRAINT chk_email_format CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_username_length CHECK (CHAR_LENGTH(username) >= 3),
    CONSTRAINT chk_phone_format CHECK (phone IS NULL OR phone REGEXP '^\\+?[1-9]\\d{1,14}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Products table with MySQL JSON and generated columns
CREATE TABLE products (
    product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id BIGINT UNSIGNED NOT NULL,
    brand_id BIGINT UNSIGNED NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    product_slug VARCHAR(255) NOT NULL UNIQUE,
    sku VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    short_description VARCHAR(500),
    price DECIMAL(10, 2) NOT NULL,
    compare_price DECIMAL(10, 2),
    cost_price DECIMAL(10, 2),
    weight DECIMAL(8, 3),
    dimensions JSON,  -- MySQL JSON support
    specifications JSON,
    inventory_tracking ENUM('none', 'product', 'variant') DEFAULT 'product',
    inventory_quantity INT DEFAULT 0,
    low_stock_threshold INT DEFAULT 5,
    allow_backorder BOOLEAN DEFAULT FALSE,
    is_digital BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    meta_title VARCHAR(255),
    meta_description VARCHAR(500),
    -- MySQL generated column for search
    search_text TEXT GENERATED ALWAYS AS (
        CONCAT(product_name, ' ', COALESCE(description, ''), ' ', COALESCE(short_description, ''))
    ) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign keys
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
    FOREIGN KEY (brand_id) REFERENCES brands(brand_id) ON DELETE RESTRICT,
    
    -- MySQL-specific indexes
    INDEX idx_products_category_active (category_id, is_active),
    INDEX idx_products_brand_active (brand_id, is_active),
    INDEX idx_products_slug_hash (product_slug(191)),
    INDEX idx_products_sku_hash (sku),
    INDEX idx_products_price_range (price),
    INDEX idx_products_inventory_status (inventory_quantity, is_active),
    INDEX idx_products_featured_active (is_featured, is_active),
    INDEX idx_products_created_at (created_at),
    
    -- JSON indexes for MySQL 5.7+
    INDEX idx_products_dimensions_weight ((CAST(dimensions->'$.weight' AS UNSIGNED))),
    INDEX idx_products_specs_color ((CAST(specifications->'$.color' AS CHAR(50)))),
    
    -- Full-text search index
    FULLTEXT INDEX idx_products_search (product_name, description),
    FULLTEXT INDEX idx_products_search_generated (search_text),
    
    -- MySQL-specific constraints
    CONSTRAINT chk_price_positive CHECK (price > 0),
    CONSTRAINT chk_compare_price CHECK (compare_price IS NULL OR compare_price > price),
    CONSTRAINT chk_cost_price CHECK (cost_price IS NULL OR cost_price >= 0),
    CONSTRAINT chk_weight_positive CHECK (weight IS NULL OR weight > 0),
    CONSTRAINT chk_inventory_quantity CHECK (inventory_quantity >= 0),
    CONSTRAINT chk_low_stock_threshold CHECK (low_stock_threshold >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Categories table with hierarchical structure
CREATE TABLE categories (
    category_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    parent_category_id BIGINT UNSIGNED NULL,
    category_name VARCHAR(100) NOT NULL,
    category_slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    image_url VARCHAR(500),
    sort_order INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    meta_title VARCHAR(255),
    meta_description VARCHAR(500),
    -- MySQL generated column for hierarchy path
    category_path VARCHAR(500) GENERATED ALWAYS AS (
        CASE 
            WHEN parent_category_id IS NULL THEN category_slug
            ELSE CONCAT((SELECT category_slug FROM categories c2 WHERE c2.category_id = categories.parent_category_id), '/', category_slug)
        END
    ) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Self-referencing foreign key for hierarchy
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    
    -- MySQL-specific indexes
    INDEX idx_categories_parent (parent_category_id),
    INDEX idx_categories_slug (category_slug),
    INDEX idx_categories_active (is_active),
    INDEX idx_categories_sort (sort_order),
    INDEX idx_categories_path (category_path),
    
    -- Full-text search index
    FULLTEXT INDEX idx_categories_search (category_name, description),
    
    -- MySQL-specific constraints
    CONSTRAINT chk_category_name_length CHECK (CHAR_LENGTH(category_name) >= 2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Brands table
CREATE TABLE brands (
    brand_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    brand_name VARCHAR(100) NOT NULL UNIQUE,
    brand_slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    logo_url VARCHAR(500),
    website_url VARCHAR(500),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- MySQL-specific indexes
    INDEX idx_brands_slug (brand_slug),
    INDEX idx_brands_active (is_active),
    
    -- Full-text search index
    FULLTEXT INDEX idx_brands_search (brand_name, description)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Orders table with MySQL features
CREATE TABLE orders (
    order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    status ENUM('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded') DEFAULT 'pending',
    payment_status ENUM('pending', 'paid', 'failed', 'refunded', 'partially_refunded') DEFAULT 'pending',
    shipping_status ENUM('pending', 'shipped', 'delivered', 'returned') DEFAULT 'pending',
    subtotal DECIMAL(10, 2) NOT NULL,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    shipping_amount DECIMAL(10, 2) DEFAULT 0,
    discount_amount DECIMAL(10, 2) DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    notes TEXT,
    shipping_address JSON,  -- MySQL JSON for flexible address storage
    billing_address JSON,
    shipped_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    
    -- MySQL-specific indexes
    INDEX idx_orders_user (user_id),
    INDEX idx_orders_number (order_number),
    INDEX idx_orders_status (status),
    INDEX idx_orders_payment_status (payment_status),
    INDEX idx_orders_shipping_status (shipping_status),
    INDEX idx_orders_created_at (created_at),
    INDEX idx_orders_total (total_amount),
    INDEX idx_orders_user_status (user_id, status),
    INDEX idx_orders_status_created (status, created_at),
    
    -- JSON indexes
    INDEX idx_orders_shipping_country ((CAST(shipping_address->'$.country' AS CHAR(100)))),
    INDEX idx_orders_billing_country ((CAST(billing_address->'$.country' AS CHAR(100)))),
    
    -- MySQL-specific constraints
    CONSTRAINT chk_subtotal_positive CHECK (subtotal >= 0),
    CONSTRAINT chk_tax_amount CHECK (tax_amount >= 0),
    CONSTRAINT chk_shipping_amount CHECK (shipping_amount >= 0),
    CONSTRAINT chk_discount_amount CHECK (discount_amount >= 0),
    CONSTRAINT chk_total_amount CHECK (total_amount >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Order items table
CREATE TABLE order_items (
    item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    variant_id BIGINT UNSIGNED NULL,
    product_name VARCHAR(255) NOT NULL,
    product_sku VARCHAR(100) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign keys
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
    
    -- MySQL-specific indexes
    INDEX idx_order_items_order (order_id),
    INDEX idx_order_items_product (product_id),
    INDEX idx_order_items_variant (variant_id),
    INDEX idx_order_items_product_order (product_id, order_id),
    
    -- MySQL-specific constraints
    CONSTRAINT chk_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_unit_price_positive CHECK (unit_price > 0),
    CONSTRAINT chk_total_price_positive CHECK (total_price > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- MySQL-Specific Views with Window Functions
-- =============================================================================

-- Product analytics view with MySQL window functions
CREATE VIEW mysql_product_analytics AS
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    p.price,
    p.inventory_quantity,
    c.category_name,
    b.brand_name,
    COALESCE(SUM(oi.total_price), 0) as total_revenue,
    COALESCE(SUM(oi.quantity), 0) as total_sold,
    COALESCE(COUNT(DISTINCT oi.order_id), 0) as order_count,
    COALESCE(AVG(oi.unit_price), 0) as avg_selling_price,
    -- MySQL window functions
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
GROUP BY p.product_id, p.product_name, p.sku, p.price, p.inventory_quantity, c.category_name, b.brand_name, p.created_at, p.updated_at;

-- Customer analytics view with MySQL window functions
CREATE VIEW mysql_customer_analytics AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    u.created_at as customer_since,
    COUNT(DISTINCT o.order_id) as total_orders,
    COALESCE(SUM(o.total_amount), 0) as lifetime_value,
    COALESCE(AVG(o.total_amount), 0) as avg_order_value,
    MAX(o.created_at) as last_order_date,
    DATEDIFF(NOW(), MAX(o.created_at)) as days_since_last_order,
    -- MySQL window functions for customer segmentation
    ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(o.total_amount), 0) DESC) as customer_rank,
    PERCENT_RANK() OVER (ORDER BY COALESCE(SUM(o.total_amount), 0)) as customer_percentile,
    NTILE(4) OVER (ORDER BY COALESCE(SUM(o.total_amount), 0) DESC) as customer_quartile,
    CASE 
        WHEN DATEDIFF(NOW(), MAX(o.created_at)) <= 30 THEN 'Active'
        WHEN DATEDIFF(NOW(), MAX(o.created_at)) <= 90 THEN 'At Risk'
        WHEN DATEDIFF(NOW(), MAX(o.created_at)) <= 180 THEN 'Inactive'
        ELSE 'Lost'
    END as customer_status
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE u.is_active = TRUE
GROUP BY u.user_id, u.username, u.email, u.created_at;

-- =============================================================================
-- MySQL-Specific Stored Procedures
-- =============================================================================

-- Procedure for advanced product search with MySQL features
DELIMITER //
CREATE PROCEDURE MySQL_AdvancedProductSearch(
    IN search_term VARCHAR(500),
    IN category_filter VARCHAR(100),
    IN brand_filter VARCHAR(100),
    IN price_min DECIMAL(10, 2),
    IN price_max DECIMAL(10, 2),
    IN sort_by VARCHAR(50),
    IN sort_direction VARCHAR(4),
    IN page_offset INT,
    IN page_limit INT
)
BEGIN
    DECLARE search_query TEXT;
    DECLARE where_clause TEXT DEFAULT '';
    DECLARE order_clause TEXT DEFAULT '';
    
    -- Build WHERE clause with MySQL full-text search
    IF search_term IS NOT NULL AND search_term != '' THEN
        SET where_clause = CONCAT(where_clause, ' AND MATCH(p.product_name, p.description) AGAINST(''', search_term, ''' IN NATURAL LANGUAGE MODE)');
    END IF;
    
    IF category_filter IS NOT NULL AND category_filter != '' THEN
        SET where_clause = CONCAT(where_clause, ' AND c.category_slug = ''', category_filter, '''');
    END IF;
    
    IF brand_filter IS NOT NULL AND brand_filter != '' THEN
        SET where_clause = CONCAT(where_clause, ' AND b.brand_slug = ''', brand_filter, '''');
    END IF;
    
    IF price_min IS NOT NULL THEN
        SET where_clause = CONCAT(where_clause, ' AND p.price >= ', price_min);
    END IF;
    
    IF price_max IS NOT NULL THEN
        SET where_clause = CONCAT(where_clause, ' AND p.price <= ', price_max);
    END IF;
    
    -- Build ORDER clause
    CASE sort_by
        WHEN 'price' THEN SET order_clause = CONCAT('ORDER BY p.price ', sort_direction);
        WHEN 'name' THEN SET order_clause = CONCAT('ORDER BY p.product_name ', sort_direction);
        WHEN 'created' THEN SET order_clause = CONCAT('ORDER BY p.created_at ', sort_direction);
        WHEN 'relevance' THEN SET order_clause = CONCAT('ORDER BY MATCH(p.product_name, p.description) AGAINST(''', search_term, ''' IN NATURAL LANGUAGE MODE) ', sort_direction);
        ELSE SET order_clause = 'ORDER BY p.created_at DESC';
    END CASE;
    
    -- Execute dynamic query
    SET @sql = CONCAT('
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
                WHEN p.inventory_quantity > p.low_stock_threshold THEN ''In Stock''
                WHEN p.inventory_quantity > 0 THEN ''Low Stock''
                ELSE ''Out of Stock''
            END as availability_status
        FROM products p
        JOIN categories c ON p.category_id = c.category_id
        JOIN brands b ON p.brand_id = b.brand_id
        WHERE p.is_active = TRUE', where_clause, '
        ', order_clause, '
        LIMIT ', page_limit, ' OFFSET ', page_offset
    );
    
    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;

-- Procedure for inventory management with MySQL features
DELIMITER //
CREATE PROCEDURE MySQL_UpdateInventory(
    IN p_product_id BIGINT UNSIGNED,
    IN p_quantity_change INT,
    IN p_operation ENUM('add', 'subtract', 'set'),
    IN p_reason VARCHAR(255)
)
BEGIN
    DECLARE current_quantity INT DEFAULT 0;
    DECLARE new_quantity INT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Get current inventory
    SELECT inventory_quantity INTO current_quantity
    FROM products 
    WHERE product_id = p_product_id
    FOR UPDATE;  -- MySQL row locking
    
    -- Calculate new quantity based on operation
    CASE p_operation
        WHEN 'add' THEN SET new_quantity = current_quantity + p_quantity_change;
        WHEN 'subtract' THEN SET new_quantity = current_quantity - p_quantity_change;
        WHEN 'set' THEN SET new_quantity = p_quantity_change;
    END CASE;
    
    -- Ensure quantity doesn't go below 0
    IF new_quantity < 0 THEN
        SET new_quantity = 0;
    END IF;
    
    -- Update inventory
    UPDATE products 
    SET inventory_quantity = new_quantity,
        updated_at = CURRENT_TIMESTAMP
    WHERE product_id = p_product_id;
    
    -- Log inventory change
    INSERT INTO inventory_log (
        product_id,
        old_quantity,
        new_quantity,
        change_amount,
        change_reason,
        created_at
    ) VALUES (
        p_product_id,
        current_quantity,
        new_quantity,
        new_quantity - current_quantity,
        p_reason,
        CURRENT_TIMESTAMP
    );
    
    COMMIT;
    
    -- Return the new quantity
    SELECT new_quantity as new_inventory_quantity;
END //
DELIMITER ;

-- =============================================================================
-- MySQL-Specific Functions
-- =============================================================================

-- Function to calculate product rating
DELIMITER //
CREATE FUNCTION MySQL_CalculateProductRating(product_id_param BIGINT UNSIGNED)
RETURNS DECIMAL(3, 2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE avg_rating DECIMAL(3, 2) DEFAULT 0.00;
    
    SELECT COALESCE(AVG(rating), 0.00) INTO avg_rating
    FROM product_reviews
    WHERE product_id = product_id_param
    AND is_approved = TRUE;
    
    RETURN avg_rating;
END //
DELIMITER ;

-- Function to get product availability status
DELIMITER //
CREATE FUNCTION MySQL_GetProductAvailability(product_id_param BIGINT UNSIGNED)
RETURNS VARCHAR(20)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE inventory_qty INT DEFAULT 0;
    DECLARE low_stock_threshold INT DEFAULT 5;
    DECLARE allow_backorder_val BOOLEAN DEFAULT FALSE;
    
    SELECT inventory_quantity, low_stock_threshold, allow_backorder
    INTO inventory_qty, low_stock_threshold, allow_backorder_val
    FROM products
    WHERE product_id = product_id_param;
    
    IF inventory_qty > low_stock_threshold THEN
        RETURN 'In Stock';
    ELSEIF inventory_qty > 0 THEN
        RETURN 'Low Stock';
    ELSEIF allow_backorder_val THEN
        RETURN 'Backorder';
    ELSE
        RETURN 'Out of Stock';
    END IF;
END //
DELIMITER ;

-- =============================================================================
-- MySQL-Specific Triggers
-- =============================================================================

-- Trigger to automatically update product updated_at when variants change
DELIMITER //
CREATE TRIGGER tr_mysql_product_variants_updated
    AFTER UPDATE ON product_variants
    FOR EACH ROW
BEGIN
    UPDATE products 
    SET updated_at = CURRENT_TIMESTAMP
    WHERE product_id = NEW.product_id;
END //
DELIMITER ;

-- Trigger to log inventory changes with detailed tracking
DELIMITER //
CREATE TRIGGER tr_mysql_product_inventory_log
    AFTER UPDATE ON products
    FOR EACH ROW
BEGIN
    IF OLD.inventory_quantity != NEW.inventory_quantity THEN
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
END //
DELIMITER ;

-- =============================================================================
-- MySQL Performance Optimization
-- =============================================================================

-- Create optimized indexes for common query patterns
CREATE INDEX idx_mysql_products_category_active ON products(category_id, is_active);
CREATE INDEX idx_mysql_products_brand_active ON products(brand_id, is_active);
CREATE INDEX idx_mysql_products_price_active ON products(price, is_active);
CREATE INDEX idx_mysql_orders_user_status ON orders(user_id, status);
CREATE INDEX idx_mysql_orders_status_created ON orders(status, created_at);
CREATE INDEX idx_mysql_order_items_product_order ON order_items(product_id, order_id);

-- Full-text search indexes
CREATE FULLTEXT INDEX idx_mysql_products_search ON products(product_name, description);
CREATE FULLTEXT INDEX idx_mysql_categories_search ON categories(category_name, description);

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
(2, 'Men\'s Clothing', 'mens-clothing', 'Men\'s fashion and apparel', 1, TRUE);

-- Insert sample brands
INSERT INTO brands (brand_name, brand_slug, description, is_active) VALUES
('Apple', 'apple', 'Technology company known for innovative products', TRUE),
('Samsung', 'samsung', 'Global technology leader in electronics', TRUE),
('Nike', 'nike', 'Athletic footwear and apparel company', TRUE),
('Adidas', 'adidas', 'German multinational sportswear company', TRUE);

-- Insert sample users
INSERT INTO users (username, email, password_hash, first_name, last_name, phone, date_of_birth, gender, is_active, is_verified, preferences) VALUES
('john_doe', 'john.doe@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'John', 'Doe', '+1234567890', '1990-05-15', 'male', TRUE, TRUE, '{"newsletter": true, "language": "en", "currency": "USD"}'),
('jane_smith', 'jane.smith@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'Jane', 'Smith', '+1234567891', '1985-08-22', 'female', TRUE, TRUE, '{"newsletter": false, "language": "en", "currency": "USD"}'),
('mike_wilson', 'mike.wilson@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'Mike', 'Wilson', '+1234567892', '1992-12-10', 'male', TRUE, FALSE, '{"newsletter": true, "language": "en", "currency": "USD"}');

-- Insert sample products
INSERT INTO products (category_id, brand_id, product_name, product_slug, sku, description, short_description, price, compare_price, inventory_quantity, is_active, is_featured, dimensions, specifications) VALUES
(4, 1, 'iPhone 15 Pro', 'iphone-15-pro', 'IPH15PRO-128', 'Latest iPhone with advanced camera system and A17 Pro chip', 'iPhone 15 Pro 128GB', 999.00, 1099.00, 50, TRUE, TRUE, '{"length": 14.67, "width": 7.15, "height": 0.83}', '{"color": "Space Black", "storage": "128GB", "camera": "48MP"}'),
(4, 2, 'Samsung Galaxy S24', 'samsung-galaxy-s24', 'SGS24-256', 'Premium Android smartphone with AI features', 'Galaxy S24 256GB', 799.00, 899.00, 75, TRUE, TRUE, '{"length": 14.7, "width": 7.0, "height": 0.78}', '{"color": "Phantom Black", "storage": "256GB", "camera": "50MP"}'),
(5, 1, 'MacBook Pro 16"', 'macbook-pro-16', 'MBP16-M3', 'Professional laptop with M3 chip and Liquid Retina XDR display', 'MacBook Pro 16" M3 512GB', 2499.00, 2699.00, 25, TRUE, TRUE, '{"length": 35.57, "width": 24.81, "height": 1.68}', '{"color": "Space Gray", "storage": "512GB", "processor": "M3"}'),
(6, 3, 'Nike Air Max 270', 'nike-air-max-270', 'NIKE-AM270-BLK', 'Comfortable running shoes with Max Air cushioning', 'Nike Air Max 270 Black', 150.00, 180.00, 200, TRUE, FALSE, '{"length": 32, "width": 12, "height": 10}', '{"color": "Black", "size": "10", "material": "Mesh"}');

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
-- End of MySQL E-commerce Database
-- =============================================================================
