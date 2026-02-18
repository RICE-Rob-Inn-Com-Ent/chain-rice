-- Ceramix Database Schema
-- Pełny schemat dla aplikacji Ceramix

-- ============================================================================
-- Rozszerzenie tabeli users – dane pacjentów oraz kadrowe
-- ============================================================================
ALTER TABLE IF EXISTS users
    ADD COLUMN IF NOT EXISTS patient_number VARCHAR(50),
    ADD COLUMN IF NOT EXISTS phone VARCHAR(20),
    ADD COLUMN IF NOT EXISTS date_of_birth DATE,
    ADD COLUMN IF NOT EXISTS pesel VARCHAR(11),
    ADD COLUMN IF NOT EXISTS address TEXT,
    ADD COLUMN IF NOT EXISTS city VARCHAR(100),
    ADD COLUMN IF NOT EXISTS postal_code VARCHAR(10),
    ADD COLUMN IF NOT EXISTS country VARCHAR(100) DEFAULT 'Polska',
    ADD COLUMN IF NOT EXISTS notes TEXT,
    ADD COLUMN IF NOT EXISTS insurance_number VARCHAR(50),
    ADD COLUMN IF NOT EXISTS employment_type VARCHAR(50), -- full_time, part_time, contract
    ADD COLUMN IF NOT EXISTS employment_status VARCHAR(50) DEFAULT 'active',
    ADD COLUMN IF NOT EXISTS salary_type VARCHAR(50), -- hourly, monthly, per_visit
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

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_patient_number ON users(patient_number);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_pesel ON users(pesel);
CREATE INDEX IF NOT EXISTS idx_users_employment_status ON users(employment_status);

-- Migracja istniejących pacjentów do tabeli users (jeśli tabela patients nadal istnieje)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'patients'
    ) THEN
        INSERT INTO users (
            id, email, display_name, first_name, last_name,
            phone, date_of_birth, pesel, address, city, postal_code,
            country, notes, insurance_number, active, created_at, updated_at,
            patient_number
        )
        SELECT
            p.id,
            COALESCE(NULLIF(p.email, ''), CONCAT('patient-', p.id::text, '@ceramix.local')),
            CONCAT(p.first_name, ' ', p.last_name),
            p.first_name,
            p.last_name,
            p.phone,
            p.date_of_birth,
            p.pesel,
            p.address,
            p.city,
            p.postal_code,
            COALESCE(p.country, 'Polska'),
            p.notes,
            p.insurance_number,
            p.active,
            COALESCE(p.created_at, CURRENT_TIMESTAMP),
            COALESCE(p.updated_at, CURRENT_TIMESTAMP),
            p.patient_number
        FROM patients p
        ON CONFLICT (id) DO UPDATE SET
            phone = EXCLUDED.phone,
            date_of_birth = EXCLUDED.date_of_birth,
            pesel = EXCLUDED.pesel,
            address = EXCLUDED.address,
            city = EXCLUDED.city,
            postal_code = EXCLUDED.postal_code,
            country = EXCLUDED.country,
            notes = EXCLUDED.notes,
            insurance_number = EXCLUDED.insurance_number,
            patient_number = COALESCE(users.patient_number, EXCLUDED.patient_number),
            updated_at = CURRENT_TIMESTAMP;
    END IF;
END;
$$;

INSERT INTO user_roles (user_id, role, granted_at)
SELECT u.id, 'user', NOW()
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM user_roles ur WHERE ur.user_id = u.id AND ur.role = 'user'
);

-- Dentyści
CREATE TABLE IF NOT EXISTS dentists (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    license_number VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID REFERENCES users(id),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20),
    specialization TEXT[], -- Array of specializations
    clinic_location VARCHAR(50) DEFAULT 'ceramix', -- ceramix, esteticdent, both
    bio TEXT,
    hourly_rate DECIMAL(10, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    active BOOLEAN DEFAULT true
);

-- Wizyty
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appointment_number VARCHAR(50) UNIQUE NOT NULL,
    patient_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    dentist_id UUID NOT NULL REFERENCES dentists(id) ON DELETE CASCADE,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    duration_minutes INTEGER DEFAULT 30,
    status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, confirmed, in_progress, completed, cancelled, no_show
    treatment_type VARCHAR(100),
    treatment_description TEXT,
    notes TEXT,
    price DECIMAL(10, 2),
    paid BOOLEAN DEFAULT false,
    payment_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL
);

