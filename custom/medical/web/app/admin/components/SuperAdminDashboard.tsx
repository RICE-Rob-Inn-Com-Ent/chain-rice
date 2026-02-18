import { query, queryMany } from "@/lib/db";
import dynamic from "next/dynamic";
import { trackComponentLoad } from "@/app/components/loading-tracker";

// Lazy load heavy components
const WeeklyCalendarBoard = dynamic(() => import("../appointments/WeeklyCalendarBoard"), {
  ssr: false,
  loading: () => {
    trackComponentLoad('WeeklyCalendarBoard', 10);
    return <div className="animate-pulse bg-white/5 rounded-lg h-96" />;
  },
});

const CerAI = dynamic(() => import("@/app/components/CerAI"), {
  ssr: false,
  loading: () => {
    trackComponentLoad('CerAI', 10);
    return <div className="animate-pulse bg-white/5 rounded-lg h-32" />;
  },
});

function startOfWeek(date: Date): Date {
  const utc = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = utc.getUTCDay();
  const diff = (day + 6) % 7;
  utc.setUTCDate(utc.getUTCDate() - diff);
  return utc;
}

function addDays(date: Date, days: number): Date {
  const copy = new Date(date);
  copy.setUTCDate(copy.getUTCDate() + days);
  return copy;
}

function formatISO(date: Date): string {
  return date.toISOString().split("T")[0];
}

async function ensureStaffSchedulesTable() {
  await query(`
    CREATE TABLE IF NOT EXISTS staff_schedules (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      staff_type VARCHAR(20) NOT NULL CHECK (staff_type IN ('dentist', 'admin')),
      staff_id VARCHAR(50) NOT NULL,
      day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
      start_time TIME NOT NULL,
      end_time TIME NOT NULL,
      location VARCHAR(100),
      notes TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    CREATE INDEX IF NOT EXISTS idx_staff_schedules_staff_id ON staff_schedules(staff_id);
  `);

  await query(`
    DO $$
    DECLARE
      col_type TEXT;
    BEGIN
      SELECT data_type INTO col_type
      FROM information_schema.columns
      WHERE table_name = 'staff_schedules' AND column_name = 'staff_id';

      IF col_type = 'uuid' THEN
        EXECUTE 'ALTER TABLE staff_schedules ALTER COLUMN staff_id TYPE VARCHAR(50) USING staff_id::text';
      END IF;
    END $$;
  `);
}

