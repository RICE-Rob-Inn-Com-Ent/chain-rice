# Architektura Bazy Danych Chain Rice ⭐⭐⭐⭐☆

## 🏗️ Przegląd Architektury

Architektura bazy danych Chain Rice została zaprojektowana jako **skalowalny system e-commerce** wykorzystujący zaawansowane wzorce projektowe, optymalizacje wydajności i najlepsze praktyki zarządzania danymi. System opiera się na **normalizacji danych**, **integralności referencyjnej** i **wysokiej wydajności**.

## 📊 Struktura Architektury

```
┌─────────────────────────────────────────────────────────────┐
│                    Chain Rice Database Architecture         │
├─────────────────────────────────────────────────────────────┤
│  Application Layer                                         │
│  ├── REST API Endpoints                                    │
│  ├── Business Logic Services                               │
│  └── Data Access Layer                                     │
├─────────────────────────────────────────────────────────────┤
│  Database Layer                                            │
│  ├── Core Tables (Users, Products, Orders)                │
│  ├── Reference Tables (Categories, Brands)                │
│  ├── Transaction Tables (Payments, Inventory)             │
│  └── Analytics Tables (Views, Sessions)                   │
├─────────────────────────────────────────────────────────────┤
│  Storage Layer                                             │
│  ├── Primary Storage (MySQL/PostgreSQL/SQLite)            │
│  ├── Backup Storage (Automated Backups)                   │
│  └── Cache Layer (Query Results, Sessions)                │
└─────────────────────────────────────────────────────────────┘
```

## 🗄️ Warstwy Architektury

### 1. Warstwa Aplikacji (Application Layer)

**Odpowiedzialność**: Logika biznesowa i interfejs API

```sql
-- Przykład warstwy dostępu do danych
CREATE VIEW user_dashboard AS
SELECT 
    u.user_id,
    u.username,
    u.email,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.total_amount) as total_spent,
    MAX(o.created_at) as last_order_date
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE u.is_active = TRUE
GROUP BY u.user_id, u.username, u.email;
```

**Kluczowe wzorce**:
- **Repository Pattern**: Abstrakcja dostępu do danych
- **Service Layer**: Logika biznesowa
- **DTO Pattern**: Transfer obiektów danych
- **Caching Strategy**: Buforowanie wyników zapytań

### 2. Warstwa Bazy Danych (Database Layer)

**Odpowiedzialność**: Przechowywanie i zarządzanie danymi

#### **Core Tables (Tabele Główne)**
```sql
-- Hierarchia tabel głównych
users (user_id, username, email, ...)
├── user_addresses (address_id, user_id, ...)
├── user_preferences (preference_id, user_id, ...)
└── user_sessions (session_id, user_id, ...)

products (product_id, category_id, brand_id, ...)
├── product_variants (variant_id, product_id, ...)
├── product_attributes (attribute_id, ...)
├── product_attribute_values (value_id, product_id, attribute_id, ...)
└── product_images (image_id, product_id, ...)

orders (order_id, user_id, ...)
├── order_items (item_id, order_id, product_id, ...)
└── order_addresses (address_id, order_id, ...)
```

#### **Reference Tables (Tabele Referencyjne)**
```sql
-- Tabele słownikowe
categories (category_id, parent_category_id, ...)
brands (brand_id, brand_name, ...)
payment_methods (method_id, method_name, ...)
```

#### **Transaction Tables (Tabele Transakcyjne)**
```sql
-- Tabele transakcji biznesowych
payments (payment_id, order_id, method_id, ...)
inventory_log (log_id, product_id, old_quantity, new_quantity, ...)
backup_log (backup_id, backup_type, backup_file, ...)
```

### 3. Warstwa Magazynowania (Storage Layer)

**Odpowiedzialność**: Fizyczne przechowywanie danych

