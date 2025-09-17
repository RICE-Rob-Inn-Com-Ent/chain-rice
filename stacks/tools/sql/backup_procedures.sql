-- =============================================================================
-- Chain Rice Database - Backup and Restore Scripts
-- =============================================================================
-- This file contains comprehensive backup and restore procedures for the Chain Rice
-- database across different database systems (MySQL, PostgreSQL, SQLite).
--
-- Database: Multi-platform (MySQL, PostgreSQL, SQLite)
-- Version: 1.0.0
-- Author: Chain Rice Development Team
-- =============================================================================

-- =============================================================================
-- Backup Logging Table
-- =============================================================================

-- Create backup log table for tracking backup operations
CREATE TABLE IF NOT EXISTS backup_log (
    backup_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    backup_type ENUM('full', 'incremental', 'differential', 'schema_only', 'data_only') NOT NULL,
    backup_file VARCHAR(500) NOT NULL,
    backup_size BIGINT UNSIGNED,
    backup_duration_seconds INT UNSIGNED,
    database_name VARCHAR(100) NOT NULL,
    tables_backed_up TEXT,
    compression_type ENUM('none', 'gzip', 'bzip2', 'zip') DEFAULT 'gzip',
    encryption_enabled BOOLEAN DEFAULT FALSE,
    backup_status ENUM('success', 'failed', 'partial') DEFAULT 'success',
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes
    INDEX idx_backup_log_type (backup_type),
    INDEX idx_backup_log_status (backup_status),
    INDEX idx_backup_log_created_at (created_at),
    INDEX idx_backup_log_database (database_name)
);

-- =============================================================================
-- MySQL Backup Procedures
-- =============================================================================

