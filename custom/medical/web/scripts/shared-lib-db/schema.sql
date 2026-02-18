-- Ceramix Database Schema
-- PostgreSQL database for Ceramix dental clinic management

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Users table (for authentication)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255),
    display_name VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(20),
    avatar_url TEXT,
    role VARCHAR(50) DEFAULT 'user' CHECK (role IN ('user', 'dentist', 'admin', 'superadmin')),
    two_factor_enabled BOOLEAN DEFAULT false,
    two_factor_secret VARCHAR(255),
    two_factor_backup_codes TEXT[],
    active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP,
    metadata JSONB DEFAULT '{}'::jsonb,
    patient_number VARCHAR(50) UNIQUE,
    date_of_birth DATE,
    pesel VARCHAR(11),
    address TEXT,
    city VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'Polska',
    notes TEXT,
    insurance_number VARCHAR(50),
    employment_type VARCHAR(50),
    employment_status VARCHAR(50) DEFAULT 'active',
    salary_type VARCHAR(50),
    hourly_rate DECIMAL(10, 2),
    monthly_salary DECIMAL(10, 2),
    hire_date DATE,
    termination_date DATE,
    department VARCHAR(100),
    position VARCHAR(100)
);

ALTER TABLE IF EXISTS users
    ADD COLUMN IF NOT EXISTS patient_number VARCHAR(50) UNIQUE,
    ADD COLUMN IF NOT EXISTS date_of_birth DATE,
    ADD COLUMN IF NOT EXISTS pesel VARCHAR(11),
    ADD COLUMN IF NOT EXISTS address TEXT,
    ADD COLUMN IF NOT EXISTS city VARCHAR(100),
    ADD COLUMN IF NOT EXISTS postal_code VARCHAR(20),
    ADD COLUMN IF NOT EXISTS country VARCHAR(100) DEFAULT 'Polska',
    ADD COLUMN IF NOT EXISTS notes TEXT,
    ADD COLUMN IF NOT EXISTS insurance_number VARCHAR(50),
    ADD COLUMN IF NOT EXISTS employment_type VARCHAR(50),
    ADD COLUMN IF NOT EXISTS employment_status VARCHAR(50) DEFAULT 'active',
    ADD COLUMN IF NOT EXISTS salary_type VARCHAR(50),
    ADD COLUMN IF NOT EXISTS hourly_rate DECIMAL(10, 2),
    ADD COLUMN IF NOT EXISTS monthly_salary DECIMAL(10, 2),
    ADD COLUMN IF NOT EXISTS hire_date DATE,
    ADD COLUMN IF NOT EXISTS termination_date DATE,
    ADD COLUMN IF NOT EXISTS department VARCHAR(100),
    ADD COLUMN IF NOT EXISTS position VARCHAR(100);

CREATE SEQUENCE IF NOT EXISTS patient_number_seq START 1;

CREATE OR REPLACE FUNCTION generate_user_patient_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.patient_number IS NULL OR NEW.patient_number = '' THEN
        NEW.patient_number := 'PAT-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(NEXTVAL('patient_number_seq')::TEXT, 4, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS generate_user_patient_number_trigger ON users;
CREATE TRIGGER generate_user_patient_number_trigger
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION generate_user_patient_number();

-- OAuth providers table
CREATE TABLE IF NOT EXISTS oauth_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider VARCHAR(50) NOT NULL, -- 'google', 'facebook', 'github', etc.
    provider_user_id VARCHAR(255) NOT NULL,
    access_token TEXT,
    refresh_token TEXT,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(provider, provider_user_id)
);

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(255) UNIQUE NOT NULL,
    refresh_token VARCHAR(255) UNIQUE,
    ip_address INET,
    user_agent TEXT,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked BOOLEAN DEFAULT false
);

-- Dentists table
CREATE TABLE IF NOT EXISTS dentists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    license_number VARCHAR(50) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    specialization VARCHAR(255)[],
    clinic_location VARCHAR(50) CHECK (clinic_location IN ('ceramix', 'esteticdent', 'both')),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Working hours for dentists
CREATE TABLE IF NOT EXISTS dentist_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dentist_id UUID NOT NULL REFERENCES dentists(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0 = Monday, 6 = Sunday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(dentist_id, day_of_week)
);

-- Appointments table
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    dentist_id UUID NOT NULL REFERENCES dentists(id) ON DELETE CASCADE,
    appointment_number VARCHAR(50) UNIQUE NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    duration_minutes INTEGER DEFAULT 60,
    status VARCHAR(50) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'confirmed', 'in_progress', 'completed', 'cancelled', 'no_show')),
    treatment_type VARCHAR(255),
    notes TEXT,
    reminder_sent BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Treatments table
CREATE TABLE IF NOT EXISTS treatments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    dentist_id UUID NOT NULL REFERENCES dentists(id) ON DELETE CASCADE,
    treatment_code VARCHAR(50),
    treatment_name VARCHAR(255) NOT NULL,
    description TEXT,
    tooth_number VARCHAR(20),
    cost DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
    treatment_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Invoices table
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    subtotal DECIMAL(10, 2) NOT NULL DEFAULT 0,
    tax_rate DECIMAL(5, 2) DEFAULT 23.00,
    tax_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    status VARCHAR(50) DEFAULT 'draft' CHECK (status IN ('draft', 'sent', 'paid', 'overdue', 'cancelled')),
    payment_method VARCHAR(50),
    paid_at TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Invoice items table
CREATE TABLE IF NOT EXISTS invoice_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    treatment_id UUID REFERENCES treatments(id) ON DELETE SET NULL,
    description VARCHAR(255) NOT NULL,
    quantity DECIMAL(10, 2) DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Payments table
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reference_number VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_oauth_accounts_user_id ON oauth_accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_users_patient_number ON users(patient_number);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_pesel ON users(pesel);
CREATE INDEX IF NOT EXISTS idx_users_employment_status ON users(employment_status);
CREATE INDEX IF NOT EXISTS idx_dentists_user_id ON dentists(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_dentist_id ON appointments(dentist_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_treatments_patient_id ON treatments(patient_id);
CREATE INDEX IF NOT EXISTS idx_treatments_dentist_id ON treatments(dentist_id);
CREATE INDEX IF NOT EXISTS idx_invoices_patient_id ON invoices(patient_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_payments_invoice_id ON payments(invoice_id);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_dentists_updated_at BEFORE UPDATE ON dentists FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_treatments_updated_at BEFORE UPDATE ON treatments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

