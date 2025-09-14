-- =============================================================================
-- Chain Rice Database - DML (Data Manipulation Language)
-- =============================================================================
-- This file contains comprehensive DML statements for the Chain Rice database,
-- including INSERT, UPDATE, DELETE operations and complex data manipulations.
--
-- Database: Chain Rice E-commerce Platform
-- Version: 1.0.0
-- Author: Chain Rice Development Team
-- =============================================================================

-- =============================================================================
-- Data Insertion Operations
-- =============================================================================

-- Insert sample categories
INSERT INTO categories (parent_category_id, category_name, category_slug, description, sort_order, is_active) VALUES
(NULL, 'Electronics', 'electronics', 'Electronic devices and gadgets', 1, TRUE),
(NULL, 'Clothing', 'clothing', 'Fashion and apparel', 2, TRUE),
(NULL, 'Home & Garden', 'home-garden', 'Home improvement and garden supplies', 3, TRUE),
(NULL, 'Books', 'books', 'Books and educational materials', 4, TRUE),
(NULL, 'Sports', 'sports', 'Sports equipment and accessories', 5, TRUE);

-- Insert subcategories
INSERT INTO categories (parent_category_id, category_name, category_slug, description, sort_order, is_active) VALUES
(1, 'Smartphones', 'smartphones', 'Mobile phones and accessories', 1, TRUE),
(1, 'Laptops', 'laptops', 'Portable computers and accessories', 2, TRUE),
(1, 'Audio', 'audio', 'Headphones, speakers, and audio equipment', 3, TRUE),
(2, 'Men\'s Clothing', 'mens-clothing', 'Men\'s fashion and apparel', 1, TRUE),
(2, 'Women\'s Clothing', 'womens-clothing', 'Women\'s fashion and apparel', 2, TRUE),
(2, 'Kids\' Clothing', 'kids-clothing', 'Children\'s clothing and accessories', 3, TRUE);

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

-- Insert user addresses
INSERT INTO user_addresses (user_id, address_type, is_default, street_address, city, state_province, postal_code, country) VALUES
(1, 'home', TRUE, '123 Main Street', 'New York', 'NY', '10001', 'United States'),
(1, 'work', FALSE, '456 Business Ave', 'New York', 'NY', '10002', 'United States'),
(2, 'home', TRUE, '789 Oak Lane', 'Los Angeles', 'CA', '90210', 'United States'),
(3, 'home', TRUE, '321 Pine Street', 'Chicago', 'IL', '60601', 'United States'),
(4, 'home', TRUE, '654 Elm Drive', 'Houston', 'TX', '77001', 'United States'),
(5, 'home', TRUE, '987 Maple Road', 'Phoenix', 'AZ', '85001', 'United States');

-- Insert user preferences
INSERT INTO user_preferences (user_id, preference_key, preference_value, data_type) VALUES
(1, 'newsletter_subscription', 'true', 'boolean'),
(1, 'email_notifications', 'true', 'boolean'),
(1, 'language', 'en', 'string'),
(1, 'currency', 'USD', 'string'),
(2, 'newsletter_subscription', 'false', 'boolean'),
(2, 'email_notifications', 'true', 'boolean'),
(2, 'language', 'en', 'string'),
(3, 'newsletter_subscription', 'true', 'boolean'),
(3, 'email_notifications', 'false', 'boolean'),
(4, 'newsletter_subscription', 'true', 'boolean'),
(4, 'email_notifications', 'true', 'boolean'),
(5, 'newsletter_subscription', 'false', 'boolean');

