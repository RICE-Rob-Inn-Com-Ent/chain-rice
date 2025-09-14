-- =============================================================================
-- Chain Rice Database - Complete Database Dump
-- =============================================================================
-- This file contains a complete database dump with all tables, data, indexes,
-- triggers, procedures, and views for the Chain Rice e-commerce platform.
--
-- Database: Multi-platform compatible
-- Version: 1.0.0
-- Author: Chain Rice Development Team
-- Generated: 2024-01-15 10:00:00
-- =============================================================================

-- =============================================================================
-- Database Creation and Configuration
-- =============================================================================

-- Create database
CREATE DATABASE IF NOT EXISTS chain_rice
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE chain_rice;

-- =============================================================================
-- Core Tables Creation
-- =============================================================================

-- Users table
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
    
    INDEX idx_users_email (email),
    INDEX idx_users_username (username),
    INDEX idx_users_active (is_active),
    INDEX idx_users_created_at (created_at),
    
    CONSTRAINT chk_email_format CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_username_length CHECK (CHAR_LENGTH(username) >= 3),
    CONSTRAINT chk_phone_format CHECK (phone IS NULL OR phone REGEXP '^\\+?[1-9]\\d{1,14}$')
);

-- Categories table
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
    
    FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
    
    INDEX idx_categories_parent (parent_category_id),
    INDEX idx_categories_slug (category_slug),
    INDEX idx_categories_active (is_active),
    INDEX idx_categories_sort (sort_order),
    
    CONSTRAINT chk_category_name_length CHECK (CHAR_LENGTH(category_name) >= 2)
);

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
    
    INDEX idx_brands_slug (brand_slug),
    INDEX idx_brands_active (is_active)
);

-- Products table
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
    dimensions JSON,
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
    
    FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
    FOREIGN KEY (brand_id) REFERENCES brands(brand_id) ON DELETE RESTRICT,
    
    INDEX idx_products_category (category_id),
    INDEX idx_products_brand (brand_id),
    INDEX idx_products_slug (product_slug),
    INDEX idx_products_sku (sku),
    INDEX idx_products_active (is_active),
    INDEX idx_products_featured (is_featured),
    INDEX idx_products_price (price),
    INDEX idx_products_inventory (inventory_quantity),
    INDEX idx_products_created_at (created_at),
    
    CONSTRAINT chk_price_positive CHECK (price > 0),
    CONSTRAINT chk_compare_price CHECK (compare_price IS NULL OR compare_price > price),
    CONSTRAINT chk_cost_price CHECK (cost_price IS NULL OR cost_price >= 0),
    CONSTRAINT chk_weight_positive CHECK (weight IS NULL OR weight > 0),
    CONSTRAINT chk_inventory_quantity CHECK (inventory_quantity >= 0),
    CONSTRAINT chk_low_stock_threshold CHECK (low_stock_threshold >= 0)
);

-- Orders table
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
    
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    
    INDEX idx_orders_user (user_id),
    INDEX idx_orders_number (order_number),
    INDEX idx_orders_status (status),
    INDEX idx_orders_payment_status (payment_status),
    INDEX idx_orders_shipping_status (shipping_status),
    INDEX idx_orders_created_at (created_at),
    INDEX idx_orders_total (total_amount),
    
    CONSTRAINT chk_subtotal_positive CHECK (subtotal >= 0),
    CONSTRAINT chk_tax_amount CHECK (tax_amount >= 0),
    CONSTRAINT chk_shipping_amount CHECK (shipping_amount >= 0),
    CONSTRAINT chk_discount_amount CHECK (discount_amount >= 0),
    CONSTRAINT chk_total_amount CHECK (total_amount >= 0)
);

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
    
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT,
    
    INDEX idx_order_items_order (order_id),
    INDEX idx_order_items_product (product_id),
    INDEX idx_order_items_variant (variant_id),
    
    CONSTRAINT chk_quantity_positive CHECK (quantity > 0),
    CONSTRAINT chk_unit_price_positive CHECK (unit_price > 0),
    CONSTRAINT chk_total_price_positive CHECK (total_price > 0)
);

-- =============================================================================
-- Sample Data Insertion
-- =============================================================================

-- Insert sample categories
INSERT INTO categories (parent_category_id, category_name, category_slug, description, sort_order, is_active) VALUES
(NULL, 'Electronics', 'electronics', 'Electronic devices and gadgets', 1, TRUE),
(NULL, 'Clothing', 'clothing', 'Fashion and apparel', 2, TRUE),
(NULL, 'Home & Garden', 'home-garden', 'Home improvement and garden supplies', 3, TRUE),
(NULL, 'Books', 'books', 'Books and educational materials', 4, TRUE),
(NULL, 'Sports', 'sports', 'Sports equipment and accessories', 5, TRUE),
(1, 'Smartphones', 'smartphones', 'Mobile phones and accessories', 1, TRUE),
(1, 'Laptops', 'laptops', 'Portable computers and accessories', 2, TRUE),
(1, 'Audio', 'audio', 'Headphones, speakers, and audio equipment', 3, TRUE),
(2, 'Men\'s Clothing', 'mens-clothing', 'Men\'s fashion and apparel', 1, TRUE),
(2, 'Women\'s Clothing', 'womens-clothing', 'Women\'s fashion and apparel', 2, TRUE);

