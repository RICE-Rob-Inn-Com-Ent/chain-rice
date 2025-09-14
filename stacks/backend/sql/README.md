# Chain Rice SQL Database Collection ⭐⭐⭐⭐☆

## 🎯 Przegląd

Kolekcja SQL Chain Rice to **kompleksowy zestaw skryptów bazodanowych** dla platformy e-commerce, demonstrujący zaawansowane wzorce projektowe, optymalizacje wydajności i najlepsze praktyki w zarządzaniu bazami danych.

## 📁 Struktura Projektu

```
sql/
├── README.md                # Ta dokumentacja
├── ARCHITECTURE.md          # Dokumentacja architektury
├── example.ddl              # Skrypty DDL (Data Definition Language)
├── example.dml              # Skrypty DML (Data Manipulation Language)
├── example.dql              # Skrypty DQL (Data Query Language)
├── example.csv              # Przykładowe dane CSV
├── example.tsv              # Przykładowe dane TSV
├── example.mysql            # Skrypty specyficzne dla MySQL
├── example.psql             # Skrypty specyficzne dla PostgreSQL
├── example.sqlite           # Skrypty specyficzne dla SQLite
├── example.backup           # Skrypty backup i restore
└── example.dump             # Kompletny dump bazy danych
```

## 🚀 Kluczowe Funkcjonalności

### 📊 **Kompleksowy Schemat Bazy Danych**
- **Zarządzanie użytkownikami**: Użytkownicy, adresy, preferencje
- **Katalog produktów**: Produkty, kategorie, marki, warianty, atrybuty
- **Zarządzanie zamówieniami**: Zamówienia, pozycje zamówień, adresy
- **System płatności**: Metody płatności, transakcje
- **Analityka**: Sesje użytkowników, widoki produktów

### 🔧 **Zaawansowane Operacje SQL**
- **DDL**: Tworzenie tabel, indeksów, ograniczeń, widoków
- **DML**: Operacje CRUD, manipulacja danych, migracje
- **DQL**: Złożone zapytania, analityka, raportowanie
- **Procedury**: Automatyzacja operacji biznesowych
- **Triggery**: Automatyczne aktualizacje i walidacja

### 🗄️ **Wsparcie Multi-Database**
- **MySQL 8.0+**: Optymalizacje, JSON, full-text search
- **PostgreSQL 14+**: Zaawansowane funkcje, JSONB, FTS
- **SQLite 3.35+**: Mobilne rozwiązania, FTS5

### 💾 **System Backup i Recovery**
- **Backup pełny**: Kompletne kopie zapasowe
- **Backup przyrostowy**: Tylko zmiany od ostatniego backup
- **Point-in-time recovery**: Odzyskiwanie do konkretnego momentu
- **Weryfikacja integralności**: Sprawdzanie poprawności backup

## 📋 Szczegółowe Funkcjonalności

### 🏗️ **Architektura Bazy Danych**

#### **Tabele Główne**
```sql
-- Użytkownicy z pełną walidacją
users (user_id, username, email, password_hash, ...)

-- Hierarchiczna struktura kategorii
categories (category_id, parent_category_id, category_name, ...)

-- Produkty z wariantami i atrybutami
products (product_id, category_id, brand_id, product_name, ...)

-- Zamówienia z pełnym śledzeniem statusu
orders (order_id, user_id, order_number, status, ...)
```

#### **Relacje i Ograniczenia**
- **Foreign Keys**: Zapewnienie integralności referencyjnej
- **Check Constraints**: Walidacja danych na poziomie bazy
- **Unique Constraints**: Zapobieganie duplikatom
- **Indexes**: Optymalizacja wydajności zapytań

### 📈 **Analityka i Raportowanie**

