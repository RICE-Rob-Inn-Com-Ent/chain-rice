-- Meowtopia MLflow Infrastructure Initialization
-- Creates MLflow database for Meowtopia ML experiment tracking
-- This script runs as postgres superuser BEFORE connecting to the database
-- Create MLflow database for Meowtopia
CREATE DATABASE IF NOT EXISTS mlflow_meowtopia OWNER meowtopia_user ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8';
-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE mlflow_meowtopia TO meowtopia_user;
GRANT ALL PRIVILEGES ON DATABASE mlflow_meowtopia TO postgres;
