-- =============================================================================
-- Chain Rice Database Schema - DDL (Data Definition Language)
-- =============================================================================
-- This file contains comprehensive DDL statements for creating the Chain Rice
-- database schema, including tables, indexes, constraints, and relationships.
--
-- Database: Chain Rice E-commerce Platform
-- Version: 1.0.0
-- Author: Chain Rice Development Team
-- =============================================================================

-- =============================================================================
-- Database Creation and Configuration
-- =============================================================================

-- Create database (MySQL/PostgreSQL)
CREATE DATABASE IF NOT EXISTS chain_rice
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- Use the database
USE chain_rice;

-- =============================================================================
-- User Management Tables
-- =============================================================================

-- Users table - Core user information
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_users_email (email),
    INDEX idx_users_username (username),
    INDEX idx_users_active (is_active),
    INDEX idx_users_created_at (created_at),
    
    -- Constraints
    CONSTRAINT chk_email_format CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_username_length CHECK (CHAR_LENGTH(username) >= 3),
    CONSTRAINT chk_phone_format CHECK (phone IS NULL OR phone REGEXP '^\\+?[1-9]\\d{1,14}$')
);

-- User addresses table - Multiple addresses per user
CREATE TABLE user_addresses (
    address_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    address_type ENUM('home', 'work', 'billing', 'shipping') DEFAULT 'home',
    is_default BOOLEAN DEFAULT FALSE,
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Indexes
    INDEX idx_user_addresses_user_id (user_id),
    INDEX idx_user_addresses_type (address_type),
    INDEX idx_user_addresses_default (is_default),
    INDEX idx_user_addresses_location (latitude, longitude),
    
    -- Constraints
    CONSTRAINT chk_coordinates CHECK (
        (latitude IS NULL AND longitude IS NULL) OR 
        (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
    )
);

-- User preferences table - User settings and preferences
CREATE TABLE user_preferences (
    preference_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    preference_key VARCHAR(100) NOT NULL,
    preference_value TEXT,
    data_type ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Unique constraint
    UNIQUE KEY uk_user_preferences (user_id, preference_key),
    
    -- Indexes
    INDEX idx_user_preferences_user_id (user_id),
    INDEX idx_user_preferences_key (preference_key)
);

-- =============================================================================
-- Product Management Tables
-- =============================================================================

-- Categories table - Product categorization
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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Self-referencing foreign key for hierarchy
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    
    -- Indexes
    INDEX idx_categories_parent (parent_category_id),
    INDEX idx_categories_slug (category_slug),
    INDEX idx_categories_active (is_active),
    INDEX idx_categories_sort (sort_order),
    
    -- Constraints
    CONSTRAINT chk_category_name_length CHECK (CHAR_LENGTH(category_name) >= 2)
);

-- Brands table - Product brands
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
    
    -- Indexes
    INDEX idx_brands_slug (brand_slug),
    INDEX idx_brands_active (is_active)
);

-- Products table - Core product information
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
    dimensions JSON, -- {"length": 10, "width": 5, "height": 2}
    inventory_tracking ENUM('none', 'product', 'variant') DEFAULT 'product',
    inventory_quantity INT DEFAULT 0,
    low_stock_threshold INT DEFAULT 5,
    allow_backorder BOOLEAN DEFAULT FALSE,
    is_digital BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    meta_title VARCHAR(255),
    meta_description VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign keys
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
    FOREIGN KEY (brand_id) REFERENCES brands(brand_id) ON DELETE RESTRICT,
    
    -- Indexes
    INDEX idx_products_category (category_id),
    INDEX idx_products_brand (brand_id),
    INDEX idx_products_slug (product_slug),
    INDEX idx_products_sku (sku),
    INDEX idx_products_active (is_active),
    INDEX idx_products_featured (is_featured),
    INDEX idx_products_price (price),
    INDEX idx_products_inventory (inventory_quantity),
    INDEX idx_products_created_at (created_at),
    
    -- Constraints
    CONSTRAINT chk_price_positive CHECK (price > 0),
    CONSTRAINT chk_compare_price CHECK (compare_price IS NULL OR compare_price > price),
    CONSTRAINT chk_cost_price CHECK (cost_price IS NULL OR cost_price >= 0),
    CONSTRAINT chk_weight_positive CHECK (weight IS NULL OR weight > 0),
    CONSTRAINT chk_inventory_quantity CHECK (inventory_quantity >= 0),
    CONSTRAINT chk_low_stock_threshold CHECK (low_stock_threshold >= 0)
);