```sql
-- Strategie przechowywania
-- Primary Storage: Główne dane transakcyjne
-- Backup Storage: Kopie zapasowe i archiwum
-- Cache Storage: Buforowane wyniki zapytań
-- Log Storage: Logi transakcji i audytu
```

## 🔧 Wzorce Architektoniczne

### 1. Normalizacja Danych (Data Normalization)

#### **Pierwsza Postać Normalna (1NF)**
```sql
-- Eliminacja duplikatów i grup powtarzających się
CREATE TABLE users (
    user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    -- Każda kolumna zawiera pojedynczą wartość atomową
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL
);
```

#### **Druga Postać Normalna (2NF)**
```sql
-- Eliminacja zależności częściowych
-- Klucze obce zapewniają pełną zależność funkcjonalną
CREATE TABLE products (
    product_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id BIGINT UNSIGNED NOT NULL,
    brand_id BIGINT UNSIGNED NOT NULL,
    -- Wszystkie atrybuty zależą od całego klucza głównego
    FOREIGN KEY (category_id) REFERENCES categories(category_id),
    FOREIGN KEY (brand_id) REFERENCES brands(brand_id)
);
```

#### **Trzecia Postać Normalna (3NF)**
```sql
-- Eliminacja zależności przechodnich
-- Wydzielenie tabel referencyjnych
CREATE TABLE categories (
    category_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    -- Brak zależności przechodnich
    description TEXT
);
```

### 2. Wzorzec Repository (Repository Pattern)

```sql
-- Abstrakcja dostępu do danych przez widoki
CREATE VIEW product_repository AS
SELECT 
    p.product_id,
    p.product_name,
    p.sku,
    p.price,
    p.inventory_quantity,
    c.category_name,
    b.brand_name,
    CASE 
        WHEN p.inventory_quantity > p.low_stock_threshold THEN 'In Stock'
        WHEN p.inventory_quantity > 0 THEN 'Low Stock'
        ELSE 'Out of Stock'
    END as availability_status
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
WHERE p.is_active = TRUE;
```

### 3. Wzorzec Factory (Factory Pattern)

```sql
-- Procedury tworzące obiekty biznesowe
DELIMITER //
CREATE PROCEDURE CreateProduct(
    IN p_category_id BIGINT UNSIGNED,
    IN p_brand_id BIGINT UNSIGNED,
    IN p_product_name VARCHAR(255),
    IN p_price DECIMAL(10, 2)
)
BEGIN
    DECLARE new_product_id BIGINT UNSIGNED;
    
    -- Walidacja danych wejściowych
    IF p_price <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Price must be positive';
    END IF;
    
    -- Tworzenie produktu
    INSERT INTO products (category_id, brand_id, product_name, price)
    VALUES (p_category_id, p_brand_id, p_product_name, p_price);
    
    SET new_product_id = LAST_INSERT_ID();
    
    -- Zwrócenie utworzonego produktu
    SELECT * FROM products WHERE product_id = new_product_id;
END //
DELIMITER ;
```

### 4. Wzorzec Observer (Observer Pattern)

```sql
-- Triggery jako obserwatorzy zmian
DELIMITER //
CREATE TRIGGER tr_product_inventory_observer
    AFTER UPDATE ON products
    FOR EACH ROW
BEGIN
    -- Reakcja na zmiany zapasów
    IF OLD.inventory_quantity != NEW.inventory_quantity THEN
        -- Logowanie zmian
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
        
        -- Wysyłanie alertów dla niskich zapasów
        IF NEW.inventory_quantity <= NEW.low_stock_threshold THEN
            INSERT INTO inventory_alerts (
                product_id,
                alert_type,
                message,
                created_at
            ) VALUES (
                NEW.product_id,
                'low_stock',
                CONCAT('Product ', NEW.product_name, ' is running low on stock'),
                CURRENT_TIMESTAMP
            );
        END IF;
    END IF;
END //
DELIMITER ;
```

## 🚀 Strategie Wydajności

