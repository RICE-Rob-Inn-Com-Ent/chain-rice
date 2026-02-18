-- Fix sessions table to use VARCHAR(50) for user_id
-- This ensures compatibility with new role-based user IDs

BEGIN;

-- Step 1: Drop foreign key constraint if exists
ALTER TABLE sessions DROP CONSTRAINT IF EXISTS sessions_user_id_fkey;

-- Step 2: Change user_id column type to VARCHAR(50)
ALTER TABLE sessions ALTER COLUMN user_id TYPE VARCHAR(50) USING user_id::text;

-- Step 3: Re-add foreign key constraint
ALTER TABLE sessions 
  ADD CONSTRAINT sessions_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

COMMIT;






















































