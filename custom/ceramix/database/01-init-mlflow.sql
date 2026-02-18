-- Ceramix MLflow Infrastructure Initialization
-- Creates MLflow database for Ceramix ML experiment tracking
-- This script runs as postgres superuser BEFORE connecting to the database
-- Create MLflow database for Ceramix
CREATE DATABASE IF NOT EXISTS mlflow_ceramix OWNER ceramix_user ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8';
-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE mlflow_ceramix TO ceramix_user;
GRANT ALL PRIVILEGES ON DATABASE mlflow_ceramix TO postgres;