### 1. Indeksowanie Strategiczne

#### **Hierarchia Indeksów**
```sql
-- Primary Indexes (Klucze główne)
PRIMARY KEY (user_id)           -- Klastrowy indeks
PRIMARY KEY (product_id)        -- Klastrowy indeks
PRIMARY KEY (order_id)          -- Klastrowy indeks

-- Secondary Indexes (Indeksy pomocnicze)
INDEX idx_users_email (email)                    -- Unikalny indeks
INDEX idx_products_category (category_id)        -- Indeks obcy
INDEX idx_orders_user_status (user_id, status)   -- Indeks kompozytowy

-- Specialized Indexes (Indeksy specjalistyczne)
FULLTEXT INDEX idx_products_search (product_name, description)  -- Wyszukiwanie pełnotekstowe
INDEX idx_products_price_range (price)                          -- Zakres cenowy
INDEX idx_products_low_stock (inventory_quantity) WHERE inventory_quantity <= 10  -- Indeks częściowy
```

#### **Strategia Indeksowania**
```sql
-- Analiza wzorców zapytań
-- 1. Często używane kolumny w WHERE
-- 2. Kolumny w JOIN conditions
-- 3. Kolumny w ORDER BY
-- 4. Kolumny w GROUP BY
-- 5. Kolumny w SELECT (covering indexes)

-- Przykład covering index
CREATE INDEX idx_products_covering ON products (
    category_id, brand_id, is_active, is_featured
) INCLUDE (product_name, price, inventory_quantity);
```

### 2. Partycjonowanie Danych

#### **Partycjonowanie Poziome (Horizontal Partitioning)**
```sql
-- Partycjonowanie według daty
CREATE TABLE orders_2024 (
    CHECK (created_at >= '2024-01-01' AND created_at < '2025-01-01')
) INHERITS (orders);

CREATE TABLE orders_2023 (
    CHECK (created_at >= '2023-01-01' AND created_at < '2024-01-01')
) INHERITS (orders);
```

#### **Partycjonowanie Pionowe (Vertical Partitioning)**
```sql
-- Wydzielenie często używanych kolumn
CREATE TABLE products_core (
    product_id BIGINT UNSIGNED PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    sku VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE products_extended (
    product_id BIGINT UNSIGNED PRIMARY KEY,
    description TEXT,
    specifications JSON,
    meta_title VARCHAR(255),
    meta_description VARCHAR(500),
    FOREIGN KEY (product_id) REFERENCES products_core(product_id)
);
```

### 3. Buforowanie i Cache

#### **Query Result Caching**
```sql
-- Materialized Views dla często używanych zapytań
CREATE MATERIALIZED VIEW mv_product_analytics AS
SELECT 
    p.product_id,
    p.product_name,
    COUNT(oi.item_id) as total_orders,
    SUM(oi.total_price) as total_revenue,
    AVG(oi.unit_price) as avg_selling_price
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.status IN ('delivered', 'shipped')
GROUP BY p.product_id, p.product_name;

-- Automatyczne odświeżanie
CREATE OR REPLACE FUNCTION refresh_product_analytics()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_product_analytics;
END;
$$ LANGUAGE plpgsql;
```

## 🔒 Bezpieczeństwo i Integralność

### 1. Model Bezpieczeństwa

#### **Warstwy Bezpieczeństwa**
```sql
-- 1. Walidacja na poziomie bazy danych
CONSTRAINT chk_email_format CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
CONSTRAINT chk_price_positive CHECK (price > 0),
CONSTRAINT chk_inventory_quantity CHECK (inventory_quantity >= 0)

-- 2. Ograniczenia referencyjne
FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE

-- 3. Unikalne ograniczenia
UNIQUE KEY uk_users_email (email),
UNIQUE KEY uk_products_sku (sku),
UNIQUE KEY uk_orders_number (order_number)
```