#### **Widoki Analityczne**
```sql
-- Podsumowanie produktów
CREATE VIEW product_summary AS
SELECT p.product_id, p.product_name, p.price, c.category_name, b.brand_name
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN brands b ON p.brand_id = b.brand_id;

-- Aktywność użytkowników
CREATE VIEW user_activity AS
SELECT u.user_id, u.username, COUNT(o.order_id) as total_orders, SUM(o.total_amount) as total_spent
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
GROUP BY u.user_id, u.username;
```

#### **Zaawansowane Zapytania**
- **Customer Lifetime Value**: Analiza wartości klientów
- **Product Performance**: Wydajność sprzedażowa produktów
- **Inventory Turnover**: Analiza rotacji zapasów
- **Geographic Sales**: Sprzedaż według regionów
- **Cross-selling Analysis**: Analiza sprzedaży krzyżowej

### 🔍 **Optymalizacja Wydajności**

#### **Indeksy Strategiczne**
```sql
-- Indeksy kompozytowe dla częstych wzorców zapytań
CREATE INDEX idx_products_category_active ON products(category_id, is_active);
CREATE INDEX idx_orders_user_status ON orders(user_id, status);

-- Indeksy pełnotekstowe dla wyszukiwania
CREATE FULLTEXT INDEX idx_products_search ON products(product_name, description);

-- Indeksy częściowe dla specyficznych warunków
CREATE INDEX idx_products_low_stock ON products(inventory_quantity, product_id)
WHERE inventory_quantity <= 10;
```

#### **Optymalizacje Specyficzne dla Baz**
- **MySQL**: JSON indexes, generated columns, window functions
- **PostgreSQL**: JSONB indexes, GIN indexes, materialized views
- **SQLite**: FTS5 virtual tables, partial indexes, covering indexes

## 🛠️ Przykłady Użycia

### 🚀 **Szybki Start**

#### **1. Tworzenie Bazy Danych**
```sql
-- MySQL/PostgreSQL
CREATE DATABASE chain_rice CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE chain_rice;

-- SQLite
-- Automatycznie tworzy plik bazy danych
```

#### **2. Wykonanie Skryptów DDL**
```bash
# MySQL
mysql -u root -p chain_rice < example.ddl

# PostgreSQL
psql -U postgres -d chain_rice -f example.ddl

# SQLite
sqlite3 chain_rice.db < example.ddl
```

#### **3. Wstawienie Danych Próbnych**
```bash
# MySQL
mysql -u root -p chain_rice < example.dml

# PostgreSQL
psql -U postgres -d chain_rice -f example.dml

# SQLite
sqlite3 chain_rice.db < example.dml
```

### 📊 **Przykłady Zapytań**

#### **Top Produkty Według Sprzedaży**
```sql
SELECT 
    p.product_name,
    COUNT(oi.item_id) as total_orders,
    SUM(oi.total_price) as total_revenue,
    AVG(oi.unit_price) as avg_selling_price
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status IN ('delivered', 'shipped')
AND o.created_at >= DATE_SUB(NOW(), INTERVAL 90 DAY)
GROUP BY p.product_id, p.product_name
ORDER BY total_revenue DESC
LIMIT 10;
```

#### **Analiza Klientów**
```sql
SELECT 
    u.username,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.total_amount) as lifetime_value,
    CASE 
        WHEN SUM(o.total_amount) >= 1000 THEN 'High Value'
        WHEN SUM(o.total_amount) >= 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END as customer_segment
FROM users u
LEFT JOIN orders o ON u.user_id = o.user_id
WHERE u.is_active = TRUE
GROUP BY u.user_id, u.username
HAVING total_orders > 0
ORDER BY lifetime_value DESC;
```

#### **Alerty Zapasów**
```sql
SELECT 
    product_name,
    sku,
    inventory_quantity,
    low_stock_threshold,
    CASE 
        WHEN inventory_quantity = 0 THEN 'Out of Stock'
        WHEN inventory_quantity <= low_stock_threshold THEN 'Low Stock'
        ELSE 'In Stock'
    END as stock_status
FROM products
WHERE inventory_quantity <= low_stock_threshold
ORDER BY inventory_quantity ASC;
```

