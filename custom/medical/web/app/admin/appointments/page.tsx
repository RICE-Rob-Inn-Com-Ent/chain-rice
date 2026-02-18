import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { query, queryMany } from "@/lib/db";
import dynamic from "next/dynamic";
import { trackComponentLoad } from "@/app/components/loading-tracker";

// Lazy load WeeklyCalendarBoard for better performance
const WeeklyCalendarBoard = dynamic(() => import("./WeeklyCalendarBoard"), {
  ssr: false,
  loading: () => {
    trackComponentLoad('WeeklyCalendarBoard', 10);
    return <div className="animate-pulse bg-white/5 rounded-lg h-96" />;
  },
});

type SearchParams = {
  week?: string;
};

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
  dentist_id?: string | null;
  dentist_user_id?: string | null;
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

function startOfWeek(date: Date): Date {
  const utc = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  const day = utc.getUTCDay();
  const diff = (day + 6) % 7;
  utc.setUTCDate(utc.getUTCDate() - diff);
  return utc;
}

function addDays(date: Date, days: number): Date {
  const copy = new Date(date.getTime());
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

export default async function WizytyPage({ searchParams }: { searchParams: SearchParams }) {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/sign-in");
  }

  // Generate 60 days: 30 days before and 30 days after today
  const today = new Date();
  const startDate = addDays(today, -30);
  const days = Array.from({ length: 60 }, (_, idx) => addDays(startDate, idx));
  const weekMeta = {
    startISO: formatISO(startDate),
    endISO: formatISO(addDays(startDate, 59)),
    days: days.map((day, idx) => ({
      date: formatISO(day),
      label: day.toLocaleDateString("pl-PL", { weekday: "long", day: "2-digit", month: "2-digit" }),
      shortLabel: day.toLocaleDateString("pl-PL", { weekday: "short", day: "2-digit" }),
      dayIndex: idx,
    })),
  };

  await ensureStaffSchedulesTable();

  const startDateParam = weekMeta.startISO;
  const endDateParam = weekMeta.endISO;
  const todayISO = formatISO(today);

  const [appointmentsData, patientsData, dentistsData, schedulesData] = await Promise.all([
    queryMany<AppointmentRow>(
    `SELECT 
        a.id,
        a.appointment_number,
        a.appointment_date::text,
        to_char(a.appointment_time, 'HH24:MI') as appointment_time,
        a.duration_minutes,
        a.status,
        a.treatment_type,
        tt.name as treatment_type_name,
        CONCAT(p.first_name, ' ', p.last_name) as patient_name,
        a.patient_id::text as patient_id,
        get_patient_number(p.id) as patient_number,
        p.username as patient_username,
        CONCAT(d.first_name, ' ', d.last_name) as dentist_name,
        d.id::text as dentist_id
     FROM appointments a
     LEFT JOIN users p ON a.patient_id::text = p.id::text
     LEFT JOIN dentists d ON a.dentist_id = d.id
     LEFT JOIN treatment_types tt ON a.treatment_type::text = tt.id::text
       WHERE a.appointment_date BETWEEN $1 AND $2
       ORDER BY a.appointment_date ASC, a.appointment_time ASC`,
      [startDateParam, endDateParam]
    ),
    queryMany<PatientOption>(
      `SELECT 
        u.id,
        COALESCE(NULLIF(u.display_name, ''), CONCAT(u.first_name, ' ', u.last_name)) as display_name,
        get_patient_number(u.id) as patient_number
       FROM users u
       WHERE NOT (u.id::text LIKE 'ADM-%' OR u.id::text LIKE 'SUP-%' OR u.id::text LIKE 'DOC-%')
       ORDER BY u.created_at DESC
       LIMIT 200`
    ),
    queryMany<{ id: string; first_name: string | null; last_name: string | null }>(
      `SELECT id, first_name, last_name
     FROM dentists 
       WHERE active = true
     ORDER BY last_name, first_name`
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
        END AS staff_name,
        d.id::text as dentist_id,
        d.user_id as dentist_user_id
       FROM staff_schedules ss
       LEFT JOIN dentists d ON (d.id::text = ss.staff_id OR d.user_id = ss.staff_id) AND ss.staff_type = 'dentist'
       LEFT JOIN users u ON u.id = ss.staff_id AND ss.staff_type = 'admin'
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
    treatmentType: (apt as any).treatment_type_name || apt.treatment_type || null,
    patientName: apt.patient_name || "Nieznany pacjent",
    patientId: apt.patient_id,
    patientNumber: apt.patient_number || null,
    patientUsername: apt.patient_username || null,
    dentistName: apt.dentist_name || "Nieznany dentysta",
    dentistId: apt.dentist_id || "",
  }));

  const patients = patientsData.map((patient) => ({
    ...patient,
    display_name: patient.display_name?.trim() || "Bez nazwy",
  }));

  let dentistOptions = dentistsData;
  if (dentistOptions.length === 0) {
    dentistOptions = await queryMany<{ id: string; first_name: string | null; last_name: string | null }>(
      `SELECT u.id, u.first_name, u.last_name
       FROM users u
       WHERE u.id::text LIKE 'DOC-%'
       ORDER BY COALESCE(u.last_name, ''), COALESCE(u.first_name, '')`
    );
  }

  const doctors: StaffOption[] = dentistOptions.map((dentist) => ({
    id: dentist.id,
    name: `${dentist.first_name || ""} ${dentist.last_name || ""}`.trim() || "Dentysta",
  }));

  const doctorSchedules = schedulesData.filter((s) => s.staff_type === "dentist");

  return (
    <div className="w-full">
      <WeeklyCalendarBoard
        week={weekMeta}
        appointments={appointments}
        patients={patients}
        doctors={doctors}
        doctorSchedules={doctorSchedules}
        todayISO={todayISO}
      />
    </div>
  );
}