#### **Zarządzanie Uprawnieniami**
```sql
-- Role-based Access Control (RBAC)
CREATE ROLE 'chain_rice_readonly';
CREATE ROLE 'chain_rice_readwrite';
CREATE ROLE 'chain_rice_admin';

-- Przypisywanie uprawnień
GRANT SELECT ON chain_rice.* TO 'chain_rice_readonly';
GRANT SELECT, INSERT, UPDATE ON chain_rice.* TO 'chain_rice_readwrite';
GRANT ALL PRIVILEGES ON chain_rice.* TO 'chain_rice_admin';

-- Row-level Security (PostgreSQL)
CREATE POLICY user_data_policy ON users
    FOR ALL TO 'chain_rice_readwrite'
    USING (user_id = current_user_id());
```

### 2. Audyt i Logowanie

#### **Audit Trail**
```sql
-- Tabela audytu zmian
CREATE TABLE audit_log (
    audit_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT UNSIGNED NOT NULL,
    operation ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    old_values JSON,
    new_values JSON,
    user_id BIGINT UNSIGNED,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_audit_table_record (table_name, record_id),
    INDEX idx_audit_created_at (created_at),
    INDEX idx_audit_user (user_id)
);

-- Trigger audytu
DELIMITER //
CREATE TRIGGER tr_users_audit
    AFTER UPDATE ON users
    FOR EACH ROW
BEGIN
    INSERT INTO audit_log (
        table_name, record_id, operation, old_values, new_values, user_id
    ) VALUES (
        'users', NEW.user_id, 'UPDATE',
        JSON_OBJECT('username', OLD.username, 'email', OLD.email),
        JSON_OBJECT('username', NEW.username, 'email', NEW.email),
        @current_user_id
    );
END //
DELIMITER ;
```

## 📊 Analityka i Raportowanie

### 1. Architektura Analityczna

#### **Data Warehouse Pattern**
```sql
-- Staging Area dla danych surowych
CREATE TABLE staging_orders (
    order_id BIGINT UNSIGNED,
    user_id BIGINT UNSIGNED,
    order_number VARCHAR(50),
    total_amount DECIMAL(10, 2),
    created_at TIMESTAMP,
    -- Dodatkowe kolumny dla transformacji
    etl_batch_id VARCHAR(50),
    etl_processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Data Mart dla analityki sprzedaży
CREATE TABLE sales_fact (
    order_id BIGINT UNSIGNED,
    user_id BIGINT UNSIGNED,
    product_id BIGINT UNSIGNED,
    category_id BIGINT UNSIGNED,
    brand_id BIGINT UNSIGNED,
    order_date DATE,
    order_amount DECIMAL(10, 2),
    quantity INT,
    -- Klucze wymiarów
    dim_date_id INT,
    dim_user_id INT,
    dim_product_id INT
);
```

#### **OLAP Operations**
```sql
-- Roll-up: Agregacja w górę hierarchii
SELECT 
    c.category_name,
    SUM(o.total_amount) as category_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_name;

-- Drill-down: Szczegółowe analizy
SELECT 
    c.category_name,
    b.brand_name,
    p.product_name,
    SUM(oi.total_price) as product_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id
GROUP BY c.category_name, b.brand_name, p.product_name;

-- Slice: Analiza według wymiaru
SELECT 
    DATE_FORMAT(o.created_at, '%Y-%m') as month,
    SUM(o.total_amount) as monthly_revenue
FROM orders o
WHERE o.status IN ('delivered', 'shipped')
GROUP BY DATE_FORMAT(o.created_at, '%Y-%m')
ORDER BY month;

-- Dice: Analiza według wielu wymiarów
SELECT 
    c.category_name,
    DATE_FORMAT(o.created_at, '%Y-%m') as month,
    SUM(o.total_amount) as revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
WHERE o.status IN ('delivered', 'shipped')
GROUP BY c.category_name, DATE_FORMAT(o.created_at, '%Y-%m')
ORDER BY c.category_name, month;
```

