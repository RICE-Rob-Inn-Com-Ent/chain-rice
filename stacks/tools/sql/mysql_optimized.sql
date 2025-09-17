-- =============================================================================
-- Chain Rice Database - MySQL Specific Scripts
-- =============================================================================
-- This file contains MySQL-specific SQL statements, optimizations, and features
-- for the Chain Rice e-commerce platform.
--
-- Database: MySQL 8.0+
-- Version: 1.0.0
-- Author: Chain Rice Development Team
-- =============================================================================

-- =============================================================================
-- MySQL Configuration and Setup
-- =============================================================================

-- Set MySQL session variables for optimal performance
SET SESSION sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO';
SET SESSION innodb_lock_wait_timeout = 50;
SET SESSION lock_wait_timeout = 50;

-- Enable MySQL performance schema for monitoring
UPDATE performance_schema.setup_instruments 
SET ENABLED = 'YES', TIMED = 'YES' 
WHERE NAME LIKE '%statement%';

-- =============================================================================
-- MySQL-Specific Data Types and Features
-- =============================================================================

-- Create optimized tables with MySQL-specific features
CREATE TABLE IF NOT EXISTS mysql_optimized_users (
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
    
    -- MySQL-specific indexes
    INDEX idx_users_email_hash (email(191)),  -- Partial index for long emails
    INDEX idx_users_username_hash (username),
    INDEX idx_users_active_created (is_active, created_at),
    INDEX idx_users_last_login (last_login_at),
    
    -- MySQL-specific constraints
    CONSTRAINT chk_email_format CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
    CONSTRAINT chk_username_length CHECK (CHAR_LENGTH(username) >= 3),
    CONSTRAINT chk_phone_format CHECK (phone IS NULL OR phone REGEXP '^\\+?[1-9]\\d{1,14}$')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create MySQL-optimized products table with JSON support
CREATE TABLE IF NOT EXISTS mysql_optimized_products (
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
    dimensions JSON,  -- MySQL 5.7+ JSON support
    specifications JSON,  -- Additional product specs
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
    
    -- MySQL-specific constraints
    CONSTRAINT chk_price_positive CHECK (price > 0),
    CONSTRAINT chk_compare_price CHECK (compare_price IS NULL OR compare_price > price),
    CONSTRAINT chk_cost_price CHECK (cost_price IS NULL OR cost_price >= 0),
    CONSTRAINT chk_weight_positive CHECK (weight IS NULL OR weight > 0),
    CONSTRAINT chk_inventory_quantity CHECK (inventory_quantity >= 0),
    CONSTRAINT chk_low_stock_threshold CHECK (low_stock_threshold >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- MySQL-Specific Stored Procedures
-- =============================================================================

-- MySQL procedure for bulk product updates with transaction safety
DELIMITER //
CREATE PROCEDURE BulkUpdateProductInventory(
    IN product_updates JSON
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE product_id_val BIGINT UNSIGNED;
    DECLARE quantity_change_val INT;
    DECLARE operation_val VARCHAR(20);
    DECLARE update_count INT DEFAULT 0;
    DECLARE error_count INT DEFAULT 0;
    
    DECLARE cur CURSOR FOR 
        SELECT 
            JSON_UNQUOTE(JSON_EXTRACT(product_updates, CONCAT('$[', idx, '].product_id'))) as product_id,
            JSON_UNQUOTE(JSON_EXTRACT(product_updates, CONCAT('$[', idx, '].quantity_change'))) as quantity_change,
            JSON_UNQUOTE(JSON_EXTRACT(product_updates, CONCAT('$[', idx, '].operation'))) as operation
        FROM (
            SELECT 0 as idx UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION
            SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION
            SELECT 10 UNION SELECT 11 UNION SELECT 12 UNION SELECT 13 UNION SELECT 14 UNION
            SELECT 15 UNION SELECT 16 UNION SELECT 17 UNION SELECT 18 UNION SELECT 19
        ) t
        WHERE JSON_EXTRACT(product_updates, CONCAT('$[', idx, '].product_id')) IS NOT NULL;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET error_count = error_count + 1;
    
    START TRANSACTION;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO product_id_val, quantity_change_val, operation_val;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        CASE operation_val
            WHEN 'add' THEN
                UPDATE mysql_optimized_products 
                SET inventory_quantity = inventory_quantity + quantity_change_val,
                    updated_at = CURRENT_TIMESTAMP
                WHERE product_id = product_id_val;
            WHEN 'subtract' THEN
                UPDATE mysql_optimized_products 
                SET inventory_quantity = GREATEST(inventory_quantity - quantity_change_val, 0),
                    updated_at = CURRENT_TIMESTAMP
                WHERE product_id = product_id_val;
            WHEN 'set' THEN
                UPDATE mysql_optimized_products 
                SET inventory_quantity = GREATEST(quantity_change_val, 0),
                    updated_at = CURRENT_TIMESTAMP
                WHERE product_id = product_id_val;
        END CASE;
        
        SET update_count = update_count + 1;
    END LOOP;
    
    CLOSE cur;
    
    IF error_count > 0 THEN
        ROLLBACK;
        SELECT 'ERROR' as status, error_count as errors, 0 as updated;
    ELSE
        COMMIT;
        SELECT 'SUCCESS' as status, 0 as errors, update_count as updated;
    END IF;
END //
DELIMITER ;

-- MySQL procedure for advanced product search with full-text search
DELIMITER //
CREATE PROCEDURE AdvancedProductSearch(
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
    
    -- Build WHERE clause
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
        WHEN 'popularity' THEN SET order_clause = CONCAT('ORDER BY COALESCE(popularity_score, 0) ', sort_direction);
        ELSE SET order_clause = 'ORDER BY p.created_at DESC';
    END CASE;
    
    -- Execute dynamic query
    SET @sql = CONCAT('
        SELECT 
            p.product_id,
            p.product_name,
            p.sku,
            p.price,
            p.compare_price,
            p.inventory_quantity,
            p.is_featured,
            c.category_name,
            b.brand_name,
            (
                SELECT COUNT(*)
                FROM order_items oi
                JOIN orders o ON oi.order_id = o.order_id
                WHERE oi.product_id = p.product_id
                AND o.status IN (''delivered'', ''shipped'')
                AND o.created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
            ) as popularity_score
        FROM mysql_optimized_products p
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

-- =============================================================================
-- MySQL-Specific Functions
-- =============================================================================

-- MySQL function to calculate product rating
DELIMITER //
CREATE FUNCTION CalculateProductRating(product_id_param BIGINT UNSIGNED)
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

-- MySQL function to get product availability status
DELIMITER //
CREATE FUNCTION GetProductAvailability(product_id_param BIGINT UNSIGNED)
RETURNS VARCHAR(20)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE inventory_qty INT DEFAULT 0;
    DECLARE low_stock_threshold INT DEFAULT 5;
    DECLARE allow_backorder_val BOOLEAN DEFAULT FALSE;
    
    SELECT inventory_quantity, low_stock_threshold, allow_backorder
    INTO inventory_qty, low_stock_threshold, allow_backorder_val
    FROM mysql_optimized_products
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

-- Trigger to automatically update product search index
DELIMITER //
CREATE TRIGGER tr_product_search_update
    AFTER UPDATE ON mysql_optimized_products
    FOR EACH ROW
BEGIN
    -- Update search index when product name or description changes
    IF OLD.product_name != NEW.product_name OR OLD.description != NEW.description THEN
        INSERT INTO product_search_log (
            product_id,
            action,
            old_name,
            new_name,
            updated_at
        ) VALUES (
            NEW.product_id,
            'search_index_update',
            OLD.product_name,
            NEW.product_name,
            CURRENT_TIMESTAMP
        );
    END IF;
END //
DELIMITER ;

-- Trigger to log inventory changes with detailed tracking
DELIMITER //
CREATE TRIGGER tr_product_inventory_change_log
    AFTER UPDATE ON mysql_optimized_products
    FOR EACH ROW
BEGIN
    IF OLD.inventory_quantity != NEW.inventory_quantity THEN
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
END //
DELIMITER ;

-- =============================================================================
-- MySQL-Specific Views
-- =============================================================================

-- View for product analytics with MySQL-specific functions
CREATE VIEW mysql_product_analytics AS
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    p.price,
    p.inventory_quantity,
    GetProductAvailability(p.product_id) as availability_status,
    CalculateProductRating(p.product_id) as avg_rating,
    c.category_name,
    b.brand_name,
    COALESCE(SUM(oi.total_price), 0) as total_revenue,
    COALESCE(SUM(oi.quantity), 0) as total_sold,
    COALESCE(COUNT(DISTINCT oi.order_id), 0) as order_count,
    COALESCE(AVG(oi.unit_price), 0) as avg_selling_price,
    p.created_at,
    p.updated_at
FROM mysql_optimized_products p
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id AND o.status IN ('delivered', 'shipped')
GROUP BY p.product_id, p.product_name, p.sku, p.price, p.inventory_quantity, c.category_name, b.brand_name, p.created_at, p.updated_at;

-- View for customer analytics with MySQL window functions
CREATE VIEW mysql_customer_analytics AS
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
    ROW_NUMBER() OVER (ORDER BY SUM(o.total_amount) DESC) as customer_rank,
    PERCENT_RANK() OVER (ORDER BY SUM(o.total_amount)) as customer_percentile,
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
-- MySQL Performance Optimization
-- =============================================================================

-- Create optimized indexes for common query patterns
CREATE INDEX idx_mysql_products_price_inventory ON mysql_optimized_products(price, inventory_quantity, is_active);
CREATE INDEX idx_mysql_products_category_brand_active ON mysql_optimized_products(category_id, brand_id, is_active);
CREATE INDEX idx_mysql_products_featured_created ON mysql_optimized_products(is_featured, created_at DESC);

-- Create covering indexes for frequently accessed columns
CREATE INDEX idx_mysql_products_covering ON mysql_optimized_products(
    product_id, product_name, sku, price, inventory_quantity, is_active, is_featured
);

-- Create partial indexes for specific conditions
CREATE INDEX idx_mysql_products_low_stock ON mysql_optimized_products(inventory_quantity, product_id)
WHERE inventory_quantity <= 10;

-- =============================================================================
-- MySQL Monitoring and Maintenance
-- =============================================================================

-- Query to analyze table sizes and storage usage
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size in MB',
    table_rows,
    ROUND((data_length / 1024 / 1024), 2) AS 'Data Size in MB',
    ROUND((index_length / 1024 / 1024), 2) AS 'Index Size in MB'
FROM information_schema.tables
WHERE table_schema = 'chain_rice'
ORDER BY (data_length + index_length) DESC;

-- Query to identify slow queries
SELECT 
    query_time,
    lock_time,
    rows_sent,
    rows_examined,
    sql_text
FROM mysql.slow_log
WHERE start_time >= DATE_SUB(NOW(), INTERVAL 1 DAY)
ORDER BY query_time DESC
LIMIT 10;

-- Query to check index usage
SELECT 
    object_schema,
    object_name,
    index_name,
    count_read,
    count_write,
    count_read + count_write as total_usage
FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE object_schema = 'chain_rice'
ORDER BY total_usage DESC;

-- =============================================================================
-- MySQL Backup and Recovery Procedures
-- =============================================================================

-- Procedure to create automated backup
DELIMITER //
CREATE PROCEDURE CreateAutomatedBackup()
BEGIN
    DECLARE backup_file VARCHAR(255);
    DECLARE backup_path VARCHAR(255);
    
    SET backup_path = '/var/backups/mysql/chain_rice/';
    SET backup_file = CONCAT(backup_path, 'chain_rice_backup_', DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s'), '.sql');
    
    -- Create backup using mysqldump (this would be called from application)
    SET @backup_command = CONCAT('mysqldump --single-transaction --routines --triggers chain_rice > ', backup_file);
    
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
    
    SELECT 'Backup initiated' as status, backup_file as file_path;
END //
DELIMITER ;

-- =============================================================================
-- End of MySQL Specific Script
-- =============================================================================