-- Insert sample products
INSERT INTO products (category_id, brand_id, product_name, product_slug, sku, description, short_description, price, compare_price, inventory_quantity, is_active, is_featured) VALUES
(6, 1, 'iPhone 15 Pro', 'iphone-15-pro', 'IPH15PRO-128', 'Latest iPhone with advanced camera system and A17 Pro chip', 'iPhone 15 Pro 128GB', 999.00, 1099.00, 50, TRUE, TRUE),
(6, 2, 'Samsung Galaxy S24', 'samsung-galaxy-s24', 'SGS24-256', 'Premium Android smartphone with AI features', 'Galaxy S24 256GB', 799.00, 899.00, 75, TRUE, TRUE),
(7, 1, 'MacBook Pro 16"', 'macbook-pro-16', 'MBP16-M3', 'Professional laptop with M3 chip and Liquid Retina XDR display', 'MacBook Pro 16" M3 512GB', 2499.00, 2699.00, 25, TRUE, TRUE),
(7, 2, 'Samsung Galaxy Book4', 'samsung-galaxy-book4', 'SGB4-512', 'Ultrabook with Intel Core i7 and AMOLED display', 'Galaxy Book4 512GB', 1299.00, 1499.00, 40, TRUE, FALSE),
(8, 5, 'Sony WH-1000XM5', 'sony-wh-1000xm5', 'SONY-WH1000XM5', 'Industry-leading noise canceling wireless headphones', 'Sony WH-1000XM5 Headphones', 399.00, 449.00, 100, TRUE, TRUE),
(9, 3, 'Nike Air Max 270', 'nike-air-max-270', 'NIKE-AM270-BLK', 'Comfortable running shoes with Max Air cushioning', 'Nike Air Max 270 Black', 150.00, 180.00, 200, TRUE, FALSE),
(10, 4, 'Adidas Ultraboost 22', 'adidas-ultraboost-22', 'ADIDAS-UB22-WHT', 'High-performance running shoes with Boost technology', 'Adidas Ultraboost 22 White', 180.00, 200.00, 150, TRUE, TRUE);

-- Insert product variants
INSERT INTO product_variants (product_id, variant_name, sku, price, inventory_quantity, is_active) VALUES
(1, 'iPhone 15 Pro 128GB Space Black', 'IPH15PRO-128-BLK', 999.00, 20, TRUE),
(1, 'iPhone 15 Pro 128GB Natural Titanium', 'IPH15PRO-128-NAT', 999.00, 15, TRUE),
(1, 'iPhone 15 Pro 128GB Blue Titanium', 'IPH15PRO-128-BLU', 999.00, 15, TRUE),
(2, 'Galaxy S24 256GB Phantom Black', 'SGS24-256-BLK', 799.00, 30, TRUE),
(2, 'Galaxy S24 256GB Marble Gray', 'SGS24-256-GRY', 799.00, 25, TRUE),
(2, 'Galaxy S24 256GB Cobalt Violet', 'SGS24-256-VIO', 799.00, 20, TRUE),
(6, 'Nike Air Max 270 Size 8', 'NIKE-AM270-BLK-8', 150.00, 25, TRUE),
(6, 'Nike Air Max 270 Size 9', 'NIKE-AM270-BLK-9', 150.00, 30, TRUE),
(6, 'Nike Air Max 270 Size 10', 'NIKE-AM270-BLK-10', 150.00, 35, TRUE);

-- Insert product attributes
INSERT INTO product_attributes (attribute_name, attribute_type, is_required, is_filterable, sort_order) VALUES
('Color', 'select', TRUE, TRUE, 1),
('Size', 'select', FALSE, TRUE, 2),
('Storage', 'select', TRUE, TRUE, 3),
('Material', 'select', FALSE, TRUE, 4),
('Weight', 'number', FALSE, FALSE, 5),
('Warranty', 'text', FALSE, FALSE, 6);

-- Insert product attribute values
INSERT INTO product_attribute_values (product_id, attribute_id, attribute_value) VALUES
(1, 1, 'Space Black'),
(1, 1, 'Natural Titanium'),
(1, 1, 'Blue Titanium'),
(1, 3, '128GB'),
(1, 3, '256GB'),
(1, 3, '512GB'),
(2, 1, 'Phantom Black'),
(2, 1, 'Marble Gray'),
(2, 1, 'Cobalt Violet'),
(2, 3, '256GB'),
(2, 3, '512GB'),
(6, 1, 'Black'),
(6, 1, 'White'),
(6, 1, 'Red'),
(6, 2, '8'),
(6, 2, '9'),
(6, 2, '10'),
(6, 2, '11'),
(6, 2, '12');