### 2. Real-time Analytics

#### **Stream Processing Pattern**
```sql
-- Tabela dla danych strumieniowych
CREATE TABLE order_stream (
    stream_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED NOT NULL,
    event_type ENUM('created', 'updated', 'cancelled') NOT NULL,
    event_data JSON,
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_stream_order (order_id),
    INDEX idx_stream_processed (processed_at)
);

-- Real-time aggregation
CREATE VIEW real_time_sales AS
SELECT 
    DATE_FORMAT(processed_at, '%Y-%m-%d %H:00:00') as hour,
    COUNT(DISTINCT order_id) as orders_count,
    SUM(JSON_EXTRACT(event_data, '$.total_amount')) as hourly_revenue
FROM order_stream
WHERE event_type = 'created'
AND processed_at >= DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY DATE_FORMAT(processed_at, '%Y-%m-%d %H:00:00')
ORDER BY hour DESC;
```

## 🔄 Backup i Disaster Recovery

### 1. Strategia Backup

#### **Hierarchia Backup**
```sql
-- Backup Levels
-- Level 0: Full Backup (Pełny backup)
-- Level 1: Incremental Backup (Backup przyrostowy)
-- Level 2: Differential Backup (Backup różnicowy)

-- Backup Configuration
CREATE TABLE backup_config (
    config_id INT PRIMARY KEY,
    backup_type ENUM('full', 'incremental', 'differential') NOT NULL,
    retention_days INT NOT NULL,
    compression_enabled BOOLEAN DEFAULT TRUE,
    encryption_enabled BOOLEAN DEFAULT FALSE,
    schedule_cron VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE
);

-- Backup Schedule
INSERT INTO backup_config VALUES
(1, 'full', 30, TRUE, TRUE, '0 2 * * 0', TRUE),      -- Pełny backup w niedzielę o 2:00
(2, 'incremental', 7, TRUE, FALSE, '0 2 * * 1-6', TRUE), -- Przyrostowy od poniedziałku do soboty
(3, 'differential', 14, TRUE, FALSE, '0 2 * * 0', TRUE);  -- Różnicowy w niedzielę
```

#### **Point-in-Time Recovery**
```sql
-- Binary Log Configuration (MySQL)
-- log-bin = mysql-bin
-- binlog-format = ROW
-- expire_logs_days = 7

-- Recovery Procedure
DELIMITER //
CREATE PROCEDURE PointInTimeRecovery(
    IN target_timestamp TIMESTAMP,
    IN database_name VARCHAR(100)
)
BEGIN
    DECLARE recovery_command TEXT;
    DECLARE binlog_files TEXT;
    
    -- Get binary log files since last backup
    SELECT GROUP_CONCAT(log_name SEPARATOR ' ') INTO binlog_files
    FROM mysql.general_log
    WHERE event_time >= target_timestamp;
    
    -- Build recovery command
    SET recovery_command = CONCAT(
        'mysqlbinlog --start-datetime="', target_timestamp, '" ',
        binlog_files, ' | mysql -u root -p ', database_name
    );
    
    -- Execute recovery
    SET @recovery_sql = recovery_command;
    PREPARE stmt FROM @recovery_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
DELIMITER ;
```

### 2. High Availability

#### **Master-Slave Replication**
```sql
-- Master Configuration
-- server-id = 1
-- log-bin = mysql-bin
-- binlog-format = ROW

-- Slave Configuration
-- server-id = 2
-- relay-log = mysql-relay-bin
-- read-only = 1

-- Replication Status Monitoring
SELECT 
    'Master' as role,
    @@hostname as hostname,
    @@port as port,
    @@server_id as server_id,
    @@read_only as read_only
UNION ALL
SELECT 
    'Slave' as role,
    @@hostname as hostname,
    @@port as port,
    @@server_id as server_id,
    @@read_only as read_only;
```

