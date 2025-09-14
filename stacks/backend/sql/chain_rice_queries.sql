-- =============================================================================
-- Chain Rice Database - DQL (Data Query Language)
-- =============================================================================
-- This file contains comprehensive DQL statements for the Chain Rice database,
-- including complex queries, analytics, reporting, and data analysis operations.
--
-- Database: Chain Rice E-commerce Platform
-- Version: 1.0.0
-- Author: Chain Rice Development Team
-- =============================================================================

-- =============================================================================
-- Basic Query Operations
-- =============================================================================

-- Get all active products with their categories and brands
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    p.price,
    p.inventory_quantity,
    c.category_name,
    b.brand_name,
    p.created_at
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
WHERE p.is_active = TRUE
ORDER BY p.created_at DESC;

-- Get user information with their default address
SELECT 
    u.user_id,
    u.username,
    u.email,
    u.first_name,
    u.last_name,
    u.last_login_at,
    ua.street_address,
    ua.city,
    ua.state_province,
    ua.postal_code,
    ua.country
FROM users u
LEFT JOIN user_addresses ua ON u.user_id = ua.user_id AND ua.is_default = TRUE
WHERE u.is_active = TRUE
ORDER BY u.created_at DESC;

-- Get order details with customer information
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
GROUP BY o.order_id, o.order_number, o.status, o.total_amount, o.created_at, u.username, u.email
ORDER BY o.created_at DESC;

-- =============================================================================
-- Advanced Query Operations
-- =============================================================================

-- Top selling products with revenue analysis
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    COUNT(oi.item_id) as total_orders,
    SUM(oi.quantity) as total_quantity_sold,
    SUM(oi.total_price) as total_revenue,
    AVG(oi.unit_price) as avg_selling_price,
    p.price as current_price,
    ROUND((SUM(oi.total_price) / COUNT(oi.item_id)), 2) as avg_order_value
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status IN ('delivered', 'shipped')
AND o.created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY p.product_id, p.product_name, p.sku, p.price
HAVING total_orders >= 1
ORDER BY total_revenue DESC
LIMIT 20;

-- Customer lifetime value analysis
SELECT 
    u.user_id,
    u.username,
    u.email,
    u.created_at as customer_since,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.total_amount) as lifetime_value,
    AVG(o.total_amount) as avg_order_value,
    MAX(o.created_at) as last_order_date,
    DATEDIFF(NOW(), MAX(o.created_at)) as days_since_last_order,
    CASE 
        WHEN DATEDIFF(NOW(), MAX(o.created_at)) <= 30 THEN 'Active'
        WHEN DATEDIFF(NOW(), MAX(o.created_at)) <= 90 THEN 'At Risk'
        WHEN DATEDIFF(NOW(), MAX(o.created_at)) <= 180 THEN 'Inactive'
        ELSE 'Lost'
    END as customer_status
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE u.is_active = TRUE
GROUP BY u.user_id, u.username, u.email, u.created_at
HAVING total_orders > 0
ORDER BY lifetime_value DESC;

-- Product performance by category
SELECT 
    c.category_name,
    COUNT(DISTINCT p.product_id) as total_products,
    COUNT(DISTINCT CASE WHEN p.is_active = TRUE THEN p.product_id END) as active_products,
    COUNT(DISTINCT CASE WHEN p.is_featured = TRUE THEN p.product_id END) as featured_products,
    SUM(p.inventory_quantity) as total_inventory,
    AVG(p.price) as avg_price,
    MIN(p.price) as min_price,
    MAX(p.price) as max_price,
    SUM(CASE WHEN oi.item_id IS NOT NULL THEN oi.total_price ELSE 0 END) as category_revenue
FROM categories c
LEFT JOIN products p ON c.category_id = p.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status IN ('delivered', 'shipped')
WHERE c.is_active = TRUE
GROUP BY c.category_id, c.category_name
ORDER BY category_revenue DESC;

