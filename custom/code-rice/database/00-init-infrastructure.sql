-- Code-Rice Infrastructure Initialization
-- Creates user, database and grants privileges
-- This script runs as postgres superuser BEFORE connecting to the database
-- Create user
CREATE USER IF NOT EXISTS code_rice_user WITH PASSWORD 'code_rice_password';
ALTER USER code_rice_user WITH CREATEDB;
-- Create database
CREATE DATABASE IF NOT EXISTS "code-rice" OWNER code_rice_user ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8';
-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE "code-rice" TO code_rice_user;
GRANT ALL PRIVILEGES ON DATABASE "code-rice" TO postgres;