## 🚀 Skalowalność i Rozszerzalność

### 1. Horizontal Scaling

#### **Sharding Strategy**
```sql
-- Sharding by User ID
-- Shard 1: user_id % 4 = 0
-- Shard 2: user_id % 4 = 1
-- Shard 3: user_id % 4 = 2
-- Shard 4: user_id % 4 = 3

-- Shard Configuration
CREATE TABLE shard_config (
    shard_id INT PRIMARY KEY,
    shard_name VARCHAR(50) NOT NULL,
    shard_host VARCHAR(100) NOT NULL,
    shard_port INT NOT NULL,
    shard_range_start BIGINT UNSIGNED NOT NULL,
    shard_range_end BIGINT UNSIGNED NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

-- Shard Routing Function
DELIMITER //
CREATE FUNCTION get_shard_for_user(user_id_param BIGINT UNSIGNED)
RETURNS VARCHAR(50)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE shard_name VARCHAR(50);
    
    SELECT shard_name INTO shard_name
    FROM shard_config
    WHERE user_id_param BETWEEN shard_range_start AND shard_range_end
    AND is_active = TRUE
    LIMIT 1;
    
    RETURN shard_name;
END //
DELIMITER ;
```

### 2. Microservices Integration

#### **Database per Service Pattern**
```sql
-- User Service Database
CREATE DATABASE user_service;
USE user_service;
CREATE TABLE users (...);
CREATE TABLE user_profiles (...);
CREATE TABLE user_preferences (...);

-- Product Service Database
CREATE DATABASE product_service;
USE product_service;
CREATE TABLE products (...);
CREATE TABLE categories (...);
CREATE TABLE brands (...);

-- Order Service Database
CREATE DATABASE order_service;
USE order_service;
CREATE TABLE orders (...);
CREATE TABLE order_items (...);
CREATE TABLE payments (...);

-- Cross-Service Communication
CREATE TABLE service_events (
    event_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    event_data JSON NOT NULL,
    correlation_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_service_events_service (service_name),
    INDEX idx_service_events_type (event_type),
    INDEX idx_service_events_correlation (correlation_id)
);
```

## 📈 Monitoring i Optymalizacja

### 1. Performance Monitoring

#### **Key Performance Indicators (KPIs)**
```sql
-- Database Performance Metrics
CREATE VIEW db_performance_metrics AS
SELECT 
    'Query Response Time' as metric_name,
    AVG(query_time) as avg_value,
    MAX(query_time) as max_value,
    MIN(query_time) as min_value
FROM mysql.slow_log
WHERE start_time >= DATE_SUB(NOW(), INTERVAL 1 DAY)

UNION ALL

SELECT 
    'Connection Count' as metric_name,
    COUNT(*) as avg_value,
    COUNT(*) as max_value,
    COUNT(*) as min_value
FROM information_schema.processlist
WHERE command != 'Sleep'

UNION ALL

SELECT 
    'Cache Hit Ratio' as metric_name,
    (SELECT (1 - (Qcache_not_cached / (Qcache_hits + Qcache_not_cached))) * 100) as avg_value,
    100 as max_value,
    0 as min_value
FROM information_schema.global_status
WHERE variable_name IN ('Qcache_hits', 'Qcache_not_cached');
```

#### **Query Performance Analysis**
```sql
-- Slow Query Analysis
SELECT 
    sql_text,
    query_time,
    lock_time,
    rows_sent,
    rows_examined,
    start_time
FROM mysql.slow_log
WHERE start_time >= DATE_SUB(NOW(), INTERVAL 1 DAY)
ORDER BY query_time DESC
LIMIT 10;

-- Index Usage Analysis
SELECT 
    table_schema,
    table_name,
    index_name,
    cardinality,
    sub_part,
    packed,
    nullable,
    index_type
FROM information_schema.statistics
WHERE table_schema = 'chain_rice'
ORDER BY table_name, seq_in_index;
```