-- Monthly sales trend analysis
SELECT 
    DATE_FORMAT(o.created_at, '%Y-%m') as month,
    COUNT(DISTINCT o.order_id) as total_orders,
    COUNT(DISTINCT o.user_id) as unique_customers,
    SUM(o.total_amount) as total_revenue,
    AVG(o.total_amount) as avg_order_value,
    SUM(oi.quantity) as total_items_sold,
    COUNT(DISTINCT oi.product_id) as unique_products_sold
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status IN ('delivered', 'shipped')
AND o.created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(o.created_at, '%Y-%m')
ORDER BY month DESC;

-- =============================================================================
-- Complex Analytics Queries
-- =============================================================================

-- Customer segmentation analysis
SELECT 
    CASE 
        WHEN SUM(o.total_amount) >= 1000 THEN 'High Value'
        WHEN SUM(o.total_amount) >= 500 THEN 'Medium Value'
        WHEN SUM(o.total_amount) >= 100 THEN 'Low Value'
        ELSE 'New Customer'
    END as customer_segment,
    COUNT(DISTINCT u.user_id) as customer_count,
    ROUND(AVG(SUM(o.total_amount)), 2) as avg_segment_value,
    ROUND(SUM(SUM(o.total_amount)) / (SELECT SUM(total_amount) FROM orders WHERE status IN ('delivered', 'shipped')) * 100, 2) as revenue_percentage
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id AND o.status IN ('delivered', 'shipped')
WHERE u.is_active = TRUE
GROUP BY u.user_id
HAVING SUM(o.total_amount) > 0
ORDER BY avg_segment_value DESC;

-- Product recommendation engine (customers who bought X also bought Y)
WITH customer_products AS (
    SELECT 
        o.user_id,
        oi.product_id,
        p.product_name
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.status IN ('delivered', 'shipped')
),
product_pairs AS (
    SELECT 
        cp1.product_id as product_a,
        cp2.product_id as product_b,
        COUNT(DISTINCT cp1.user_id) as co_purchase_count
    FROM customer_products cp1
    JOIN customer_products cp2 ON cp1.user_id = cp2.user_id
    WHERE cp1.product_id != cp2.product_id
    GROUP BY cp1.product_id, cp2.product_id
    HAVING co_purchase_count >= 2
)
SELECT 
    pa.product_a,
    p1.product_name as product_a_name,
    pa.product_b,
    p2.product_name as product_b_name,
    pa.co_purchase_count,
    ROUND(pa.co_purchase_count * 100.0 / (
        SELECT COUNT(DISTINCT user_id) 
        FROM customer_products 
        WHERE product_id = pa.product_a
    ), 2) as recommendation_score
FROM product_pairs pa
JOIN products p1 ON pa.product_a = p1.product_id
JOIN products p2 ON pa.product_b = p2.product_id
WHERE p1.is_active = TRUE AND p2.is_active = TRUE
ORDER BY recommendation_score DESC, co_purchase_count DESC
LIMIT 50;

-- Inventory turnover analysis
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    p.inventory_quantity as current_inventory,
    COALESCE(SUM(oi.quantity), 0) as total_sold_90_days,
    COALESCE(SUM(oi.quantity), 0) / 3 as monthly_avg_sales,
    CASE 
        WHEN COALESCE(SUM(oi.quantity), 0) = 0 THEN 'No Sales'
        WHEN p.inventory_quantity = 0 THEN 'Out of Stock'
        WHEN p.inventory_quantity / (COALESCE(SUM(oi.quantity), 0) / 3) <= 1 THEN 'Low Stock'
        WHEN p.inventory_quantity / (COALESCE(SUM(oi.quantity), 0) / 3) <= 3 THEN 'Adequate Stock'
        ELSE 'Overstocked'
    END as stock_status,
    CASE 
        WHEN COALESCE(SUM(oi.quantity), 0) = 0 THEN NULL
        ELSE ROUND(p.inventory_quantity / (COALESCE(SUM(oi.quantity), 0) / 3), 1)
    END as months_of_inventory
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id 
    AND o.status IN ('delivered', 'shipped')
    AND o.created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
