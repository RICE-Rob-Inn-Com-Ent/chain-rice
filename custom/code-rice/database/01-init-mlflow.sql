-- Code-Rice MLflow Infrastructure Initialization
-- Creates MLflow database for Code-Rice ML experiment tracking
-- This script runs as postgres superuser BEFORE connecting to the database
-- Create MLflow database for Code-Rice
CREATE DATABASE IF NOT EXISTS mlflow_code_rice OWNER code_rice_user ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8';
-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE mlflow_code_rice TO code_rice_user;
GRANT ALL PRIVILEGES ON DATABASE mlflow_code_rice TO postgres;