async function ensureCalendarSettingsTable() {
  await query(`
    CREATE TABLE IF NOT EXISTS calendar_settings (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      setting_key VARCHAR(100) UNIQUE NOT NULL,
      setting_value TEXT,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);
}

async function ensureClinicLocationsTable() {
  await query(`
    CREATE TABLE IF NOT EXISTS clinic_locations (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      owner_id VARCHAR(50) NOT NULL,
      name VARCHAR(100) NOT NULL,
      address TEXT,
      city VARCHAR(100),
      postal_code VARCHAR(20),
      phone VARCHAR(20),
      email VARCHAR(255),
      active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(owner_id, name)
    );
    CREATE INDEX IF NOT EXISTS idx_clinic_locations_owner_id ON clinic_locations(owner_id);
  `);

  // Tabela relacji użytkowników z lokalizacjami (many-to-many)
  await query(`
    CREATE TABLE IF NOT EXISTS user_locations (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id VARCHAR(50) NOT NULL,
      location_id UUID NOT NULL REFERENCES clinic_locations(id) ON DELETE CASCADE,
      role_at_location VARCHAR(50),
      active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(user_id, location_id)
    );
    CREATE INDEX IF NOT EXISTS idx_user_locations_user ON user_locations(user_id);
    CREATE INDEX IF NOT EXISTS idx_user_locations_location ON user_locations(location_id);
  `);

  // Tabela relacji lekarzy z lokalizacjami (many-to-many)
  await query(`
    CREATE TABLE IF NOT EXISTS dentist_locations (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      dentist_id UUID NOT NULL REFERENCES dentists(id) ON DELETE CASCADE,
      location_id UUID NOT NULL REFERENCES clinic_locations(id) ON DELETE CASCADE,
      active BOOLEAN DEFAULT true,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(dentist_id, location_id)
    );
    CREATE INDEX IF NOT EXISTS idx_dentist_locations_dentist ON dentist_locations(dentist_id);
    CREATE INDEX IF NOT EXISTS idx_dentist_locations_location ON dentist_locations(location_id);
  `);

  // Dodaj location_id do appointments
  await query(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'appointments' AND column_name = 'location_id'
      ) THEN
        ALTER TABLE appointments 
        ADD COLUMN location_id UUID REFERENCES clinic_locations(id) ON DELETE SET NULL;
        CREATE INDEX IF NOT EXISTS idx_appointments_location ON appointments(location_id);
      END IF;
    END $$;
  `);

  // Dodaj location_id do staff_schedules
  await query(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'staff_schedules' AND column_name = 'location_id'
      ) THEN
        ALTER TABLE staff_schedules 
        ADD COLUMN location_id UUID REFERENCES clinic_locations(id) ON DELETE SET NULL;
        CREATE INDEX IF NOT EXISTS idx_staff_schedules_location ON staff_schedules(location_id);
      END IF;
    END $$;
  `);
}

async function getWorkingHours(): Promise<{ start: string | null; end: string | null }> {
  await ensureCalendarSettingsTable();

  const startResult = await query<{ setting_value: string | null }>(
    `SELECT setting_value FROM calendar_settings WHERE setting_key = 'working_hours_start'`
  );
  const endResult = await query<{ setting_value: string | null }>(
    `SELECT setting_value FROM calendar_settings WHERE setting_key = 'working_hours_end'`
  );

  return {
    start: startResult?.setting_value || null,
    end: endResult?.setting_value || null,
  };
}

async function ensureDoctorsTableCompatibility() {
  await query(`
    DO $$
    DECLARE
      col_type TEXT;
    BEGIN
      SELECT data_type INTO col_type
      FROM information_schema.columns
      WHERE table_name = 'dentists' AND column_name = 'user_id';

      IF col_type = 'uuid' THEN
        EXECUTE 'ALTER TABLE dentists ALTER COLUMN user_id TYPE VARCHAR(50) USING user_id::text';
      END IF;
    END $$;
  `);

  await query(`
    UPDATE dentists
    SET user_id = NULL
    WHERE user_id IS NOT NULL
      AND NOT EXISTS (SELECT 1 FROM users WHERE users.id = dentists.user_id);
  `);

  await query(`
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'dentists' AND constraint_name = 'dentists_user_id_fkey'
      ) THEN
        ALTER TABLE dentists DROP CONSTRAINT dentists_user_id_fkey;
      END IF;
    END $$;
  `);

  await query(`
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE table_name = 'dentists' AND constraint_name = 'dentists_user_id_fkey'
      ) THEN
        ALTER TABLE dentists
          ADD CONSTRAINT dentists_user_id_fkey
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL;
      END IF;
    END $$;
  `);
}

async function ensureDoctorRecords() {
  await ensureDoctorsTableCompatibility();
  // Ensure every user with doctor role has a record in dentists table
  // Uses DOC-% ID prefix to identify doctors (role-based ID system)
  // Note: Table is still named 'dentists' for backward compatibility, but it stores all doctors (dentists, endocrinologists, etc.)
  // Generate unique license_number using full user ID (replacing dashes) to ensure uniqueness
  await query(`
    INSERT INTO dentists (
      id,
      license_number,
      user_id,
      first_name,
      last_name,
      email,
      phone,
      specialization,
      clinic_location,
      bio,
      hourly_rate,
      active,
      created_at,
      updated_at
    )
    SELECT
      uuid_generate_v4(),
      CONCAT('AUTO-', REPLACE(u.id::text, '-', '')),
      u.id,
      COALESCE(NULLIF(u.first_name, ''), split_part(u.display_name, ' ', 1), 'Lekarz'),
      COALESCE(NULLIF(u.last_name, ''), NULLIF(split_part(u.display_name, ' ', 2), ''), 'Ceramix'),
      u.email,
      NULL,
      NULL,
      'ceramix',
      NULL,
      NULL,
      TRUE,
      CURRENT_TIMESTAMP,
      CURRENT_TIMESTAMP
    FROM users u
    WHERE u.id::text LIKE 'DOC-%'
      AND u.active = true
      AND NOT EXISTS (
        SELECT 1 FROM dentists d WHERE d.user_id = u.id
      )
    ON CONFLICT (license_number) DO NOTHING;
  `);
}

type PatientOption = {
  id: string;
  display_name: string;
  patient_number: string | null;
};

type StaffOption = {
  id: string;
  name: string;
};

type ScheduleRow = {
  id: string;
  staff_type: "dentist" | "admin";
  staff_id: string;
  staff_name: string;
  day_of_week: number;
  start_time: string;
  end_time: string;
  location: string | null;
  notes: string | null;
};

type AppointmentRow = {
  id: string;
  appointment_number: string;
  appointment_date: string;
  appointment_time: string;
  duration_minutes: number;
  status: string;
  treatment_type: string | null;
  patient_name: string;
  patient_id: string;
  dentist_name: string;
  dentist_id: string;
};

export default async function SuperAdminDashboard() {
  // Prepare calendar data - 30 days from today
  const today = new Date();
  const startDate = today; // Start from today
  const days = Array.from({ length: 30 }, (_, idx) => addDays(startDate, idx));
  const weekMeta = {
    startISO: formatISO(startDate),
    endISO: formatISO(addDays(startDate, 29)),
    days: days.map((day, idx) => ({
      date: formatISO(day),
      label: day.toLocaleDateString("pl-PL", { weekday: "long", day: "2-digit", month: "2-digit" }),
      shortLabel: day.toLocaleDateString("pl-PL", { weekday: "short", day: "2-digit" }),
      dayIndex: (day.getUTCDay() + 6) % 7, // Monday = 0
    })),
  };

  await ensureStaffSchedulesTable();
  await ensureDoctorRecords();
  await ensureClinicLocationsTable();

  const startDateParam = weekMeta.startISO;
  const endDateParam = weekMeta.endISO;
  const todayISO = formatISO(today);

  const [appointmentsData, patientsData, dentistsData, schedulesData] = await Promise.all([
    queryMany<AppointmentRow & { location_id: string | null }>(
      `SELECT
        a.id,
        a.appointment_number,
        a.appointment_date::text,
        to_char(a.appointment_time, 'HH24:MI') as appointment_time,
        a.duration_minutes,
        a.status,
        a.treatment_type,
        CONCAT(p.first_name, ' ', p.last_name) as patient_name,
        a.patient_id::text as patient_id,
        CONCAT(d.first_name, ' ', d.last_name) as dentist_name,
        a.dentist_id::text as dentist_id,
        a.location_id::text as location_id
     FROM appointments a
     JOIN users p ON a.patient_id::text = p.id
     JOIN dentists d ON a.dentist_id = d.id
       WHERE a.appointment_date BETWEEN $1 AND $2
       ORDER BY a.appointment_date ASC, a.appointment_time ASC`,
      [startDateParam, endDateParam]
    ),
    queryMany<PatientOption>(
      `SELECT
        p.id,
        COALESCE(NULLIF(p.first_name, ''), 'Pacjent') || ' ' || COALESCE(NULLIF(p.last_name, ''), 'Ceramix') as display_name,
        p.patient_number,
        p.email,
        p.phone
      FROM patients p
      WHERE p.active = true
      ORDER BY p.created_at DESC
       LIMIT 200`
    ),
    queryMany<{ id: string; first_name: string | null; last_name: string | null }>(
      `SELECT DISTINCT d.id, d.first_name, d.last_name, COALESCE(d.last_name, '') as last_name_sort, COALESCE(d.first_name, '') as first_name_sort
     FROM dentists d
     LEFT JOIN users u ON d.user_id = u.id
     WHERE d.active = true 
       AND (d.user_id IS NULL OR u.active = true)
     ORDER BY last_name_sort, first_name_sort`
    ),
    queryMany<ScheduleRow>(
      `SELECT
        ss.id,
        ss.staff_type,
        ss.staff_id,
        ss.day_of_week,
        to_char(ss.start_time, 'HH24:MI') as start_time,
        to_char(ss.end_time, 'HH24:MI') as end_time,
        ss.location,
        ss.notes,
        CASE
          WHEN ss.staff_type = 'dentist'
            THEN CONCAT(d.first_name, ' ', d.last_name)
          ELSE u.display_name
        END AS staff_name
       FROM staff_schedules ss
       LEFT JOIN dentists d ON d.id::text = ss.staff_id AND ss.staff_type = 'dentist'
       LEFT JOIN users u_dentist ON d.user_id = u_dentist.id AND ss.staff_type = 'dentist'
       LEFT JOIN users u ON u.id = ss.staff_id AND ss.staff_type = 'admin'
       WHERE (ss.staff_type = 'dentist' AND u_dentist.active = true)
          OR (ss.staff_type = 'admin' AND u.active = true)
          OR (ss.staff_type NOT IN ('dentist', 'admin'))
       ORDER BY ss.day_of_week, ss.start_time`
    ),
  ]);

  const appointments = appointmentsData.map((apt) => ({
    id: apt.id,
    appointmentNumber: apt.appointment_number,
    date: apt.appointment_date,
    startTime: apt.appointment_time,
    durationMinutes: apt.duration_minutes,
    status: apt.status,
    treatmentType: apt.treatment_type,
    patientName: apt.patient_name,
    patientId: apt.patient_id,
    dentistName: apt.dentist_name,
    dentistId: apt.dentist_id,
    location_id: (apt as any).location_id || null,
  }));

  const patients = patientsData.map((patient) => ({
    ...patient,
    display_name: patient.display_name?.trim() || "Bez nazwy",
  }));

  let doctorOptions = dentistsData;

  if (doctorOptions.length === 0) {
    // Fallback: jeśli nie ma lekarzy w tabeli dentists, pobierz przez user_id
    // WAŻNE: zawsze zwracamy ID z tabeli dentists, nie z users!
    // Najpierw upewnij się, że wszyscy lekarze mają rekordy w dentists
    await ensureDoctorRecords();
    
    doctorOptions = await queryMany<{ id: string; first_name: string | null; last_name: string | null }>(
      `SELECT d.id, d.first_name, d.last_name
       FROM dentists d
       LEFT JOIN users u ON d.user_id = u.id
       WHERE d.active = true
         AND (d.user_id IS NULL OR u.active = true)
       ORDER BY COALESCE(d.last_name, ''), COALESCE(d.first_name, '')`
    );
  }

  const doctors: StaffOption[] = doctorOptions.map((doctor) => ({
    id: doctor.id,
    name: `${doctor.first_name || ""} ${doctor.last_name || ""}`.trim() || "Lekarz",
  }));

  const doctorSchedules = schedulesData.filter((s) => s.staff_type === "dentist");

  // Get working hours settings
  const workingHours = await getWorkingHours();

  return (
    <div className="relative min-h-screen">
      {/* Calendar Section */}
      <div className="flex flex-col h-full min-h-0">
        <WeeklyCalendarBoard
          week={weekMeta}
          appointments={appointments}
          patients={patients}
          doctors={doctors}
          doctorSchedules={doctorSchedules}
          todayISO={todayISO}
          workingHoursStart={workingHours.start || undefined}
          workingHoursEnd={workingHours.end || undefined}
        />
      </div>

      {/* CerAI Chat Widget */}
      <CerAI botType="client_management" context="dashboard" />
    </div>
  );
}