-- Insert product images
INSERT INTO product_images (product_id, image_url, alt_text, sort_order, is_primary) VALUES
(1, 'https://example.com/images/iphone15pro-front.jpg', 'iPhone 15 Pro front view', 1, TRUE),
(1, 'https://example.com/images/iphone15pro-back.jpg', 'iPhone 15 Pro back view', 2, FALSE),
(1, 'https://example.com/images/iphone15pro-side.jpg', 'iPhone 15 Pro side view', 3, FALSE),
(2, 'https://example.com/images/galaxy-s24-front.jpg', 'Samsung Galaxy S24 front view', 1, TRUE),
(2, 'https://example.com/images/galaxy-s24-back.jpg', 'Samsung Galaxy S24 back view', 2, FALSE),
(3, 'https://example.com/images/macbook-pro-front.jpg', 'MacBook Pro front view', 1, TRUE),
(3, 'https://example.com/images/macbook-pro-keyboard.jpg', 'MacBook Pro keyboard view', 2, FALSE),
(5, 'https://example.com/images/sony-headphones.jpg', 'Sony WH-1000XM5 headphones', 1, TRUE),
(6, 'https://example.com/images/nike-airmax-front.jpg', 'Nike Air Max 270 front view', 1, TRUE),
(6, 'https://example.com/images/nike-airmax-side.jpg', 'Nike Air Max 270 side view', 2, FALSE);

-- =============================================================================
-- Order Management Operations
-- =============================================================================

-- Insert sample orders
INSERT INTO orders (user_id, order_number, status, payment_status, shipping_status, subtotal, tax_amount, shipping_amount, total_amount, currency) VALUES
(1, 'ORD-2024-001', 'delivered', 'paid', 'delivered', 999.00, 79.92, 9.99, 1088.91, 'USD'),
(2, 'ORD-2024-002', 'shipped', 'paid', 'shipped', 799.00, 63.92, 9.99, 872.91, 'USD'),
(3, 'ORD-2024-003', 'processing', 'paid', 'pending', 150.00, 12.00, 9.99, 171.99, 'USD'),
(4, 'ORD-2024-004', 'pending', 'pending', 'pending', 2499.00, 199.92, 9.99, 2708.91, 'USD'),
(5, 'ORD-2024-005', 'delivered', 'paid', 'delivered', 399.00, 31.92, 9.99, 440.91, 'USD');

-- Insert order items
INSERT INTO order_items (order_id, product_id, variant_id, product_name, product_sku, quantity, unit_price, total_price) VALUES
(1, 1, 1, 'iPhone 15 Pro', 'IPH15PRO-128-BLK', 1, 999.00, 999.00),
(2, 2, 4, 'Samsung Galaxy S24', 'SGS24-256-BLK', 1, 799.00, 799.00),
(3, 6, 7, 'Nike Air Max 270', 'NIKE-AM270-BLK-8', 1, 150.00, 150.00),
(4, 3, NULL, 'MacBook Pro 16"', 'MBP16-M3', 1, 2499.00, 2499.00),
(5, 5, NULL, 'Sony WH-1000XM5', 'SONY-WH1000XM5', 1, 399.00, 399.00);

-- Insert order addresses
INSERT INTO order_addresses (order_id, address_type, first_name, last_name, street_address, city, state_province, postal_code, country, phone) VALUES
(1, 'billing', 'John', 'Doe', '123 Main Street', 'New York', 'NY', '10001', 'United States', '+1234567890'),
(1, 'shipping', 'John', 'Doe', '123 Main Street', 'New York', 'NY', '10001', 'United States', '+1234567890'),
(2, 'billing', 'Jane', 'Smith', '789 Oak Lane', 'Los Angeles', 'CA', '90210', 'United States', '+1234567891'),
(2, 'shipping', 'Jane', 'Smith', '789 Oak Lane', 'Los Angeles', 'CA', '90210', 'United States', '+1234567891'),
(3, 'billing', 'Mike', 'Wilson', '321 Pine Street', 'Chicago', 'IL', '60601', 'United States', '+1234567892'),
(3, 'shipping', 'Mike', 'Wilson', '321 Pine Street', 'Chicago', 'IL', '60601', 'United States', '+1234567892');

-- =============================================================================
-- Payment Operations
-- =============================================================================

-- Insert payment methods
INSERT INTO payment_methods (method_name, method_type, is_active, processing_fee_percentage, processing_fee_fixed) VALUES
('Credit Card', 'credit_card', TRUE, 0.029, 0.30),
('Debit Card', 'debit_card', TRUE, 0.025, 0.25),
('PayPal', 'paypal', TRUE, 0.034, 0.35),
('Stripe', 'stripe', TRUE, 0.029, 0.30),
('Bank Transfer', 'bank_transfer', TRUE, 0.000, 0.00),
('Cash on Delivery', 'cash_on_delivery', TRUE, 0.000, 0.00);