-- Product variants table - Different variations of products
CREATE TABLE product_variants (
    variant_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT UNSIGNED NOT NULL,
    variant_name VARCHAR(255) NOT NULL,
    sku VARCHAR(100) NOT NULL UNIQUE,
    price DECIMAL(10, 2),
    compare_price DECIMAL(10, 2),
    cost_price DECIMAL(10, 2),
    weight DECIMAL(8, 3),
    inventory_quantity INT DEFAULT 0,
    low_stock_threshold INT DEFAULT 5,
    allow_backorder BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    
    -- Indexes
    INDEX idx_variants_product (product_id),
    INDEX idx_variants_sku (sku),
    INDEX idx_variants_active (is_active),
    
    -- Constraints
    CONSTRAINT chk_variant_price CHECK (price IS NULL OR price > 0),
    CONSTRAINT chk_variant_compare_price CHECK (compare_price IS NULL OR compare_price > price),
    CONSTRAINT chk_variant_cost_price CHECK (cost_price IS NULL OR cost_price >= 0),
    CONSTRAINT chk_variant_weight CHECK (weight IS NULL OR weight > 0),
    CONSTRAINT chk_variant_inventory CHECK (inventory_quantity >= 0)
);

-- Product attributes table - Custom attributes for products
CREATE TABLE product_attributes (
    attribute_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    attribute_name VARCHAR(100) NOT NULL,
    attribute_type ENUM('text', 'number', 'boolean', 'select', 'multiselect', 'date') DEFAULT 'text',
    is_required BOOLEAN DEFAULT FALSE,
    is_filterable BOOLEAN DEFAULT FALSE,
    sort_order INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_attributes_name (attribute_name),
    INDEX idx_attributes_type (attribute_type),
    INDEX idx_attributes_filterable (is_filterable),
    
    -- Constraints
    CONSTRAINT chk_attribute_name_length CHECK (CHAR_LENGTH(attribute_name) >= 2)
);

-- Product attribute values table - Values for product attributes
CREATE TABLE product_attribute_values (
    value_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT UNSIGNED NOT NULL,
    attribute_id BIGINT UNSIGNED NOT NULL,
    attribute_value TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign keys
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (attribute_id) REFERENCES product_attributes(attribute_id) ON DELETE CASCADE,
    
    -- Unique constraint
    UNIQUE KEY uk_product_attribute (product_id, attribute_id),
    
    -- Indexes
    INDEX idx_attribute_values_product (product_id),
    INDEX idx_attribute_values_attribute (attribute_id)
);

-- Product images table - Multiple images per product
CREATE TABLE product_images (
    image_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT UNSIGNED NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    alt_text VARCHAR(255),
    sort_order INT DEFAULT 0,
    is_primary BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    
    -- Indexes
    INDEX idx_images_product (product_id),
    INDEX idx_images_sort (sort_order),
    INDEX idx_images_primary (is_primary)
);

-- =============================================================================
-- Order Management Tables
-- =============================================================================

-- Orders table - Customer orders
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
    shipped_at TIMESTAMP NULL,
    delivered_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    
    -- Indexes
    INDEX idx_orders_user (user_id),
    INDEX idx_orders_number (order_number),
    INDEX idx_orders_status (status),
    INDEX idx_orders_payment_status (payment_status),
    INDEX idx_orders_shipping_status (shipping_status),
    INDEX idx_orders_created_at (created_at),
    INDEX idx_orders_total (total_amount),
    
    -- Constraints
    CONSTRAINT chk_subtotal_positive CHECK (subtotal >= 0),
    CONSTRAINT chk_tax_amount CHECK (tax_amount >= 0),
    CONSTRAINT chk_shipping_amount CHECK (shipping_amount >= 0),
    CONSTRAINT chk_discount_amount CHECK (discount_amount >= 0),
    CONSTRAINT chk_total_amount CHECK (total_amount >= 0)
);

-- Order items table - Items within orders
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
    FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id) ON DELETE SET NULL,
    
    -- Indexes
    INDEX idx_order_items_order (order_id),
    INDEX idx_order_items_product (product_id),
    INDEX idx_order_items_variant (variant_id),
    
    -- Constraints
    CONSTRAINT chk_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_unit_price_positive CHECK (unit_price > 0),
    CONSTRAINT chk_total_price_positive CHECK (total_price > 0)
);

-- Order addresses table - Shipping and billing addresses for orders
CREATE TABLE order_addresses (
    address_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    address_type ENUM('billing', 'shipping') NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    company VARCHAR(255),
    street_address VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    
    -- Indexes
    INDEX idx_order_addresses_order (order_id),
    INDEX idx_order_addresses_type (address_type)
);

-- =============================================================================
-- Payment and Financial Tables
-- =============================================================================

