-- Migration script to convert SUP- (superadmin) user IDs to OWN- (owner)
-- This script updates all foreign key references automatically
-- Run this in the ceramix database

DO $$
DECLARE
    old_id TEXT;
    new_id TEXT;
    fk_record RECORD;
    updated_count INTEGER;
    timestamp_str TEXT;
    sequence_num INTEGER;
BEGIN
    -- Find all users with SUP- prefix
    FOR old_id IN 
        SELECT id::text FROM users WHERE id::text LIKE 'SUP-%'
    LOOP
        -- Generate new OWN- ID with format: OWN-YYYYMMDD-HHMMSS-XXXXXX
        timestamp_str := TO_CHAR(NOW(), 'YYYYMMDD-HHMMSS');
        
        -- Get sequence number (use random 6 digits for simplicity)
        sequence_num := floor(random() * 1000000)::INTEGER;
        
        -- Format: OWN-YYYYMMDD-HHMMSS-XXXXXX
        new_id := 'OWN-' || timestamp_str || '-' || LPAD(sequence_num::TEXT, 6, '0');
        
        -- Ensure uniqueness by checking if ID exists
        WHILE EXISTS (SELECT 1 FROM users WHERE id::text = new_id) LOOP
            sequence_num := floor(random() * 1000000)::INTEGER;
            new_id := 'OWN-' || timestamp_str || '-' || LPAD(sequence_num::TEXT, 6, '0');
        END LOOP;
        
        RAISE NOTICE 'Converting user % to %', old_id, new_id;
        
        -- Temporarily disable foreign key constraints
        -- We'll update all foreign keys first, then the user ID
        
        -- Update all foreign key references
        -- Find all tables with foreign keys to users.id
        FOR fk_record IN
            SELECT 
                tc.table_name,
                kcu.column_name,
                tc.constraint_name
            FROM information_schema.table_constraints AS tc
            JOIN information_schema.key_column_usage AS kcu
                ON tc.constraint_name = kcu.constraint_name
                AND tc.table_schema = kcu.table_schema
            JOIN information_schema.constraint_column_usage AS ccu
                ON ccu.constraint_name = tc.constraint_name
                AND ccu.table_schema = tc.table_schema
            WHERE tc.constraint_type = 'FOREIGN KEY'
                AND ccu.table_name = 'users'
                AND ccu.column_name = 'id'
                AND tc.table_schema = 'public'
        LOOP
            -- Update foreign key references
            BEGIN
                EXECUTE format('UPDATE %I SET %I = $1 WHERE %I = $2', 
                    fk_record.table_name, 
                    fk_record.column_name, 
                    fk_record.column_name)
                USING new_id, old_id;
                
                GET DIAGNOSTICS updated_count = ROW_COUNT;
                IF updated_count > 0 THEN
                    RAISE NOTICE 'Updated % rows in %.%', updated_count, fk_record.table_name, fk_record.column_name;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                RAISE NOTICE 'Error updating %.%: %', fk_record.table_name, fk_record.column_name, SQLERRM;
            END;
        END LOOP;
        
        -- Finally update the user ID (id is VARCHAR, not UUID)
        -- This should work now because all foreign keys are updated
        UPDATE users SET id = new_id WHERE id = old_id;
        RAISE NOTICE 'Updated user ID from % to %', old_id, new_id;
    END LOOP;
    
    RAISE NOTICE 'Migration completed!';
END $$;

-- Verify no SUP- users remain
SELECT COUNT(*) as remaining_sup_users FROM users WHERE id::text LIKE 'SUP-%';
SELECT COUNT(*) as owner_users FROM users WHERE id::text LIKE 'OWN-%';