-- Insert payments
INSERT INTO payments (order_id, method_id, transaction_id, amount, currency, status, processed_at) VALUES
(1, 1, 'txn_1234567890', 1088.91, 'USD', 'completed', '2024-01-15 10:30:00'),
(2, 2, 'txn_1234567891', 872.91, 'USD', 'completed', '2024-01-16 14:20:00'),
(3, 1, 'txn_1234567892', 171.99, 'USD', 'completed', '2024-01-17 09:15:00'),
(4, 3, 'txn_1234567893', 2708.91, 'USD', 'completed', '2024-01-18 16:45:00'),
(5, 1, 'txn_1234567894', 440.91, 'USD', 'completed', '2024-01-19 11:30:00');

-- =============================================================================
-- Analytics Data
-- =============================================================================

-- Insert user sessions
INSERT INTO user_sessions (user_id, session_token, ip_address, user_agent, device_type, browser, os, country, city, expires_at) VALUES
(1, 'sess_abc123def456', '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', 'desktop', 'Chrome', 'Windows', 'United States', 'New York', DATE_ADD(NOW(), INTERVAL 24 HOUR)),
(2, 'sess_ghi789jkl012', '192.168.1.101', 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)', 'mobile', 'Safari', 'iOS', 'United States', 'Los Angeles', DATE_ADD(NOW(), INTERVAL 24 HOUR)),
(3, 'sess_mno345pqr678', '192.168.1.102', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36', 'desktop', 'Chrome', 'macOS', 'United States', 'Chicago', DATE_ADD(NOW(), INTERVAL 24 HOUR)),
(4, 'sess_stu901vwx234', '192.168.1.103', 'Mozilla/5.0 (Android 12; Mobile; rv:91.0) Gecko/91.0 Firefox/91.0', 'mobile', 'Firefox', 'Android', 'United States', 'Houston', DATE_ADD(NOW(), INTERVAL 24 HOUR)),
(5, 'sess_yza567bcd890', '192.168.1.104', 'Mozilla/5.0 (iPad; CPU OS 15_0 like Mac OS X) AppleWebKit/605.1.15', 'tablet', 'Safari', 'iOS', 'United States', 'Phoenix', DATE_ADD(NOW(), INTERVAL 24 HOUR));

-- Insert product views
INSERT INTO product_views (product_id, user_id, session_id, ip_address, user_agent, referrer_url) VALUES
(1, 1, 1, '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', 'https://google.com/search?q=iphone+15+pro'),
(1, 2, 2, '192.168.1.101', 'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)', 'https://facebook.com'),
(2, 3, 3, '192.168.1.102', 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36', 'https://twitter.com'),
(3, 1, 1, '192.168.1.100', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36', 'https://example.com/products'),
(5, 4, 4, '192.168.1.103', 'Mozilla/5.0 (Android 12; Mobile; rv:91.0) Gecko/91.0 Firefox/91.0', 'https://amazon.com'),
(6, 5, 5, '192.168.1.104', 'Mozilla/5.0 (iPad; CPU OS 15_0 like Mac OS X) AppleWebKit/605.1.15', 'https://nike.com');

-- =============================================================================
-- Data Update Operations
-- =============================================================================

-- Update user information
UPDATE users 
SET last_login_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE user_id IN (1, 2, 3);

-- Update product inventory after sales
UPDATE products 
SET inventory_quantity = inventory_quantity - 1,
    updated_at = CURRENT_TIMESTAMP
WHERE product_id IN (1, 2, 6, 3, 5);

-- Update order status
UPDATE orders 
SET status = 'delivered',
    shipping_status = 'delivered',
    delivered_at = CURRENT_TIMESTAMP,
    updated_at = CURRENT_TIMESTAMP
WHERE order_id = 2;

-- Update product prices (price increase)
UPDATE products 
SET price = price * 1.05,  -- 5% increase
    updated_at = CURRENT_TIMESTAMP
WHERE category_id IN (6, 7);  -- Electronics categories

-- Update user preferences
UPDATE user_preferences 
SET preference_value = 'false',
    updated_at = CURRENT_TIMESTAMP
WHERE user_id = 1 AND preference_key = 'newsletter_subscription';

-- =============================================================================
-- Complex Data Manipulation Operations
-- =============================================================================

-- Bulk update product inventory based on sales
UPDATE products p
SET inventory_quantity = (
    SELECT p.inventory_quantity - COALESCE(SUM(oi.quantity), 0)
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE oi.product_id = p.product_id
    AND o.status IN ('confirmed', 'processing', 'shipped', 'delivered')
    AND o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
),
updated_at = CURRENT_TIMESTAMP
WHERE p.is_active = TRUE;

-- Update user activity based on orders
UPDATE users u
SET last_login_at = (
    SELECT MAX(o.created_at)
    FROM orders o
    WHERE o.user_id = u.user_id
),
updated_at = CURRENT_TIMESTAMP
WHERE u.user_id IN (
    SELECT DISTINCT user_id 
    FROM orders 
    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
);

-- Update product featured status based on sales performance
UPDATE products p
SET is_featured = (
    SELECT CASE 
        WHEN COUNT(oi.item_id) >= 10 THEN TRUE
        ELSE FALSE
    END
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE oi.product_id = p.product_id
    AND o.status IN ('delivered')
    AND o.created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
),
updated_at = CURRENT_TIMESTAMP;

-- =============================================================================
-- Data Deletion Operations
-- =============================================================================

-- Delete inactive user sessions older than 30 days
DELETE FROM user_sessions 
WHERE is_active = FALSE 
AND created_at < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- Delete old product views (keep only last 90 days)
DELETE FROM product_views 
WHERE viewed_at < DATE_SUB(NOW(), INTERVAL 90 DAY);

-- Delete cancelled orders and their related data
DELETE oi FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'cancelled'
AND o.created_at < DATE_SUB(NOW(), INTERVAL 30 DAY);

DELETE FROM orders 
WHERE status = 'cancelled'
AND created_at < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- Delete inactive products (soft delete by setting is_active = FALSE)
UPDATE products 
SET is_active = FALSE,
    updated_at = CURRENT_TIMESTAMP
WHERE inventory_quantity = 0
AND created_at < DATE_SUB(NOW(), INTERVAL 180 DAY)
AND product_id NOT IN (
    SELECT DISTINCT product_id 
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
);

-- =============================================================================
-- Data Validation and Cleanup Operations
-- =============================================================================

-- Fix orphaned order items
UPDATE order_items oi
SET product_name = (
    SELECT p.product_name
    FROM products p
    WHERE p.product_id = oi.product_id
),
product_sku = (
    SELECT COALESCE(pv.sku, p.sku)
    FROM products p
    LEFT JOIN product_variants pv ON pv.variant_id = oi.variant_id
    WHERE p.product_id = oi.product_id
)
WHERE oi.product_id IN (
    SELECT product_id 
    FROM products 
    WHERE is_active = TRUE
);

-- Clean up invalid email addresses
UPDATE users 
SET email = CONCAT('invalid_', user_id, '@example.com'),
    updated_at = CURRENT_TIMESTAMP
WHERE email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$';

-- Fix negative inventory quantities
UPDATE products 
SET inventory_quantity = 0,
    updated_at = CURRENT_TIMESTAMP
WHERE inventory_quantity < 0;

-- Update order totals to match order items
UPDATE orders o
SET subtotal = (
    SELECT COALESCE(SUM(total_price), 0)
    FROM order_items oi
    WHERE oi.order_id = o.order_id
),
total_amount = (
    SELECT COALESCE(SUM(total_price), 0) + o.tax_amount + o.shipping_amount - o.discount_amount
    FROM order_items oi
    WHERE oi.order_id = o.order_id
),
updated_at = CURRENT_TIMESTAMP;

-- =============================================================================
-- Data Migration Operations
-- =============================================================================

-- Migrate old product data to new schema
INSERT INTO product_attribute_values (product_id, attribute_id, attribute_value)
SELECT 
    p.product_id,
    pa.attribute_id,
    CASE 
        WHEN pa.attribute_name = 'Color' THEN 'Default'
        WHEN pa.attribute_name = 'Size' THEN 'One Size'
        WHEN pa.attribute_name = 'Storage' THEN 'Standard'
        ELSE 'N/A'
    END
FROM products p
CROSS JOIN product_attributes pa
WHERE p.product_id NOT IN (
    SELECT DISTINCT product_id 
    FROM product_attribute_values
);

-- Migrate user preferences to new format
INSERT INTO user_preferences (user_id, preference_key, preference_value, data_type)
SELECT 
    u.user_id,
    'legacy_migration',
    'true',
    'boolean'
FROM users u
WHERE u.created_at < '2024-01-01'
AND u.user_id NOT IN (
    SELECT DISTINCT user_id 
    FROM user_preferences 
    WHERE preference_key = 'legacy_migration'
);

-- =============================================================================
-- End of DML Script
-- =============================================================================