-- Payment methods table - Available payment methods
CREATE TABLE payment_methods (
    method_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    method_name VARCHAR(100) NOT NULL UNIQUE,
    method_type ENUM('credit_card', 'debit_card', 'paypal', 'stripe', 'bank_transfer', 'cash_on_delivery') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    processing_fee_percentage DECIMAL(5, 4) DEFAULT 0,
    processing_fee_fixed DECIMAL(10, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_payment_methods_type (method_type),
    INDEX idx_payment_methods_active (is_active),
    
    -- Constraints
    CONSTRAINT chk_processing_fee_percentage CHECK (processing_fee_percentage >= 0 AND processing_fee_percentage <= 1),
    CONSTRAINT chk_processing_fee_fixed CHECK (processing_fee_fixed >= 0)
);

-- Payments table - Payment transactions
CREATE TABLE payments (
    payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    method_id BIGINT UNSIGNED NOT NULL,
    transaction_id VARCHAR(255) UNIQUE,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    status ENUM('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded') DEFAULT 'pending',
    gateway_response JSON,
    processed_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign keys
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE RESTRICT,
    FOREIGN KEY (method_id) REFERENCES payment_methods(method_id) ON DELETE RESTRICT,
    
    -- Indexes
    INDEX idx_payments_order (order_id),
    INDEX idx_payments_method (method_id),
    INDEX idx_payments_transaction (transaction_id),
    INDEX idx_payments_status (status),
    INDEX idx_payments_processed_at (processed_at),
    
    -- Constraints
    CONSTRAINT chk_payment_amount_positive CHECK (amount > 0)
);

-- =============================================================================
-- Analytics and Reporting Tables
-- =============================================================================

-- User sessions table - Track user sessions
CREATE TABLE user_sessions (
    session_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NULL,
    session_token VARCHAR(255) NOT NULL UNIQUE,
    ip_address VARCHAR(45),
    user_agent TEXT,
    device_type ENUM('desktop', 'mobile', 'tablet') DEFAULT 'desktop',
    browser VARCHAR(100),
    os VARCHAR(100),
    country VARCHAR(100),
    city VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    last_activity_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    
    -- Foreign key
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    
    -- Indexes
    INDEX idx_sessions_user (user_id),
    INDEX idx_sessions_token (session_token),
    INDEX idx_sessions_active (is_active),
    INDEX idx_sessions_expires (expires_at),
    INDEX idx_sessions_ip (ip_address),
    INDEX idx_sessions_device (device_type)
);

-- Product views table - Track product page views
CREATE TABLE product_views (
    view_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    product_id BIGINT UNSIGNED NOT NULL,
    user_id BIGINT UNSIGNED NULL,
    session_id BIGINT UNSIGNED NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    referrer_url VARCHAR(500),
    viewed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign keys
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (session_id) REFERENCES user_sessions(session_id) ON DELETE SET NULL,
    
    -- Indexes
    INDEX idx_views_product (product_id),
    INDEX idx_views_user (user_id),
    INDEX idx_views_session (session_id),
    INDEX idx_views_viewed_at (viewed_at),
    INDEX idx_views_ip (ip_address)
);

-- =============================================================================
-- Views for Common Queries
-- =============================================================================

-- Product summary view
CREATE VIEW product_summary AS
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    p.price,
    p.inventory_quantity,
    c.category_name,
    b.brand_name,
    p.is_active,
    p.created_at
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id;

-- Order summary view
CREATE VIEW order_summary AS
SELECT 
    o.order_id,
    o.order_number,
    o.status,
    o.total_amount,
    o.created_at,
    u.username,
    u.email,
    COUNT(oi.item_id) as item_count
FROM orders o
JOIN users u ON o.user_id = u.user_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_number, o.status, o.total_amount, o.created_at, u.username, u.email;

-- User activity view
CREATE VIEW user_activity AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    u.created_at as user_created_at,
    u.last_login_at,
    COUNT(DISTINCT o.order_id) as total_orders,
    COALESCE(SUM(o.total_amount), 0) as total_spent,
    COUNT(DISTINCT pv.view_id) as product_views
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
LEFT JOIN product_views pv ON u.user_id = pv.user_id
GROUP BY u.user_id, u.username, u.email, u.created_at, u.last_login_at;

-- =============================================================================
-- Stored Procedures
-- =============================================================================

-- Procedure to update product inventory
DELIMITER //
CREATE PROCEDURE UpdateProductInventory(
    IN p_product_id BIGINT UNSIGNED,
    IN p_quantity_change INT,
    IN p_operation ENUM('add', 'subtract', 'set')
)
BEGIN
    DECLARE current_quantity INT DEFAULT 0;
    DECLARE new_quantity INT DEFAULT 0;
    
    -- Get current inventory
    SELECT inventory_quantity INTO current_quantity
    FROM products 
    WHERE product_id = p_product_id;
    
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
    
    -- Return the new quantity
    SELECT new_quantity as new_inventory_quantity;
END //
DELIMITER ;

-- Procedure to calculate order totals
DELIMITER //
CREATE PROCEDURE CalculateOrderTotals(IN p_order_id BIGINT UNSIGNED)
BEGIN
    DECLARE v_subtotal DECIMAL(10, 2) DEFAULT 0;
    DECLARE v_tax_amount DECIMAL(10, 2) DEFAULT 0;
    DECLARE v_shipping_amount DECIMAL(10, 2) DEFAULT 0;
    DECLARE v_discount_amount DECIMAL(10, 2) DEFAULT 0;
    DECLARE v_total_amount DECIMAL(10, 2) DEFAULT 0;
    
    -- Calculate subtotal from order items
    SELECT COALESCE(SUM(total_price), 0) INTO v_subtotal
    FROM order_items
    WHERE order_id = p_order_id;
    
    -- Calculate tax (example: 8.5% tax rate)
    SET v_tax_amount = v_subtotal * 0.085;
    
    -- Calculate shipping (example: $5.99 flat rate)
    SET v_shipping_amount = 5.99;
    
    -- Calculate total
    SET v_total_amount = v_subtotal + v_tax_amount + v_shipping_amount - v_discount_amount;
    
    -- Update order with calculated totals
    UPDATE orders 
    SET subtotal = v_subtotal,
        tax_amount = v_tax_amount,
        shipping_amount = v_shipping_amount,
        discount_amount = v_discount_amount,
        total_amount = v_total_amount,
        updated_at = CURRENT_TIMESTAMP
    WHERE order_id = p_order_id;
    
    -- Return calculated totals
    SELECT 
        v_subtotal as subtotal,
        v_tax_amount as tax_amount,
        v_shipping_amount as shipping_amount,
        v_discount_amount as discount_amount,
        v_total_amount as total_amount;
END //
DELIMITER ;

-- =============================================================================
-- Triggers
-- =============================================================================

-- Trigger to update product updated_at when variants change
DELIMITER //
CREATE TRIGGER tr_product_variants_updated
    AFTER UPDATE ON product_variants
    FOR EACH ROW
BEGIN
    UPDATE products 
    SET updated_at = CURRENT_TIMESTAMP
    WHERE product_id = NEW.product_id;
END //
DELIMITER ;

-- Trigger to log inventory changes
DELIMITER //
CREATE TRIGGER tr_product_inventory_log
    AFTER UPDATE ON products
    FOR EACH ROW
BEGIN
    IF OLD.inventory_quantity != NEW.inventory_quantity THEN
        INSERT INTO inventory_log (
            product_id,
            old_quantity,
            new_quantity,
            change_reason,
            created_at
        ) VALUES (
            NEW.product_id,
            OLD.inventory_quantity,
            NEW.inventory_quantity,
            'automatic_update',
            CURRENT_TIMESTAMP
        );
    END IF;
END //
DELIMITER ;

-- =============================================================================
-- Indexes for Performance Optimization
-- =============================================================================

-- Composite indexes for common query patterns
CREATE INDEX idx_products_category_active ON products(category_id, is_active);
CREATE INDEX idx_products_brand_active ON products(brand_id, is_active);
CREATE INDEX idx_products_price_active ON products(price, is_active);
CREATE INDEX idx_orders_user_status ON orders(user_id, status);
CREATE INDEX idx_orders_status_created ON orders(status, created_at);
CREATE INDEX idx_order_items_product_order ON order_items(product_id, order_id);
CREATE INDEX idx_product_views_product_date ON product_views(product_id, viewed_at);

-- Full-text search indexes
CREATE FULLTEXT INDEX idx_products_search ON products(product_name, description);
CREATE FULLTEXT INDEX idx_categories_search ON categories(category_name, description);

-- =============================================================================
-- Comments and Documentation
-- =============================================================================

-- Add table comments
ALTER TABLE users COMMENT = 'Core user information and authentication data';
ALTER TABLE products COMMENT = 'Product catalog with pricing and inventory information';
ALTER TABLE orders COMMENT = 'Customer orders with status tracking';
ALTER TABLE payments COMMENT = 'Payment transactions and gateway responses';

-- Add column comments for key fields
ALTER TABLE users MODIFY COLUMN password_hash VARCHAR(255) COMMENT 'Bcrypt hashed password';
ALTER TABLE products MODIFY COLUMN price DECIMAL(10, 2) COMMENT 'Selling price in USD';
ALTER TABLE orders MODIFY COLUMN total_amount DECIMAL(10, 2) COMMENT 'Final order total including taxes and shipping';

-- =============================================================================
-- End of DDL Script
-- =============================================================================
