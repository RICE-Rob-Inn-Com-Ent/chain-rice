import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { query, queryOne } from "@/lib/db";
import { isAdminOrOwner } from "@/lib/rbac";

// GET - Lista wizyt
export async function GET(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const { searchParams } = new URL(request.url);
    const patientId = searchParams.get("patient_id");
    const dentistId = searchParams.get("dentist_id");
    const dateFrom = searchParams.get("date_from");
    const dateTo = searchParams.get("date_to");
    const status = searchParams.get("status");
    const locationId = searchParams.get("location_id");

    let sql = `
      SELECT 
        a.id,
        a.appointment_number,
        a.appointment_date,
        to_char(a.appointment_time, 'HH24:MI') as appointment_time,
        a.duration_minutes,
        a.status,
        a.treatment_type,
        tt.name as treatment_type_name,
        a.patient_id::text as patient_id,
        d.id::text as dentist_id,
        CONCAT(p.first_name, ' ', p.last_name) as patient_name,
        CONCAT(d.first_name, ' ', d.last_name) as dentist_name,
        get_patient_number(p.id) as patient_number,
        p.username as patient_username
      FROM appointments a
      LEFT JOIN users p ON a.patient_id::text = p.id::text
      LEFT JOIN dentists d ON a.dentist_id = d.id
      LEFT JOIN treatment_types tt ON a.treatment_type::text = tt.id::text
      WHERE 1=1
    `;
    const params: any[] = [];
    let paramIndex = 1;

    // Filtrowanie dla dentysty - tylko swoje wizyty
    if (user.role === "dentist") {
      const dentist = await queryOne(`SELECT id FROM dentists WHERE user_id = $1`, [user.id]);
      if (dentist) {
        sql += ` AND a.dentist_id = $${paramIndex}`;
        params.push(dentist.id);
        paramIndex++;
      }
    }

    if (patientId) {
      sql += ` AND a.patient_id = $${paramIndex}`;
      params.push(patientId);
      paramIndex++;
    }

    if (dentistId && (user.role === "admin" || user.role === "superadmin")) {
      sql += ` AND a.dentist_id = $${paramIndex}`;
      params.push(dentistId);
      paramIndex++;
    }

    if (dateFrom) {
      sql += ` AND a.appointment_date >= $${paramIndex}`;
      params.push(dateFrom);
      paramIndex++;
    }

    if (dateTo) {
      sql += ` AND a.appointment_date <= $${paramIndex}`;
      params.push(dateTo);
      paramIndex++;
    }

    if (status) {
      sql += ` AND a.status = $${paramIndex}`;
      params.push(status);
      paramIndex++;
    }

    // Filtrowanie po lokalizacji
    if (locationId) {
      sql += ` AND a.location_id = $${paramIndex}`;
      params.push(locationId);
      paramIndex++;
    } else {
      // Jeśli nie podano location_id, pokaż tylko wizyty bez przypisanej lokalizacji lub wszystkie (dla owner)
      // Owner widzi wszystkie, inni tylko swoje lokalizacje
      if (user.role !== "owner") {
        sql += ` AND (
          a.location_id IS NULL 
          OR EXISTS (
            SELECT 1 FROM user_locations ul 
            WHERE ul.user_id = $${paramIndex} 
            AND ul.location_id = a.location_id
            AND ul.active = true
          )
        )`;
        params.push(user.id);
        paramIndex++;
      }
    }

    sql += ` ORDER BY a.appointment_date DESC, a.appointment_time DESC LIMIT 100`;

    const appointments = await query(sql, params);

    return NextResponse.json({ appointments: appointments.rows });
  } catch (error: any) {
    console.error("Get appointments error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST - Utwórz wizytę
export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }
    
    // Allow admin, owner, superadmin, and dentist to create appointments
    const canCreate = isAdminOrOwner(user.id) || user.role === "superadmin" || user.role === "dentist";
    if (!canCreate) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    let {
      patient_id,
      dentist_id,
      appointment_date,
      appointment_time,
      duration_minutes,
      treatment_type,
      treatment_description,
      notes,
      price,
      location_id,
    } = body;

    if (!patient_id || !dentist_id || !appointment_date || !appointment_time) {
      return NextResponse.json(
        { error: "Pacjent, dentysta, data i godzina są wymagane" },
        { status: 400 }
      );
    }

    // Validate location_id is a valid UUID if provided
    if (location_id !== null && location_id !== undefined && String(location_id).trim() !== "") {
      const locationIdStr = String(location_id).trim();
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidRegex.test(locationIdStr)) {
        console.error("Invalid location_id format:", locationIdStr);
        return NextResponse.json(
          { error: "Nieprawidłowy format ID lokalizacji. Musi być UUID." },
          { status: 400 }
        );
      }
      // Use validated UUID
      location_id = locationIdStr;
    } else {
      // Set to null if empty, undefined, or null
      location_id = null;
    }

    // Validate date is not in the past
    const appointmentDate = new Date(appointment_date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    appointmentDate.setHours(0, 0, 0, 0);
    
    if (appointmentDate < today) {
      return NextResponse.json(
        { error: "Nie można dodawać wizyt w przeszłości." },
        { status: 400 }
      );
    }

    // Check for time conflicts with existing appointments for the same dentist
    const duration = duration_minutes || 30;
    
    // Check for overlapping appointments using time range overlap logic
    // Two appointments overlap if: new_start < existing_end AND new_end > existing_start
    // Also check if new appointment is completely within existing appointment or vice versa
    const conflictingAppointments = await query(
      `SELECT id, appointment_time, duration_minutes, appointment_number, status
       FROM appointments
       WHERE dentist_id = $1
         AND appointment_date = $2
         AND (status IS NULL OR status != 'cancelled')
         AND (
           -- Check if new appointment overlaps with existing appointment
           -- New appointment starts before existing appointment ends
           ($3::time < (appointment_time::time + COALESCE(duration_minutes, 30) * INTERVAL '1 minute'))
           AND
           -- New appointment ends after existing appointment starts
           (($3::time + $4::integer * INTERVAL '1 minute') > appointment_time::time)
         )`,
      [dentist_id, appointment_date, appointment_time, duration]
    );

    if (conflictingAppointments.rows.length > 0) {
      return NextResponse.json(
        { error: "Lekarz ma już zarezerwowaną wizytę w tym czasie. Wybierz inny termin." },
        { status: 400 }
      );
    }

    // Sprawdź czy dentysta może tworzyć tylko swoje wizyty
    if (user.role === "dentist") {
      const userDentist = await queryOne(`SELECT id FROM dentists WHERE user_id = $1`, [user.id]);
      if (!userDentist || userDentist.id !== dentist_id) {
        return NextResponse.json({ error: "Możesz tworzyć tylko swoje wizyty" }, { status: 403 });
      }
    }

    // Validate location opening hours if location_id is provided
    if (location_id) {
      const location = await queryOne<{ opening_hours: any }>(
        `SELECT opening_hours FROM clinic_locations WHERE id = $1`,
        [location_id]
      );

      if (location && location.opening_hours) {
        // Get day of week (0 = Monday, 6 = Sunday)
        const appointmentDate = new Date(appointment_date);
        const dayOfWeek = (appointmentDate.getUTCDay() + 6) % 7; // Convert to Monday=0 format
        const dayKeys = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"];
        const dayKey = dayKeys[dayOfWeek];
        const dayHours = location.opening_hours[dayKey];

        // Check if day is closed
        if (!dayHours || dayHours.closed) {
          return NextResponse.json(
            { error: "Wybrany dzień jest dniem wolnym od pracy w tej lokalizacji." },
            { status: 400 }
          );
        }

        // Convert time strings to minutes for comparison
        const timeToMinutes = (timeStr: string): number => {
          const [h, m] = timeStr.split(":").map(Number);
          return h * 60 + m;
        };

        const appointmentTimeMinutes = timeToMinutes(appointment_time);
        const openMinutes = timeToMinutes(dayHours.open);
        const closeMinutes = timeToMinutes(dayHours.close);
        const duration = duration_minutes || 30;
        const appointmentEndMinutes = appointmentTimeMinutes + duration;

        // Check if appointment time is within opening hours
        if (appointmentTimeMinutes < openMinutes || appointmentTimeMinutes >= closeMinutes) {
          return NextResponse.json(
            { error: `Godzina wizyty musi być w godzinach otwarcia gabinetu (${dayHours.open} - ${dayHours.close}).` },
            { status: 400 }
          );
        }

        // Check if there's enough time until closing
        if (appointmentEndMinutes > closeMinutes) {
          return NextResponse.json(
            { error: `Do końca pracy gabinetu (${dayHours.close}) brakuje czasu na zabieg (${duration} min).` },
            { status: 400 }
          );
        }
      }
    }

    const result = await queryOne<{ id: string; appointment_number: string }>(
      `INSERT INTO appointments (
        patient_id, dentist_id, appointment_date, appointment_time,
        duration_minutes, treatment_type, treatment_description, notes, price, created_by, location_id
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING id, appointment_number`,
      [
        patient_id,
        dentist_id,
        appointment_date,
        appointment_time,
        duration_minutes || 30,
        treatment_type || null,
        treatment_description || null,
        notes || null,
        price || null,
        user.id,
        location_id || null,
      ]
    );

    return NextResponse.json({ success: true, appointment: result });
  } catch (error: any) {
    console.error("Create appointment error:", error);
    if (error?.code === "23503") {
      const detail = error?.detail || "";
      if (detail.includes("appointments_patient_id_fkey")) {
        return NextResponse.json(
          { error: "Wybrany pacjent nie istnieje w bazie danych. Odśwież stronę i wybierz pacjenta ponownie." },
          { status: 400 }
        );
      }
      if (detail.includes("appointments_dentist_id_fkey")) {
        return NextResponse.json(
          { error: "Wybrany dentysta nie istnieje w bazie danych lub jest nieaktywny." },
          { status: 400 }
        );
      }
    }
    return NextResponse.json({ error: error.message || "Nie udało się utworzyć wizyty." }, { status: 500 });
  }
}


