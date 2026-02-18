-- Dental Chart Schema for Ceramix
-- Schema for storing dental charting data

-- Dental visits table
-- patient_id can reference either users.id or patients table
CREATE TABLE IF NOT EXISTS dental_visits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id VARCHAR(50) NOT NULL, -- Can be from users or patients table
    visit_date DATE NOT NULL DEFAULT CURRENT_DATE,
    visit_time TIME,
    dentist_id UUID REFERENCES dentists(id),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(50) REFERENCES users(id) ON DELETE SET NULL
);

-- Dental chart entries table
-- patient_id can reference either users.id or patients.id
CREATE TABLE IF NOT EXISTS dental_chart_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id UUID REFERENCES dental_visits(id) ON DELETE CASCADE,
    patient_id VARCHAR(50) NOT NULL, -- Can be from users or patients table
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
-- patient_id can reference either users.id or patients.id
CREATE TABLE IF NOT EXISTS dental_chart_custom_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    visit_id UUID REFERENCES dental_visits(id) ON DELETE CASCADE,
    patient_id VARCHAR(50) NOT NULL, -- Can be from users or patients table
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