### 🔧 **Operacje Administracyjne**

#### **Backup Bazy Danych**
```sql
-- MySQL
CALL MySQL_FullBackup('/var/backups/mysql/chain_rice', 'chain_rice', TRUE, FALSE);

-- PostgreSQL
SELECT pg_full_backup('/var/backups/postgresql/chain_rice', 'chain_rice', TRUE, FALSE);

-- SQLite
-- .backup main backup_file.db
```

#### **Optymalizacja Wydajności**
```sql
-- MySQL
ANALYZE TABLE products, orders, users;
OPTIMIZE TABLE products, orders, users;

-- PostgreSQL
ANALYZE;
VACUUM ANALYZE;

-- SQLite
ANALYZE;
VACUUM;
REINDEX;
```

## 🎯 Zaawansowane Funkcje

### 🔍 **Wyszukiwanie Pełnotekstowe**

#### **MySQL Full-Text Search**
```sql
SELECT product_id, product_name, 
       MATCH(product_name, description) AGAINST('iPhone camera' IN NATURAL LANGUAGE MODE) as relevance
FROM products
WHERE MATCH(product_name, description) AGAINST('iPhone camera' IN NATURAL LANGUAGE MODE)
ORDER BY relevance DESC;
```

#### **PostgreSQL Full-Text Search**
```sql
SELECT product_id, product_name, 
       ts_rank(search_vector, plainto_tsquery('english', 'iPhone camera')) as relevance
FROM products
WHERE search_vector @@ plainto_tsquery('english', 'iPhone camera')
ORDER BY relevance DESC;
```

#### **SQLite FTS5**
```sql
SELECT product_id, product_name, rank
FROM fts_products
WHERE fts_products MATCH 'iPhone camera'
ORDER BY rank;
```

### 📊 **Analityka Biznesowa**

#### **Analiza Trendów Sprzedaży**
```sql
SELECT 
    DATE_FORMAT(o.created_at, '%Y-%m') as month,
    COUNT(DISTINCT o.order_id) as total_orders,
    SUM(o.total_amount) as total_revenue,
    AVG(o.total_amount) as avg_order_value
FROM orders o
WHERE o.status IN ('delivered', 'shipped')
AND o.created_at >= DATE_SUB(NOW(), INTERVAL 12 MONTH)
GROUP BY DATE_FORMAT(o.created_at, '%Y-%m')
ORDER BY month DESC;
```

#### **Segmentacja Klientów**
```sql
WITH customer_segments AS (
    SELECT 
        u.user_id,
        SUM(o.total_amount) as lifetime_value,
        COUNT(DISTINCT o.order_id) as order_count,
        DATEDIFF(NOW(), MAX(o.created_at)) as days_since_last_order
    FROM users u
    LEFT JOIN orders o ON u.user_id = o.user_id
    GROUP BY u.user_id
)
SELECT 
    CASE 
        WHEN lifetime_value >= 1000 AND days_since_last_order <= 30 THEN 'Champions'
        WHEN lifetime_value >= 500 AND days_since_last_order <= 60 THEN 'Loyal Customers'
        WHEN days_since_last_order <= 30 THEN 'New Customers'
        WHEN days_since_last_order > 180 THEN 'At Risk'
        ELSE 'Potential Loyalists'
    END as segment,
    COUNT(*) as customer_count,
    AVG(lifetime_value) as avg_value
FROM customer_segments
GROUP BY segment
ORDER BY avg_value DESC;
```

### 🔄 **Automatyzacja Operacji**