-- Usługi/Typy leczenia
CREATE TABLE IF NOT EXISTS treatment_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    default_duration_minutes INTEGER DEFAULT 30,
    default_price DECIMAL(10, 2),
    category VARCHAR(100), -- protetyka, implantologia, zachowawcza, ortodoncja
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indeksy
CREATE INDEX IF NOT EXISTS idx_dentists_license ON dentists(license_number);
CREATE INDEX IF NOT EXISTS idx_dentists_user_id ON dentists(user_id);
CREATE INDEX IF NOT EXISTS idx_appointments_patient ON appointments(patient_id);
CREATE INDEX IF NOT EXISTS idx_appointments_dentist ON appointments(dentist_id);
CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_number ON appointments(appointment_number);

-- Upewnij się, że klucze obce wskazują na tabelę users
ALTER TABLE IF EXISTS appointments
    DROP CONSTRAINT IF EXISTS appointments_patient_id_fkey,
    ADD CONSTRAINT appointments_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS invoices
    DROP CONSTRAINT IF EXISTS invoices_patient_id_fkey,
    ADD CONSTRAINT invoices_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES users(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS payments
    DROP CONSTRAINT IF EXISTS payments_patient_id_fkey,
    ADD CONSTRAINT payments_patient_id_fkey FOREIGN KEY (patient_id) REFERENCES users(id) ON DELETE CASCADE;

-- Funkcje pomocnicze
CREATE OR REPLACE FUNCTION generate_appointment_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.appointment_number IS NULL OR NEW.appointment_number = '' THEN
        NEW.appointment_number := 'APT-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(NEXTVAL('appointment_number_seq')::TEXT, 4, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS appointment_number_seq START 1;

-- Triggery
DROP TRIGGER IF EXISTS generate_appointment_number_trigger ON appointments;
CREATE TRIGGER generate_appointment_number_trigger
    BEFORE INSERT ON appointments
    FOR EACH ROW
    EXECUTE FUNCTION generate_appointment_number();

DROP TRIGGER IF EXISTS update_dentists_updated_at ON dentists;
CREATE TRIGGER update_dentists_updated_at BEFORE UPDATE ON dentists
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_appointments_updated_at ON appointments;
CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Faktury
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_number VARCHAR(50) UNIQUE NOT NULL,
    patient_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    issue_date DATE NOT NULL DEFAULT CURRENT_DATE,
    due_date DATE NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0,
    tax_amount DECIMAL(10, 2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'draft', -- draft, sent, paid, overdue, cancelled
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL
);

-- Płatności
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    patient_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_method VARCHAR(50) NOT NULL, -- cash, card, transfer
    payment_date DATE NOT NULL DEFAULT CURRENT_DATE,
    paid_at TIMESTAMP,
    reference_number VARCHAR(100),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL
);

