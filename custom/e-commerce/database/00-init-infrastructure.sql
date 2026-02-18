-- E-Commerce Infrastructure Initialization
-- Creates user, database and grants privileges
-- This script runs as postgres superuser BEFORE connecting to the database
-- Create user
CREATE USER IF NOT EXISTS e_commerce_user WITH PASSWORD 'e_commerce_password';
ALTER USER e_commerce_user WITH CREATEDB;
-- Create database
CREATE DATABASE IF NOT EXISTS e_commerce OWNER e_commerce_user ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8';
-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE e_commerce TO e_commerce_user;
GRANT ALL PRIVILEGES ON DATABASE e_commerce TO postgres;