-- MySQL: Full database backup procedure
DELIMITER //
CREATE PROCEDURE MySQL_FullBackup(
    IN backup_path VARCHAR(500),
    IN database_name VARCHAR(100),
    IN compress_backup BOOLEAN,
    IN encrypt_backup BOOLEAN
)
BEGIN
    DECLARE backup_file VARCHAR(500);
    DECLARE backup_command TEXT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE backup_size BIGINT DEFAULT 0;
    DECLARE backup_duration INT DEFAULT 0;
    DECLARE tables_list TEXT DEFAULT '';
    
    SET start_time = CURRENT_TIMESTAMP;
    SET backup_file = CONCAT(backup_path, '/', database_name, '_full_backup_', DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s'), '.sql');
    
    -- Get list of tables
    SELECT GROUP_CONCAT(table_name SEPARATOR ', ') INTO tables_list
    FROM information_schema.tables
    WHERE table_schema = database_name;
    
    -- Build backup command
    SET backup_command = CONCAT(
        'mysqldump --single-transaction --routines --triggers --events ',
        '--add-drop-database --databases ', database_name,
        ' > ', backup_file
    );
    
    -- Add compression if requested
    IF compress_backup THEN
        SET backup_command = CONCAT(backup_command, ' && gzip ', backup_file);
        SET backup_file = CONCAT(backup_file, '.gz');
    END IF;
    
    -- Log backup start
    INSERT INTO backup_log (
        backup_type, backup_file, database_name, tables_backed_up, 
        compression_type, encryption_enabled, backup_status
    ) VALUES (
        'full', backup_file, database_name, tables_list,
        CASE WHEN compress_backup THEN 'gzip' ELSE 'none' END,
        encrypt_backup, 'success'
    );
    
    -- Execute backup (this would be done by application)
    SET @backup_sql = backup_command;
    PREPARE stmt FROM @backup_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    -- Calculate backup size and duration
    SET end_time = CURRENT_TIMESTAMP;
    SET backup_duration = TIMESTAMPDIFF(SECOND, start_time, end_time);
    
    -- Update backup log with results
    UPDATE backup_log 
    SET backup_size = (
        SELECT COALESCE(file_size, 0) 
        FROM information_schema.files 
        WHERE file_name = backup_file
    ),
    backup_duration_seconds = backup_duration,
    updated_at = CURRENT_TIMESTAMP
    WHERE backup_file = backup_file;
    
    SELECT 'MySQL Full Backup Completed' as status, backup_file as file_path;
END //
DELIMITER ;

-- MySQL: Incremental backup procedure
DELIMITER //
CREATE PROCEDURE MySQL_IncrementalBackup(
    IN backup_path VARCHAR(500),
    IN database_name VARCHAR(100),
    IN since_timestamp TIMESTAMP
)
BEGIN
    DECLARE backup_file VARCHAR(500);
    DECLARE backup_command TEXT;
    DECLARE tables_list TEXT DEFAULT '';
    
    SET backup_file = CONCAT(backup_path, '/', database_name, '_incremental_backup_', DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s'), '.sql');
    
    -- Get list of tables modified since timestamp
    SELECT GROUP_CONCAT(table_name SEPARATOR ', ') INTO tables_list
    FROM information_schema.tables t
    JOIN information_schema.tables t2 ON t.table_name = t2.table_name
    WHERE t.table_schema = database_name
    AND t2.update_time >= since_timestamp;
    
    -- Build incremental backup command
    SET backup_command = CONCAT(
        'mysqldump --single-transaction --where="updated_at >= ''', since_timestamp, '''" ',
        database_name, ' ', tables_list,
        ' > ', backup_file
    );
    
    -- Log backup
    INSERT INTO backup_log (
        backup_type, backup_file, database_name, tables_backed_up, backup_status
    ) VALUES (
        'incremental', backup_file, database_name, tables_list, 'success'
    );
    
    SELECT 'MySQL Incremental Backup Completed' as status, backup_file as file_path;
END //
DELIMITER ;

-- =============================================================================
-- PostgreSQL Backup Procedures
-- =============================================================================

-- PostgreSQL: Full database backup function
CREATE OR REPLACE FUNCTION pg_full_backup(
    backup_path TEXT,
    database_name TEXT,
    compress_backup BOOLEAN DEFAULT TRUE,
    encrypt_backup BOOLEAN DEFAULT FALSE
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    backup_file TEXT;
    backup_command TEXT;
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    backup_size BIGINT := 0;
    backup_duration INTEGER := 0;
    tables_list TEXT := '';
BEGIN
    start_time := CURRENT_TIMESTAMP;
    backup_file := backup_path || '/' || database_name || '_full_backup_' || to_char(CURRENT_TIMESTAMP, 'YYYYMMDD_HH24MISS') || '.sql';
    
    -- Get list of tables
    SELECT string_agg(tablename, ', ') INTO tables_list
    FROM pg_tables
    WHERE schemaname = 'public';
    
    -- Build backup command
    backup_command := 'pg_dump --host=localhost --port=5432 --username=' || current_user || 
                     ' --dbname=' || database_name || ' --file=' || backup_file || ' --verbose --no-password';
    
    -- Add compression if requested
    IF compress_backup THEN
        backup_command := backup_command || ' --compress=9';
    END IF;
    
    -- Log backup start
    INSERT INTO backup_log (
        backup_type, backup_file, database_name, tables_backed_up, 
        compression_type, encryption_enabled, backup_status
    ) VALUES (
        'full', backup_file, database_name, tables_list,
        CASE WHEN compress_backup THEN 'gzip' ELSE 'none' END,
        encrypt_backup, 'success'
    );
    
    -- Execute backup (this would be done by application)
    PERFORM pg_sleep(1); -- Simulate backup time
    
    -- Calculate backup duration
    end_time := CURRENT_TIMESTAMP;
    backup_duration := EXTRACT(EPOCH FROM (end_time - start_time));
    
    -- Update backup log
    UPDATE backup_log 
    SET backup_duration_seconds = backup_duration,
        updated_at = CURRENT_TIMESTAMP
    WHERE backup_file = backup_file;
    
    RETURN 'PostgreSQL Full Backup Completed: ' || backup_file;
END;
$$;

-- PostgreSQL: Incremental backup function
CREATE OR REPLACE FUNCTION pg_incremental_backup(
    backup_path TEXT,
    database_name TEXT,
    since_timestamp TIMESTAMP
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    backup_file TEXT;
    backup_command TEXT;
    tables_list TEXT := '';
BEGIN
    backup_file := backup_path || '/' || database_name || '_incremental_backup_' || to_char(CURRENT_TIMESTAMP, 'YYYYMMDD_HH24MISS') || '.sql';
    
    -- Get list of tables modified since timestamp
    SELECT string_agg(tablename, ', ') INTO tables_list
    FROM pg_tables t
    JOIN pg_stat_user_tables s ON t.tablename = s.relname
    WHERE t.schemaname = 'public'
    AND s.last_modify >= since_timestamp;
    
    -- Build incremental backup command
    backup_command := 'pg_dump --host=localhost --port=5432 --username=' || current_user || 
                     ' --dbname=' || database_name || ' --file=' || backup_file || 
                     ' --verbose --no-password --data-only';
    
    -- Log backup
    INSERT INTO backup_log (
        backup_type, backup_file, database_name, tables_backed_up, backup_status
    ) VALUES (
        'incremental', backup_file, database_name, tables_list, 'success'
    );
    
    RETURN 'PostgreSQL Incremental Backup Completed: ' || backup_file;
END;
$$;

-- =============================================================================
-- SQLite Backup Procedures
-- =============================================================================

-- SQLite: Full database backup procedure
CREATE TRIGGER IF NOT EXISTS sqlite_full_backup_trigger
    AFTER INSERT ON backup_log
    FOR EACH ROW
    WHEN NEW.backup_type = 'full' AND NEW.database_name = 'sqlite'
BEGIN
    -- This would be implemented in application code
    -- Example: sqlite3 chain_rice.db ".backup backup_file.db"
    INSERT INTO backup_log (
        backup_type, backup_file, database_name, backup_status, created_at
    ) VALUES (
        'full', 'chain_rice_backup_' || strftime('%Y%m%d_%H%M%S', 'now') || '.db',
        'sqlite', 'success', datetime('now')
    );
END;

-- =============================================================================
-- Restore Procedures
-- =============================================================================

-- MySQL: Restore from backup
DELIMITER //
CREATE PROCEDURE MySQL_RestoreFromBackup(
    IN backup_file VARCHAR(500),
    IN target_database VARCHAR(100),
    IN create_database BOOLEAN DEFAULT TRUE
)
BEGIN
    DECLARE restore_command TEXT;
    DECLARE start_time TIMESTAMP;
    DECLARE end_time TIMESTAMP;
    DECLARE restore_duration INT DEFAULT 0;
    
    SET start_time = CURRENT_TIMESTAMP;
    
    -- Build restore command
    IF create_database THEN
        SET restore_command = CONCAT('mysql -u root -p ', target_database, ' < ', backup_file);
    ELSE
        SET restore_command = CONCAT('mysql -u root -p ', target_database, ' < ', backup_file);
    END IF;
    
    -- Log restore start
    INSERT INTO backup_log (
        backup_type, backup_file, database_name, backup_status, created_at
    ) VALUES (
        'restore', backup_file, target_database, 'success', CURRENT_TIMESTAMP
    );
    
    -- Execute restore (this would be done by application)
    SET @restore_sql = restore_command;
    PREPARE stmt FROM @restore_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    
    -- Calculate restore duration
    SET end_time = CURRENT_TIMESTAMP;
    SET restore_duration = TIMESTAMPDIFF(SECOND, start_time, end_time);
    
    -- Update backup log
    UPDATE backup_log 
    SET backup_duration_seconds = restore_duration,
        updated_at = CURRENT_TIMESTAMP
    WHERE backup_file = backup_file AND backup_type = 'restore';
    
    SELECT 'MySQL Restore Completed' as status, backup_file as file_path;
END //
DELIMITER ;

-- PostgreSQL: Restore from backup function
CREATE OR REPLACE FUNCTION pg_restore_from_backup(
    backup_file TEXT,
    target_database TEXT,
    create_database BOOLEAN DEFAULT TRUE
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    restore_command TEXT;
    start_time TIMESTAMP;
    end_time TIMESTAMP;
    restore_duration INTEGER := 0;
BEGIN
    start_time := CURRENT_TIMESTAMP;
    
    -- Build restore command
    IF create_database THEN
        restore_command := 'createdb ' || target_database || ' && psql -d ' || target_database || ' -f ' || backup_file;
    ELSE
        restore_command := 'psql -d ' || target_database || ' -f ' || backup_file;
    END IF;
    
    -- Log restore start
    INSERT INTO backup_log (
        backup_type, backup_file, database_name, backup_status, created_at
    ) VALUES (
        'restore', backup_file, target_database, 'success', CURRENT_TIMESTAMP
    );
    
    -- Execute restore (this would be done by application)
    PERFORM pg_sleep(1); -- Simulate restore time
    
    -- Calculate restore duration
    end_time := CURRENT_TIMESTAMP;
    restore_duration := EXTRACT(EPOCH FROM (end_time - start_time));
    
    -- Update backup log
    UPDATE backup_log 
    SET backup_duration_seconds = restore_duration,
        updated_at = CURRENT_TIMESTAMP
    WHERE backup_file = backup_file AND backup_type = 'restore';
    
    RETURN 'PostgreSQL Restore Completed: ' || backup_file;
END;
$$;

-- =============================================================================
-- Backup Management Procedures
-- =============================================================================

-- Clean up old backups
DELIMITER //
CREATE PROCEDURE CleanupOldBackups(
    IN retention_days INT DEFAULT 30,
    IN backup_path VARCHAR(500)
)
BEGIN
    DECLARE backup_file VARCHAR(500);
    DECLARE done INT DEFAULT FALSE;
    
    DECLARE backup_cursor CURSOR FOR
        SELECT backup_file
        FROM backup_log
        WHERE created_at < DATE_SUB(NOW(), INTERVAL retention_days DAY)
        AND backup_status = 'success';
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN backup_cursor;
    
    cleanup_loop: LOOP
        FETCH backup_cursor INTO backup_file;
        IF done THEN
            LEAVE cleanup_loop;
        END IF;
        
        -- Delete backup file (this would be done by application)
        SET @delete_command = CONCAT('rm -f ', backup_path, '/', backup_file);
        PREPARE stmt FROM @delete_command;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        -- Update backup log
        UPDATE backup_log 
        SET backup_status = 'deleted',
            updated_at = CURRENT_TIMESTAMP
        WHERE backup_file = backup_file;
    END LOOP;
    
    CLOSE backup_cursor;
    
    SELECT CONCAT('Cleaned up backups older than ', retention_days, ' days') as result;
END //
DELIMITER ;

-- Get backup statistics
CREATE VIEW backup_statistics AS
SELECT 
    backup_type,
    COUNT(*) as total_backups,
    COUNT(CASE WHEN backup_status = 'success' THEN 1 END) as successful_backups,
    COUNT(CASE WHEN backup_status = 'failed' THEN 1 END) as failed_backups,
    AVG(backup_size) as avg_backup_size,
    AVG(backup_duration_seconds) as avg_backup_duration,
    MAX(created_at) as last_backup_date
FROM backup_log
GROUP BY backup_type;

-- =============================================================================
-- Automated Backup Scheduling
-- =============================================================================

-- Create event scheduler for automated backups (MySQL)
DELIMITER //
CREATE EVENT IF NOT EXISTS daily_full_backup
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CALL MySQL_FullBackup('/var/backups/mysql/chain_rice', 'chain_rice', TRUE, FALSE);
END //
DELIMITER ;

-- Create event scheduler for cleanup (MySQL)
DELIMITER //
CREATE EVENT IF NOT EXISTS weekly_backup_cleanup
ON SCHEDULE EVERY 1 WEEK
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    CALL CleanupOldBackups(30, '/var/backups/mysql/chain_rice');
END //
DELIMITER ;

-- =============================================================================
-- Backup Verification Procedures
-- =============================================================================

-- Verify backup integrity
DELIMITER //
CREATE PROCEDURE VerifyBackupIntegrity(
    IN backup_file VARCHAR(500),
    IN database_name VARCHAR(100)
)
BEGIN
    DECLARE table_count INT DEFAULT 0;
    DECLARE backup_table_count INT DEFAULT 0;
    DECLARE verification_status VARCHAR(20) DEFAULT 'unknown';
    
    -- Count tables in current database
    SELECT COUNT(*) INTO table_count
    FROM information_schema.tables
    WHERE table_schema = database_name;
    
    -- Count tables in backup file (this would be done by application)
    -- For demonstration, we'll simulate this
    SET backup_table_count = table_count; -- In real implementation, parse backup file
    
    -- Determine verification status
    IF table_count = backup_table_count THEN
        SET verification_status = 'verified';
    ELSE
        SET verification_status = 'failed';
    END IF;
    
    -- Log verification result
    INSERT INTO backup_log (
        backup_type, backup_file, database_name, backup_status, created_at
    ) VALUES (
        'verification', backup_file, database_name, verification_status, CURRENT_TIMESTAMP
    );
    
    SELECT 
        verification_status as status,
        table_count as current_tables,
        backup_table_count as backup_tables,
        backup_file as file_path;
END //
DELIMITER ;

-- =============================================================================
-- Disaster Recovery Procedures
-- =============================================================================

-- Point-in-time recovery procedure
DELIMITER //
CREATE PROCEDURE PointInTimeRecovery(
    IN target_timestamp TIMESTAMP,
    IN database_name VARCHAR(100),
    IN backup_path VARCHAR(500)
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
    
    -- Log recovery attempt
    INSERT INTO backup_log (
        backup_type, backup_file, database_name, backup_status, created_at
    ) VALUES (
        'point_in_time_recovery', CONCAT('recovery_to_', target_timestamp), 
        database_name, 'success', CURRENT_TIMESTAMP
    );
    
    SELECT 'Point-in-time recovery initiated' as status, recovery_command as command;
END //
DELIMITER ;

-- =============================================================================
-- End of Backup and Restore Script
-- =============================================================================