#### **Procedury Zarządzania Zapasami**
```sql
DELIMITER //
CREATE PROCEDURE UpdateProductInventory(
    IN p_product_id BIGINT UNSIGNED,
    IN p_quantity_change INT,
    IN p_operation ENUM('add', 'subtract', 'set')
)
BEGIN
    DECLARE current_quantity INT DEFAULT 0;
    DECLARE new_quantity INT DEFAULT 0;
    
    SELECT inventory_quantity INTO current_quantity
    FROM products WHERE product_id = p_product_id;
    
    CASE p_operation
        WHEN 'add' THEN SET new_quantity = current_quantity + p_quantity_change;
        WHEN 'subtract' THEN SET new_quantity = current_quantity - p_quantity_change;
        WHEN 'set' THEN SET new_quantity = p_quantity_change;
    END CASE;
    
    UPDATE products 
    SET inventory_quantity = GREATEST(new_quantity, 0),
        updated_at = CURRENT_TIMESTAMP
    WHERE product_id = p_product_id;
    
    SELECT new_quantity as new_inventory_quantity;
END //
DELIMITER ;
```

## 📈 Wydajność i Optymalizacja

### ⚡ **Strategie Optymalizacji**

#### **Indeksowanie Strategiczne**
- **Primary Keys**: Automatyczne indeksy klastrowe
- **Foreign Keys**: Indeksy dla join operations
- **Frequently Queried Columns**: Indeksy dla często używanych kolumn
- **Composite Indexes**: Indeksy wielokolumnowe dla złożonych zapytań
- **Partial Indexes**: Indeksy dla specyficznych warunków

#### **Optymalizacja Zapytań**
- **Query Planning**: Analiza planów wykonania
- **Index Usage**: Monitorowanie użycia indeksów
- **Slow Query Logging**: Identyfikacja wolnych zapytań
- **Query Caching**: Buforowanie wyników zapytań

### 📊 **Monitoring Wydajności**

#### **Metryki Kluczowe**
- **Response Time**: Czas odpowiedzi zapytań
- **Throughput**: Liczba zapytań na sekundę
- **Index Usage**: Wykorzystanie indeksów
- **Lock Contention**: Konflikty blokad
- **Cache Hit Ratio**: Współczynnik trafień cache

#### **Narzędzia Monitorowania**
- **MySQL**: Performance Schema, Slow Query Log
- **PostgreSQL**: pg_stat_statements, pg_stat_user_tables
- **SQLite**: EXPLAIN QUERY PLAN, sqlite_stat1

## 🔒 Bezpieczeństwo i Integralność

### 🛡️ **Zabezpieczenia Danych**

#### **Walidacja Danych**
```sql
-- Ograniczenia sprawdzające
CONSTRAINT chk_email_format CHECK (email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
CONSTRAINT chk_price_positive CHECK (price > 0),
CONSTRAINT chk_inventory_quantity CHECK (inventory_quantity >= 0)
```

#### **Integralność Referencyjna**
```sql
-- Klucze obce z odpowiednimi akcjami
FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
```

### 🔐 **Zarządzanie Uprawnieniami**

#### **Role i Uprawnienia**
```sql
-- Tworzenie ról
CREATE ROLE 'chain_rice_readonly';
CREATE ROLE 'chain_rice_admin';

-- Przypisywanie uprawnień
GRANT SELECT ON chain_rice.* TO 'chain_rice_readonly';
GRANT ALL PRIVILEGES ON chain_rice.* TO 'chain_rice_admin';
```

## 📚 Dokumentacja i Utrzymanie

### 📖 **Dokumentacja Kodu**

#### **Komentarze w SQL**
```sql
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
```

#### **Dokumentacja Tabel**
```sql
-- Add table comments
ALTER TABLE users COMMENT = 'Core user information and authentication data';
ALTER TABLE products COMMENT = 'Product catalog with pricing and inventory information';

-- Add column comments for key fields
ALTER TABLE users MODIFY COLUMN password_hash VARCHAR(255) COMMENT 'Bcrypt hashed password';
ALTER TABLE products MODIFY COLUMN price DECIMAL(10, 2) COMMENT 'Selling price in USD';
```

### 🔄 **Wersjonowanie i Migracje**

#### **Strategia Migracji**
- **Forward Migrations**: Migracje do nowszych wersji
- **Rollback Migrations**: Cofanie migracji
- **Schema Versioning**: Śledzenie wersji schematu
- **Data Migration**: Migracja danych między wersjami

