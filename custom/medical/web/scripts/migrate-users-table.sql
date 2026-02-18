-- Migration script to change users.id from UUID to VARCHAR with role-based IDs
-- 
-- WARNING: This is a destructive migration!
-- Make sure to backup your database before running this.
--
-- Steps:
-- 1. Backup your database
-- 2. Run this script
-- 3. Update all foreign key references
-- 4. Test thoroughly

BEGIN;

-- Step 1: Drop foreign key constraints temporarily
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_fkey;
ALTER TABLE user_roles DROP CONSTRAINT IF EXISTS user_roles_granted_by_fkey;
ALTER TABLE patient_profiles DROP CONSTRAINT IF EXISTS patient_profiles_user_id_fkey;
ALTER TABLE sessions DROP CONSTRAINT IF EXISTS sessions_user_id_fkey;
-- Add other tables that reference users.id

-- Step 2: Change users.id column type
ALTER TABLE users ALTER COLUMN id TYPE VARCHAR(50);

-- Step 3: Change all foreign key columns to VARCHAR
ALTER TABLE user_roles ALTER COLUMN user_id TYPE VARCHAR(50);
ALTER TABLE user_roles ALTER COLUMN granted_by TYPE VARCHAR(50);
ALTER TABLE patient_profiles ALTER COLUMN user_id TYPE VARCHAR(50);
ALTER TABLE sessions ALTER COLUMN user_id TYPE VARCHAR(50);
-- Add other tables

-- Step 4: Re-add foreign key constraints
ALTER TABLE user_roles 
  ADD CONSTRAINT user_roles_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE user_roles 
  ADD CONSTRAINT user_roles_granted_by_fkey 
  FOREIGN KEY (granted_by) REFERENCES users(id) ON DELETE SET NULL;

ALTER TABLE patient_profiles 
  ADD CONSTRAINT patient_profiles_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE sessions 
  ADD CONSTRAINT sessions_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

-- Step 5: Create index on users.id for performance
CREATE INDEX IF NOT EXISTS idx_users_id ON users(id);

COMMIT;

-- After running this, you need to:
-- 1. Update all existing user IDs using the migrate-user-ids.ts script
-- 2. Test all functionality
-- 3. Update application code to use new ID format




