WHERE p.is_active = TRUE
GROUP BY p.product_id, p.product_name, p.sku, p.inventory_quantity
ORDER BY months_of_inventory ASC;

-- =============================================================================
-- Reporting Queries
-- =============================================================================

-- Daily sales report
SELECT 
    DATE(o.created_at) as sale_date,
    COUNT(DISTINCT o.order_id) as orders_count,
    COUNT(DISTINCT o.user_id) as unique_customers,
    SUM(o.total_amount) as daily_revenue,
    AVG(o.total_amount) as avg_order_value,
    SUM(oi.quantity) as items_sold,
    COUNT(DISTINCT oi.product_id) as unique_products
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status IN ('delivered', 'shipped')
AND o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(o.created_at)
ORDER BY sale_date DESC;

-- Payment method analysis
SELECT 
    pm.method_name,
    pm.method_type,
    COUNT(p.payment_id) as transaction_count,
    SUM(p.amount) as total_amount,
    AVG(p.amount) as avg_transaction_amount,
    COUNT(CASE WHEN p.status = 'completed' THEN 1 END) as successful_transactions,
    COUNT(CASE WHEN p.status = 'failed' THEN 1 END) as failed_transactions,
    ROUND(COUNT(CASE WHEN p.status = 'completed' THEN 1 END) * 100.0 / COUNT(p.payment_id), 2) as success_rate
FROM payment_methods pm
LEFT JOIN payments p ON pm.method_id = p.method_id
WHERE p.created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY pm.method_id, pm.method_name, pm.method_type
ORDER BY total_amount DESC;

-- Geographic sales analysis
SELECT 
    oa.country,
    oa.state_province,
    COUNT(DISTINCT o.order_id) as orders_count,
    COUNT(DISTINCT o.user_id) as unique_customers,
    SUM(o.total_amount) as total_revenue,
    AVG(o.total_amount) as avg_order_value
FROM orders o
JOIN order_addresses oa ON o.order_id = oa.order_id AND oa.address_type = 'shipping'
WHERE o.status IN ('delivered', 'shipped')
AND o.created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY oa.country, oa.state_province
ORDER BY total_revenue DESC;

-- =============================================================================
-- Performance and Optimization Queries
-- =============================================================================

-- Slow moving products (products with low sales velocity)
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    p.price,
    p.inventory_quantity,
    COALESCE(SUM(oi.quantity), 0) as total_sold_90_days,
    COALESCE(SUM(oi.quantity), 0) / 3 as monthly_avg_sales,
    p.inventory_quantity / GREATEST(COALESCE(SUM(oi.quantity), 0) / 3, 1) as months_of_inventory,
    CASE 
        WHEN COALESCE(SUM(oi.quantity), 0) = 0 THEN 'No Sales'
        WHEN p.inventory_quantity / (COALESCE(SUM(oi.quantity), 0) / 3) > 12 THEN 'Very Slow Moving'
        WHEN p.inventory_quantity / (COALESCE(SUM(oi.quantity), 0) / 3) > 6 THEN 'Slow Moving'
        ELSE 'Normal'
    END as movement_status
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id 
    AND o.status IN ('delivered', 'shipped')
    AND o.created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
WHERE p.is_active = TRUE
GROUP BY p.product_id, p.product_name, p.sku, p.price, p.inventory_quantity
HAVING total_sold_90_days = 0 OR months_of_inventory > 6
ORDER BY months_of_inventory DESC;

-- Top performing categories by revenue and margin
SELECT 
    c.category_name,
    COUNT(DISTINCT p.product_id) as product_count,
    SUM(p.inventory_quantity * p.price) as inventory_value,
    SUM(oi.total_price) as total_revenue,
    SUM(oi.total_price - (oi.quantity * p.cost_price)) as total_margin,
    ROUND(SUM(oi.total_price - (oi.quantity * p.cost_price)) / SUM(oi.total_price) * 100, 2) as margin_percentage,
    AVG(p.price) as avg_product_price
