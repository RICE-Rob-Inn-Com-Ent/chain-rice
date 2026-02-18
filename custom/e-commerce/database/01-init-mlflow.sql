-- E-Commerce MLflow Infrastructure Initialization
-- Creates MLflow database for E-Commerce ML experiment tracking
-- This script runs as postgres superuser BEFORE connecting to the database
-- Create MLflow database for E-Commerce
CREATE DATABASE IF NOT EXISTS mlflow_e_commerce OWNER e_commerce_user ENCODING 'UTF8' LC_COLLATE 'en_US.utf8' LC_CTYPE 'en_US.utf8';
-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE mlflow_e_commerce TO e_commerce_user;
GRANT ALL PRIVILEGES ON DATABASE mlflow_e_commerce TO postgres;