-- Indeksy dla faktur i płatności
CREATE INDEX IF NOT EXISTS idx_invoices_patient ON invoices(patient_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_issue_date ON invoices(issue_date);
CREATE INDEX IF NOT EXISTS idx_invoices_number ON invoices(invoice_number);
CREATE INDEX IF NOT EXISTS idx_payments_invoice ON payments(invoice_id);
CREATE INDEX IF NOT EXISTS idx_payments_patient ON payments(patient_id);
CREATE INDEX IF NOT EXISTS idx_payments_date ON payments(payment_date);
CREATE INDEX IF NOT EXISTS idx_payments_paid_at ON payments(paid_at);

-- Posprzątaj stare struktury pacjentów
DROP INDEX IF EXISTS idx_patients_email;
DROP INDEX IF EXISTS idx_patients_phone;
DROP INDEX IF EXISTS idx_patients_patient_number;
DROP TABLE IF EXISTS patients;

-- Triggery dla faktur i płatności
DROP TRIGGER IF EXISTS update_invoices_updated_at ON invoices;
CREATE TRIGGER update_invoices_updated_at BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Funkcja do generowania numeru faktury
CREATE OR REPLACE FUNCTION generate_invoice_number()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invoice_number IS NULL OR NEW.invoice_number = '' THEN
        NEW.invoice_number := 'FV-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || LPAD(NEXTVAL('invoice_number_seq')::TEXT, 4, '0');
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE SEQUENCE IF NOT EXISTS invoice_number_seq START 1;

DROP TRIGGER IF EXISTS generate_invoice_number_trigger ON invoices;
CREATE TRIGGER generate_invoice_number_trigger
    BEFORE INSERT ON invoices
    FOR EACH ROW
    EXECUTE FUNCTION generate_invoice_number();

-- Przykładowe dane
INSERT INTO treatment_types (code, name, description, default_duration_minutes, default_price, category) VALUES
('KONSULTACJA', 'Konsultacja', 'Wstępna konsultacja stomatologiczna', 30, 200, 'zachowawcza'),
('CZYSZCZENIE', 'Czyszczenie zębów', 'Profesjonalne czyszczenie i piaskowanie', 45, 150, 'zachowawcza'),
('PLOMBA', 'Plomba', 'Wypełnienie ubytku', 60, 300, 'zachowawcza'),
('KORONA', 'Korona ceramiczna', 'Korona protetyczna', 120, 2000, 'protetyka'),
('IMPLANT', 'Implant zębowy', 'Wszczepienie implantu', 180, 5000, 'implantologia'),
('WYBIELANIE', 'Wybielanie zębów', 'Zabieg wybielania', 90, 1500, 'zachowawcza'),
('APARAT', 'Aparat ortodontyczny', 'Konsultacja i założenie aparatu', 60, 3000, 'ortodoncja')
ON CONFLICT (code) DO NOTHING;

-- ============================================================================
-- Dental Chart Schema
-- ============================================================================

-- Dental visits table
CREATE TABLE IF NOT EXISTS dental_visits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    visit_date DATE NOT NULL DEFAULT CURRENT_DATE,
    visit_time TIME,
    dentist_id UUID REFERENCES dentists(id),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL
);

-- Dental chart entries table
CREATE TABLE IF NOT EXISTS dental_chart_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id UUID REFERENCES dental_visits(id) ON DELETE CASCADE,
    patient_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tooth_number INTEGER NOT NULL CHECK (tooth_number >= 11 AND tooth_number <= 48),
    surface VARCHAR(10), -- PZ, BS, PM, PD, PI, PW
    category VARCHAR(50) NOT NULL, -- conservative, endo, prosthetics, surgery
    condition_type VARCHAR(100) NOT NULL, -- e.g., 'próchnica', 'wypełnienie', 'korona', etc.
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL
);

-- Custom entries for dental chart
CREATE TABLE IF NOT EXISTS dental_chart_custom_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id UUID REFERENCES dental_visits(id) ON DELETE CASCADE,
    patient_id VARCHAR(50) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    tooth_number INTEGER NOT NULL CHECK (tooth_number >= 11 AND tooth_number <= 48),
    custom_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_dental_visits_patient ON dental_visits(patient_id);
CREATE INDEX IF NOT EXISTS idx_dental_visits_date ON dental_visits(visit_date);
CREATE INDEX IF NOT EXISTS idx_dental_chart_entries_patient ON dental_chart_entries(patient_id);
CREATE INDEX IF NOT EXISTS idx_dental_chart_entries_visit ON dental_chart_entries(visit_id);
CREATE INDEX IF NOT EXISTS idx_dental_chart_entries_tooth ON dental_chart_entries(tooth_number);
CREATE INDEX IF NOT EXISTS idx_dental_chart_custom_patient ON dental_chart_custom_entries(patient_id);
CREATE INDEX IF NOT EXISTS idx_dental_chart_custom_visit ON dental_chart_custom_entries(visit_id);
CREATE INDEX IF NOT EXISTS idx_dental_chart_custom_tooth ON dental_chart_custom_entries(tooth_number);

-- Triggers
DROP TRIGGER IF EXISTS update_dental_visits_updated_at ON dental_visits;
CREATE TRIGGER update_dental_visits_updated_at BEFORE UPDATE ON dental_visits
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_dental_chart_entries_updated_at ON dental_chart_entries;
CREATE TRIGGER update_dental_chart_entries_updated_at BEFORE UPDATE ON dental_chart_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_dental_chart_custom_updated_at ON dental_chart_custom_entries;
CREATE TRIGGER update_dental_chart_custom_updated_at BEFORE UPDATE ON dental_chart_custom_entries
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

