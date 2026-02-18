-- Verify migration - check all tables and foreign keys

SELECT 
    'users' as table_name,
    'id' as column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'id'

UNION ALL

SELECT 
    'sessions' as table_name,
    'user_id' as column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'sessions' AND column_name = 'user_id'

UNION ALL

SELECT 
    'oauth_accounts' as table_name,
    'user_id' as column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'oauth_accounts' AND column_name = 'user_id'

UNION ALL

SELECT 
    'patient_profiles' as table_name,
    'user_id' as column_name,
    data_type,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'patient_profiles' AND column_name = 'user_id';

-- Check foreign keys
SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    tc.constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
    AND tc.constraint_type = 'FOREIGN KEY'
    AND ccu.table_name = 'users'
    AND ccu.column_name = 'id'
ORDER BY tc.table_name, kcu.column_name;






















