FROM categories c
JOIN products p ON c.category_id = p.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status IN ('delivered', 'shipped')
WHERE c.is_active = TRUE AND p.is_active = TRUE
GROUP BY c.category_id, c.category_name
HAVING total_revenue > 0
ORDER BY total_margin DESC;

-- =============================================================================
-- Data Quality and Validation Queries
-- =============================================================================

-- Data integrity checks
SELECT 
    'Orphaned Order Items' as check_type,
    COUNT(*) as issue_count
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL

UNION ALL

SELECT 
    'Orphaned Product Variants' as check_type,
    COUNT(*) as issue_count
FROM product_variants pv
LEFT JOIN products p ON pv.product_id = p.product_id
WHERE p.product_id IS NULL

UNION ALL

SELECT 
    'Negative Inventory' as check_type,
    COUNT(*) as issue_count
FROM products
WHERE inventory_quantity < 0

UNION ALL

SELECT 
    'Invalid Email Addresses' as check_type,
    COUNT(*) as issue_count
FROM users
WHERE email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'

UNION ALL

SELECT 
    'Orders Without Items' as check_type,
    COUNT(*) as issue_count
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL;

-- Duplicate data detection
SELECT 
    'Duplicate SKUs' as check_type,
    sku,
    COUNT(*) as duplicate_count
FROM products
GROUP BY sku
HAVING COUNT(*) > 1

UNION ALL

SELECT 
    'Duplicate Emails' as check_type,
    email,
    COUNT(*) as duplicate_count
FROM users
GROUP BY email
HAVING COUNT(*) > 1

UNION ALL

SELECT 
    'Duplicate Order Numbers' as check_type,
    order_number,
    COUNT(*) as duplicate_count
FROM orders
GROUP BY order_number
HAVING COUNT(*) > 1;

-- =============================================================================
-- Business Intelligence Queries
-- =============================================================================

-- Customer acquisition and retention analysis
WITH customer_cohorts AS (
    SELECT 
        u.user_id,
        DATE_FORMAT(u.created_at, '%Y-%m') as cohort_month,
        DATE_FORMAT(o.created_at, '%Y-%m') as order_month,
        COUNT(DISTINCT o.order_id) as orders_in_month
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id 
        AND o.status IN ('delivered', 'shipped')
    WHERE u.created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
    GROUP BY u.user_id, cohort_month, order_month
)
SELECT 
    cohort_month,
    COUNT(DISTINCT user_id) as cohort_size,
    COUNT(DISTINCT CASE WHEN order_month = cohort_month THEN user_id END) as month_0_orders,
    COUNT(DISTINCT CASE WHEN order_month = DATE_ADD(cohort_month, INTERVAL 1 MONTH) THEN user_id END) as month_1_orders,
    COUNT(DISTINCT CASE WHEN order_month = DATE_ADD(cohort_month, INTERVAL 2 MONTH) THEN user_id END) as month_2_orders,
    COUNT(DISTINCT CASE WHEN order_month = DATE_ADD(cohort_month, INTERVAL 3 MONTH) THEN user_id END) as month_3_orders
FROM customer_cohorts
GROUP BY cohort_month
ORDER BY cohort_month DESC;

-- Product cross-selling analysis
WITH product_combinations AS (
    SELECT 
        o.order_id,
        GROUP_CONCAT(DISTINCT oi.product_id ORDER BY oi.product_id) as product_list,
        COUNT(DISTINCT oi.product_id) as product_count
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status IN ('delivered', 'shipped')
    GROUP BY o.order_id
    HAVING product_count > 1
)
SELECT 
    product_list,
    COUNT(*) as combination_frequency,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM product_combinations), 2) as percentage_of_multi_product_orders
FROM product_combinations
GROUP BY product_list
ORDER BY combination_frequency DESC
LIMIT 20;

-- =============================================================================
-- End of DQL Script
-- =============================================================================
