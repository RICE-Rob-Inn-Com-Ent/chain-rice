-- Medical Infrastructure Initialization
-- Creates user, database and grants privileges
-- This script runs as postgres superuser BEFORE connecting to the database
-- Create user
CREATE USER IF NOT EXISTS medical_user WITH PASSWORD 'medical_password';
ALTER USER medical_user WITH CREATEDB;
-- Create database
CREATE DATABASE IF NOT EXISTS medical OWNER medical_user ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8';
-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE medical TO medical_user;
GRANT ALL PRIVILEGES ON DATABASE medical TO postgres;