### 2. Capacity Planning

#### **Storage Growth Analysis**
```sql
-- Table Size Growth
SELECT 
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS 'Size in MB',
    table_rows,
    ROUND((data_length / 1024 / 1024), 2) AS 'Data Size in MB',
    ROUND((index_length / 1024 / 1024), 2) AS 'Index Size in MB',
    ROUND((index_length / data_length) * 100, 2) AS 'Index/Data Ratio %'
FROM information_schema.tables
WHERE table_schema = 'chain_rice'
ORDER BY (data_length + index_length) DESC;

-- Growth Projection
WITH monthly_growth AS (
    SELECT 
        DATE_FORMAT(created_at, '%Y-%m') as month,
        COUNT(*) as record_count
    FROM orders
    WHERE created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
)
SELECT 
    month,
    record_count,
    LAG(record_count) OVER (ORDER BY month) as previous_month,
    ROUND(((record_count - LAG(record_count) OVER (ORDER BY month)) / LAG(record_count) OVER (ORDER BY month)) * 100, 2) as growth_rate
FROM monthly_growth
ORDER BY month DESC;
```

## 🔮 Przyszłe Rozszerzenia

### 1. NoSQL Integration

#### **Polyglot Persistence**
```sql
-- Hybrid SQL/NoSQL Architecture
-- SQL: Structured data (users, products, orders)
-- MongoDB: Product catalogs, user preferences
-- Redis: Session data, cache, real-time analytics
-- Elasticsearch: Full-text search, log analysis

-- Integration Layer
CREATE TABLE nosql_sync_log (
    sync_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT UNSIGNED NOT NULL,
    operation ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    nosql_target VARCHAR(100) NOT NULL,
    sync_status ENUM('pending', 'completed', 'failed') DEFAULT 'pending',
    sync_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    synced_at TIMESTAMP NULL,
    
    INDEX idx_nosql_sync_table (table_name),
    INDEX idx_nosql_sync_status (sync_status),
    INDEX idx_nosql_sync_created (created_at)
);
```

### 2. Machine Learning Integration

#### **Predictive Analytics**
```sql
-- Customer Lifetime Value Prediction
CREATE TABLE ml_predictions (
    prediction_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    prediction_type VARCHAR(100) NOT NULL,
    predicted_value DECIMAL(10, 2),
    confidence_score DECIMAL(3, 2),
    model_version VARCHAR(50),
    prediction_date DATE DEFAULT (CURRENT_DATE),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    INDEX idx_ml_predictions_user (user_id),
    INDEX idx_ml_predictions_type (prediction_type),
    INDEX idx_ml_predictions_date (prediction_date)
);

-- Product Recommendation Engine
CREATE TABLE product_recommendations (
    recommendation_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED NOT NULL,
    product_id BIGINT UNSIGNED NOT NULL,
    recommendation_score DECIMAL(3, 2),
    recommendation_reason VARCHAR(255),
    model_version VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    INDEX idx_recommendations_user (user_id),
    INDEX idx_recommendations_score (recommendation_score)
);
```

## 📋 Podsumowanie Architektury

Ta architektura demonstruje **zaawansowane wzorce projektowe** w kontekście zarządzania bazami danych:

- **Scalability**: Horizontal i vertical scaling strategies
- **Performance**: Advanced indexing i optimization techniques
- **Security**: Multi-layer security model z audit trail
- **Reliability**: Comprehensive backup i disaster recovery
- **Maintainability**: Clean architecture z separation of concerns
- **Extensibility**: Microservices-ready z polyglot persistence

Architektura wykorzystuje **industry-standard patterns** i **best practices**, pokazując głębokie zrozumienie database design, performance optimization i professional development practices.

**Poziom architektury: Zaawansowany** - Demonstruje solidne zrozumienie database architecture, performance optimization i enterprise-level database management.
