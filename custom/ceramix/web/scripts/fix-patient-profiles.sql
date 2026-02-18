-- Fix patient_profiles table to use VARCHAR(50) for user_id

BEGIN;

-- Step 1: Remove orphaned patient profiles
DELETE FROM patient_profiles 
WHERE user_id::text NOT IN (SELECT id::text FROM users);

-- Step 2: Drop foreign key constraint
ALTER TABLE patient_profiles DROP CONSTRAINT IF EXISTS patient_profiles_user_id_fkey;

-- Step 3: Change user_id column type to VARCHAR(50)
ALTER TABLE patient_profiles ALTER COLUMN user_id TYPE VARCHAR(50) USING user_id::text;

-- Step 4: Re-add foreign key constraint
ALTER TABLE patient_profiles 
  ADD CONSTRAINT patient_profiles_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;

COMMIT;






















































