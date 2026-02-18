import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { createDentalVisit, getDentalVisits } from "@/lib/mongodb-dental";

export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || (user.role !== "admin" && user.role !== "superadmin")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { patientId, visitDate, visitTime, dentistId, notes } = body;

    if (!patientId || !visitDate) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
    }

    const visitId = await createDentalVisit({
      patientId,
      visitDate,
      visitTime: visitTime || null,
      dentistId: dentistId || null,
      notes: notes || null,
      createdBy: user.id,
    });

    return NextResponse.json({ visitId });
  } catch (error: any) {
    console.error("Error creating dental visit:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function GET(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || (user.role !== "admin" && user.role !== "superadmin")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const searchParams = request.nextUrl.searchParams;
    const patientId = searchParams.get("patientId");

    if (!patientId) {
      return NextResponse.json({ error: "Missing patientId" }, { status: 400 });
    }

    const visits = await getDentalVisits(patientId, 10);

    return NextResponse.json({
      visits: visits.map((visit) => ({
        id: visit.visitId,
        visit_date: visit.visitDate,
        visit_time: visit.visitTime,
        dentist_id: visit.dentistId,
        notes: visit.notes,
        created_at: visit.createdAt,
      })),
    });
  } catch (error: any) {
    console.error("Error fetching dental visits:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}