-- Insert sample brands
INSERT INTO brands (brand_name, brand_slug, description, is_active) VALUES
('Apple', 'apple', 'Technology company known for innovative products', TRUE),
('Samsung', 'samsung', 'Global technology leader in electronics', TRUE),
('Nike', 'nike', 'Athletic footwear and apparel company', TRUE),
('Adidas', 'adidas', 'German multinational sportswear company', TRUE),
('Sony', 'sony', 'Japanese multinational conglomerate', TRUE),
('Microsoft', 'microsoft', 'Technology corporation and software company', TRUE),
('Google', 'google', 'Multinational technology company', TRUE),
('Amazon', 'amazon', 'E-commerce and cloud computing company', TRUE);

-- Insert sample users
INSERT INTO users (username, email, password_hash, first_name, last_name, phone, date_of_birth, gender, is_active, is_verified) VALUES
('john_doe', 'john.doe@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'John', 'Doe', '+1234567890', '1990-05-15', 'male', TRUE, TRUE),
('jane_smith', 'jane.smith@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'Jane', 'Smith', '+1234567891', '1985-08-22', 'female', TRUE, TRUE),
('mike_wilson', 'mike.wilson@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'Mike', 'Wilson', '+1234567892', '1992-12-10', 'male', TRUE, FALSE),
('sarah_jones', 'sarah.jones@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'Sarah', 'Jones', '+1234567893', '1988-03-25', 'female', TRUE, TRUE),
('alex_brown', 'alex.brown@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/8Q8Q8Q8', 'Alex', 'Brown', '+1234567894', '1995-07-18', 'other', TRUE, FALSE);

-- Insert sample products
INSERT INTO products (category_id, brand_id, product_name, product_slug, sku, description, short_description, price, compare_price, inventory_quantity, is_active, is_featured) VALUES
(6, 1, 'iPhone 15 Pro', 'iphone-15-pro', 'IPH15PRO-128', 'Latest iPhone with advanced camera system and A17 Pro chip', 'iPhone 15 Pro 128GB', 999.00, 1099.00, 50, TRUE, TRUE),
(6, 2, 'Samsung Galaxy S24', 'samsung-galaxy-s24', 'SGS24-256', 'Premium Android smartphone with AI features', 'Galaxy S24 256GB', 799.00, 899.00, 75, TRUE, TRUE),
(7, 1, 'MacBook Pro 16"', 'macbook-pro-16', 'MBP16-M3', 'Professional laptop with M3 chip and Liquid Retina XDR display', 'MacBook Pro 16" M3 512GB', 2499.00, 2699.00, 25, TRUE, TRUE),
(7, 2, 'Samsung Galaxy Book4', 'samsung-galaxy-book4', 'SGB4-512', 'Ultrabook with Intel Core i7 and AMOLED display', 'Galaxy Book4 512GB', 1299.00, 1499.00, 40, TRUE, FALSE),
(8, 5, 'Sony WH-1000XM5', 'sony-wh-1000xm5', 'SONY-WH1000XM5', 'Industry-leading noise canceling wireless headphones', 'Sony WH-1000XM5 Headphones', 399.00, 449.00, 100, TRUE, TRUE),
(9, 3, 'Nike Air Max 270', 'nike-air-max-270', 'NIKE-AM270-BLK', 'Comfortable running shoes with Max Air cushioning', 'Nike Air Max 270 Black', 150.00, 180.00, 200, TRUE, FALSE),
(10, 4, 'Adidas Ultraboost 22', 'adidas-ultraboost-22', 'ADIDAS-UB22-WHT', 'High-performance running shoes with Boost technology', 'Adidas Ultraboost 22 White', 180.00, 200.00, 150, TRUE, TRUE);

-- Insert sample orders
INSERT INTO orders (user_id, order_number, status, payment_status, shipping_status, subtotal, tax_amount, shipping_amount, total_amount, currency) VALUES
(1, 'ORD-2024-001', 'delivered', 'paid', 'delivered', 999.00, 79.92, 9.99, 1088.91, 'USD'),
(2, 'ORD-2024-002', 'shipped', 'paid', 'shipped', 799.00, 63.92, 9.99, 872.91, 'USD'),
(3, 'ORD-2024-003', 'processing', 'paid', 'pending', 150.00, 12.00, 9.99, 171.99, 'USD'),
(4, 'ORD-2024-004', 'pending', 'pending', 'pending', 2499.00, 199.92, 9.99, 2708.91, 'USD'),
(5, 'ORD-2024-005', 'delivered', 'paid', 'delivered', 399.00, 31.92, 9.99, 440.91, 'USD');

-- Insert sample order items
INSERT INTO order_items (order_id, product_id, product_name, product_sku, quantity, unit_price, total_price) VALUES
(1, 1, 'iPhone 15 Pro', 'IPH15PRO-128', 1, 999.00, 999.00),
(2, 2, 'Samsung Galaxy S24', 'SGS24-256', 1, 799.00, 799.00),
(3, 6, 'Nike Air Max 270', 'NIKE-AM270-BLK', 1, 150.00, 150.00),
(4, 3, 'MacBook Pro 16"', 'MBP16-M3', 1, 2499.00, 2499.00),
(5, 5, 'Sony WH-1000XM5', 'SONY-WH1000XM5', 1, 399.00, 399.00);

-- =============================================================================
-- Views Creation
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

-- Add column comments for key fields
ALTER TABLE users MODIFY COLUMN password_hash VARCHAR(255) COMMENT 'Bcrypt hashed password';
ALTER TABLE products MODIFY COLUMN price DECIMAL(10, 2) COMMENT 'Selling price in USD';
ALTER TABLE orders MODIFY COLUMN total_amount DECIMAL(10, 2) COMMENT 'Final order total including taxes and shipping';

-- =============================================================================
-- End of Database Dump
-- =============================================================================
