-- Migration script to change all columns that reference users.id from UUID to VARCHAR(50)
-- This fixes columns like patient_id, created_by, updated_by, etc.
-- 
-- WARNING: This is a DESTRUCTIVE migration!
-- Make sure to backup your database before running this.

BEGIN;

-- Step 1: Drop foreign key constraints for columns that reference users.id
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT 
            tc.table_name,
            tc.constraint_name
        FROM information_schema.table_constraints AS tc
        WHERE tc.table_schema = 'public'
            AND tc.constraint_type = 'FOREIGN KEY'
            AND EXISTS (
                SELECT 1 FROM information_schema.constraint_column_usage AS ccu
                WHERE ccu.constraint_name = tc.constraint_name
                    AND ccu.table_schema = tc.table_schema
                    AND ccu.table_name = 'users'
                    AND ccu.column_name = 'id'
            )
    ) LOOP
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', r.table_name, r.constraint_name);
        RAISE NOTICE 'Dropped constraint % on table %', r.constraint_name, r.table_name;
    END LOOP;
END $$;

-- Step 2: Change all columns that reference users.id to VARCHAR(50)
-- This includes: patient_id, created_by, updated_by, user_id, granted_by, etc.
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (
        SELECT DISTINCT
            kcu.table_name,
            kcu.column_name
        FROM information_schema.key_column_usage AS kcu
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = kcu.constraint_name
            AND ccu.table_schema = kcu.table_schema
        WHERE kcu.table_schema = 'public'
            AND ccu.table_name = 'users'
            AND ccu.column_name = 'id'
            AND EXISTS (
                SELECT 1 FROM information_schema.columns AS c
                WHERE c.table_schema = 'public'
                    AND c.table_name = kcu.table_name
                    AND c.column_name = kcu.column_name
                    AND c.data_type = 'uuid'
            )
    ) LOOP
        BEGIN
            EXECUTE format('ALTER TABLE %I ALTER COLUMN %I TYPE VARCHAR(50) USING %I::text', 
                r.table_name, r.column_name, r.column_name);
            RAISE NOTICE 'Changed %.% to VARCHAR(50)', r.table_name, r.column_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not change %.%: %', r.table_name, r.column_name, SQLERRM;
        END;
    END LOOP;
END $$;

-- Step 3: Also update columns that might not have foreign key constraints but should reference users.id
-- Based on naming conventions (patient_id, created_by, updated_by, etc.)
DO $$
DECLARE
    r RECORD;
    has_fk BOOLEAN;
BEGIN
    FOR r IN (
        SELECT 
            table_name,
            column_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
            AND data_type = 'uuid'
            AND (
                column_name IN ('patient_id', 'created_by', 'updated_by', 'deleted_by', 'user_id', 'granted_by')
                OR column_name LIKE '%user_id%'
                OR column_name LIKE '%created_by%'
                OR column_name LIKE '%updated_by%'
            )
            AND table_name != 'users'
    ) LOOP
        -- Check if this column already has a foreign key to users.id
        SELECT EXISTS (
            SELECT 1
            FROM information_schema.table_constraints AS tc
            JOIN information_schema.key_column_usage AS kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage AS ccu
                ON ccu.constraint_name = tc.constraint_name
                AND ccu.table_schema = tc.table_schema
            WHERE tc.table_schema = 'public'
                AND tc.table_name = r.table_name
                AND kcu.column_name = r.column_name
                AND tc.constraint_type = 'FOREIGN KEY'
                AND ccu.table_name = 'users'
                AND ccu.column_name = 'id'
        ) INTO has_fk;
        
        -- Only update if it references users.id (has FK) or if it's a common pattern
        IF has_fk OR r.column_name IN ('patient_id', 'created_by', 'updated_by', 'deleted_by', 'user_id', 'granted_by') THEN
            BEGIN
                EXECUTE format('ALTER TABLE %I ALTER COLUMN %I TYPE VARCHAR(50) USING %I::text', 
                    r.table_name, r.column_name, r.column_name);
                RAISE NOTICE 'Changed %.% to VARCHAR(50) (pattern match)', r.table_name, r.column_name;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Could not change %.%: %', r.table_name, r.column_name, SQLERRM;
            END;
        END IF;
    END LOOP;
END $$;

-- Step 4: Re-add foreign key constraints
DO $$
DECLARE
    r RECORD;
    col_type TEXT;
BEGIN
    FOR r IN (
        SELECT DISTINCT
            kcu.table_name,
            kcu.column_name,
            'fk_' || kcu.table_name || '_' || kcu.column_name as new_constraint_name
        FROM information_schema.key_column_usage AS kcu
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = kcu.constraint_name
            AND ccu.table_schema = kcu.table_schema
        WHERE kcu.table_schema = 'public'
            AND ccu.table_name = 'users'
            AND ccu.column_name = 'id'
    ) LOOP
        BEGIN
            -- Check if column is VARCHAR(50)
            SELECT data_type INTO col_type
            FROM information_schema.columns
            WHERE table_schema = 'public'
                AND table_name = r.table_name
                AND column_name = r.column_name;
            
            IF col_type = 'character varying' THEN
                -- Determine ON DELETE action based on column name
                IF r.column_name IN ('granted_by', 'created_by', 'updated_by', 'deleted_by') THEN
                    EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES users(id) ON DELETE SET NULL', 
                        r.table_name, r.new_constraint_name, r.column_name);
                ELSE
                    EXECUTE format('ALTER TABLE %I ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES users(id) ON DELETE CASCADE', 
                        r.table_name, r.new_constraint_name, r.column_name);
                END IF;
                RAISE NOTICE 'Added FK constraint % on %', r.new_constraint_name, r.table_name;
            ELSE
                RAISE NOTICE 'Skipping %.% - column type is %, not VARCHAR', r.table_name, r.column_name, col_type;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE 'Could not add constraint %: %', r.new_constraint_name, SQLERRM;
        END;
    END LOOP;
END $$;

COMMIT;

-- Verify the changes
SELECT 
    table_name,
    column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public'
    AND column_name IN ('patient_id', 'created_by', 'updated_by', 'user_id', 'granted_by')
    AND data_type = 'character varying'
ORDER BY table_name, column_name;


