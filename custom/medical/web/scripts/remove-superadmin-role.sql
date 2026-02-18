-- Script to remove superadmin role and convert to owner
-- Run this in the ceramix database

-- 1. Update all users with superadmin role to owner
-- First, find all users with superadmin role prefix (SUP-)
UPDATE users 
SET id = REPLACE(id::text, 'SUP-', 'OWN-')::uuid
WHERE id::text LIKE 'SUP-%';

-- 2. Update role_groups table - remove superadmin, ensure owner exists
DELETE FROM role_groups WHERE role_key = 'superadmin';

-- Ensure owner role exists
INSERT INTO role_groups (role_key, label, description, color_class, sort_order)
VALUES ('owner', 'Właściciel', 'Pełny dostęp i kontrola ról', 'bg-purple-500/20 text-purple-400', 40)
ON CONFLICT (role_key) DO UPDATE SET
  label = EXCLUDED.label,
  description = EXCLUDED.description,
  color_class = EXCLUDED.color_class,
  sort_order = EXCLUDED.sort_order,
  updated_at = CURRENT_TIMESTAMP;

-- 3. Update user_roles table - change superadmin to owner
UPDATE user_roles 
SET role = 'owner' 
WHERE role = 'superadmin';

-- 4. Verify no superadmin roles remain
SELECT COUNT(*) as superadmin_count FROM user_roles WHERE role = 'superadmin';
SELECT COUNT(*) as owner_count FROM user_roles WHERE role = 'owner';


