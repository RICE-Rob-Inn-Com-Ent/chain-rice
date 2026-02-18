-- Medical MLflow Infrastructure Initialization
-- Creates MLflow database for Medical ML experiment tracking
-- This script runs as postgres superuser BEFORE connecting to the database
-- Create MLflow database for Medical
CREATE DATABASE IF NOT EXISTS mlflow_medical OWNER medical_user ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8';
-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE mlflow_medical TO medical_user;
GRANT ALL PRIVILEGES ON DATABASE mlflow_medical TO postgres;
