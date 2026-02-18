import { NextRequest, NextResponse } from "next/server";
import { query } from "@/lib/db";

export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const dentistId = params.id;
    const { searchParams } = new URL(request.url);
    const start = searchParams.get("start");
    const end = searchParams.get("end");

    if (!start || !end) {
      return NextResponse.json({ error: "Start and end dates are required" }, { status: 400 });
    }

    const appointments = await query<{
      id: string;
      appointment_date: Date;
      appointment_time: string;
      duration_minutes: number;
      patient_first_name: string;
      patient_last_name: string;
      treatment_type: string;
      status: string;
    }>(
      `SELECT 
        a.id, a.appointment_date, a.appointment_time, a.duration_minutes,
        a.treatment_type, a.status,
        p.first_name as patient_first_name, p.last_name as patient_last_name
       FROM appointments a
       JOIN users p ON a.patient_id::text = p.id
       WHERE a.dentist_id = $1 
         AND a.appointment_date >= $2 
         AND a.appointment_date <= $3
       ORDER BY a.appointment_date, a.appointment_time`,
      [dentistId, start, end]
    );

    return NextResponse.json({ appointments });
  } catch (error) {
    console.error("Error fetching appointments:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}


