-- Meowtopia Infrastructure Initialization
-- Creates user, database and grants privileges
-- This script runs as postgres superuser BEFORE connecting to the database
-- Create user
CREATE USER IF NOT EXISTS meowtopia_user WITH PASSWORD 'meowtopia_password';
ALTER USER meowtopia_user WITH CREATEDB;
-- Create database
CREATE DATABASE IF NOT EXISTS meowtopia OWNER meowtopia_user ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8';
-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE meowtopia TO meowtopia_user;
GRANT ALL PRIVILEGES ON DATABASE meowtopia TO postgres;
