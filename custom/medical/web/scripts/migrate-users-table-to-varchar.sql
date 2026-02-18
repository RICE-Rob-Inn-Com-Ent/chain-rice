-- Migration script to change users.id and all foreign key columns from UUID to VARCHAR(50)
-- 
-- WARNING: This is a DESTRUCTIVE migration!
-- Make sure to backup your database before running this.
--
-- Run this BEFORE running migrate-all-users-to-new-ids.ts

BEGIN;

-- Step 1: Drop ALL foreign key constraints that reference users.id
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

-- Step 2: Change ALL foreign key columns that reference users.id to VARCHAR(50) first
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

-- Step 3: Change users.id column type to VARCHAR(50)
ALTER TABLE users ALTER COLUMN id TYPE VARCHAR(50) USING id::text;

-- Step 4: Re-add foreign key constraints (only for columns that were successfully changed)
DO $$
DECLARE
    r RECORD;
    col_type TEXT;
BEGIN
    FOR r IN (
        SELECT DISTINCT
            kcu.table_name,
            kcu.column_name,
            tc.constraint_name as original_constraint_name,
            'fk_' || kcu.table_name || '_' || kcu.column_name as new_constraint_name
        FROM information_schema.key_column_usage AS kcu
        JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = kcu.constraint_name
            AND ccu.table_schema = kcu.table_schema
        JOIN information_schema.table_constraints AS tc
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
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

-- After running this, you can run: yarn migrate:all-users