## 🌟 Oceny Gwiazdkowe

### ⭐ **Ocena Funkcjonalności**
- **Kompleksowość Schematu**: ★★★★★ (Pełny schemat e-commerce)
- **Optymalizacja Wydajności**: ★★★★★ (Zaawansowane indeksy i optymalizacje)
- **Wsparcie Multi-Database**: ★★★★★ (MySQL, PostgreSQL, SQLite)
- **Analityka i Raportowanie**: ★★★★★ (Zaawansowane zapytania analityczne)
- **Backup i Recovery**: ★★★★★ (Kompleksowy system backup)
- **Bezpieczeństwo**: ★★★★★ (Walidacja, integralność, uprawnienia)
- **Dokumentacja**: ★★★★★ (Szczegółowa dokumentacja w języku polskim)
- **Praktyczne Zastosowania**: ★★★★★ (Real-world e-commerce scenarios)

### 🎯 **Poziom Zaawansowania**
- **SQL Fundamentals**: ★★★★★ (Podstawy SQL na poziomie eksperta)
- **Database Design**: ★★★★★ (Zaawansowane wzorce projektowe)
- **Performance Optimization**: ★★★★★ (Optymalizacje na poziomie produkcyjnym)
- **Business Intelligence**: ★★★★★ (Analityka biznesowa i raportowanie)
- **Database Administration**: ★★★★★ (Administracja baz danych)
- **Multi-Platform Support**: ★★★★★ (Wsparcie wielu systemów bazodanowych)

## 🚀 Rozszerzenia i Przyszłe Funkcje

### 🔮 **Planowane Rozszerzenia**
- **NoSQL Integration**: Integracja z MongoDB, Redis
- **Real-time Analytics**: Stream processing z Apache Kafka
- **Machine Learning**: Predykcyjne modele analityczne
- **Cloud Integration**: AWS RDS, Google Cloud SQL, Azure Database
- **Microservices Support**: Rozproszone bazy danych
- **Graph Database**: Relacje grafowe dla rekomendacji

### 🛠️ **Narzędzia Deweloperskie**
- **Database Migrations**: Automatyczne migracje schematu
- **Testing Framework**: Testy jednostkowe dla SQL
- **Performance Profiling**: Profilowanie wydajności zapytań
- **Schema Validation**: Walidacja schematu bazy danych

## 📞 Wsparcie i Współpraca

### 🤝 **Współpraca**
- **Code Reviews**: Przeglądy kodu SQL
- **Best Practices**: Udostępnianie najlepszych praktyk
- **Performance Tuning**: Optymalizacja wydajności
- **Security Audits**: Audyty bezpieczeństwa

### 📧 **Kontakt**
- **Issues**: Zgłaszanie problemów i sugestii
- **Documentation**: Ulepszanie dokumentacji
- **Training**: Szkolenia z SQL i baz danych
- **Consulting**: Konsultacje techniczne

---

## 📋 Podsumowanie

Kolekcja SQL Chain Rice demonstruje **zaawansowane umiejętności** w zakresie:

- **Database Design**: Profesjonalne projektowanie schematów baz danych
- **SQL Mastery**: Zaawansowane operacje SQL i optymalizacje
- **Multi-Platform Expertise**: Wsparcie różnych systemów bazodanowych
- **Business Intelligence**: Analityka biznesowa i raportowanie
- **Performance Optimization**: Optymalizacja wydajności na poziomie produkcyjnym
- **Security & Integrity**: Bezpieczeństwo i integralność danych
- **Documentation**: Profesjonalna dokumentacja w języku polskim

Ta kolekcja pokazuje **głębokie zrozumienie** technologii baz danych i **praktyczne zastosowania** w real-world scenarios e-commerce platform.

**Poziom ekspertyzy: Zaawansowany** - Demonstruje solidne zrozumienie database design, SQL optimization i professional development practices.
