-- Add username column to users table
-- Username will be used for URL routing (like GitHub: /username instead of /user-id)

-- Add username column (unique, not null after migration)
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(50) UNIQUE;

-- Create index for fast username lookups
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username) WHERE username IS NOT NULL;

-- Function to generate username from email or display name
CREATE OR REPLACE FUNCTION generate_username(base_text TEXT)
RETURNS TEXT AS $$
DECLARE
    clean_text TEXT;
    username_candidate TEXT;
    counter INTEGER := 0;
BEGIN
    -- Clean the base text: lowercase, remove special chars, keep only alphanumeric and hyphens
    clean_text := LOWER(REGEXP_REPLACE(base_text, '[^a-z0-9]', '', 'g'));
    
    -- If empty, use 'user'
    IF clean_text = '' THEN
        clean_text := 'user';
    END IF;
    
    -- Ensure it's between 3-50 characters
    IF LENGTH(clean_text) < 3 THEN
        clean_text := clean_text || '123';
    END IF;
    
    IF LENGTH(clean_text) > 50 THEN
        clean_text := SUBSTRING(clean_text, 1, 50);
    END IF;
    
    username_candidate := clean_text;
    
    -- Check if username exists, if so, append number
    WHILE EXISTS (SELECT 1 FROM users WHERE username = username_candidate) LOOP
        counter := counter + 1;
        username_candidate := clean_text || counter::TEXT;
        
        -- Prevent infinite loop
        IF counter > 999999 THEN
            RAISE EXCEPTION 'Unable to generate unique username';
        END IF;
    END LOOP;
    
    RETURN username_candidate;
END;
$$ LANGUAGE plpgsql;

-- Migrate existing users: generate username from email (part before @)
DO $$
DECLARE
    user_record RECORD;
    new_username TEXT;
BEGIN
    FOR user_record IN SELECT id, email, display_name FROM users WHERE username IS NULL LOOP
        -- Try email first (part before @)
        IF user_record.email IS NOT NULL AND user_record.email LIKE '%@%' THEN
            new_username := generate_username(SPLIT_PART(user_record.email, '@', 1));
        -- Fallback to display_name
        ELSIF user_record.display_name IS NOT NULL THEN
            new_username := generate_username(user_record.display_name);
        -- Last resort: use 'user' + id hash
        ELSE
            new_username := generate_username('user' || SUBSTRING(user_record.id::TEXT, 1, 8));
        END IF;
        
        UPDATE users SET username = new_username WHERE id = user_record.id;
    END LOOP;
END $$;

-- Make username NOT NULL after migration
ALTER TABLE users ALTER COLUMN username SET NOT NULL;

-- Add constraint: username must be 3-50 characters, alphanumeric + hyphens only
ALTER TABLE users ADD CONSTRAINT username_format CHECK (
    username ~ '^[a-z0-9]([a-z0-9-]{1,48}[a-z0-9])?$'
);










































