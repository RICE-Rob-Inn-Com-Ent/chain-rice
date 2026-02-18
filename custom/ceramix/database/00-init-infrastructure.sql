-- Ceramix Infrastructure Initialization
-- Creates user, database and grants privileges
-- This script runs as postgres superuser BEFORE connecting to the database
-- Create user
CREATE USER IF NOT EXISTS ceramix_user WITH PASSWORD 'ceramix_password';
ALTER USER ceramix_user WITH CREATEDB;
-- Create database
CREATE DATABASE IF NOT EXISTS ceramix OWNER ceramix_user ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8';
-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE ceramix TO ceramix_user;
GRANT ALL PRIVILEGES ON DATABASE ceramix TO postgres;
