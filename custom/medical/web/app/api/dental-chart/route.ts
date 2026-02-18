import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import {
  getDentalChartEntries,
  getDentalChartCustomEntries,
  saveDentalChartEntry,
  deleteDentalChartEntries,
} from "@/lib/mongodb-dental";

export async function GET(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || (user.role !== "admin" && user.role !== "superadmin")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const searchParams = request.nextUrl.searchParams;
    const patientId = searchParams.get("patientId");
    const visitId = searchParams.get("visitId");

    if (!patientId) {
      return NextResponse.json({ error: "Missing patientId" }, { status: 400 });
    }

    const entries = await getDentalChartEntries(patientId, visitId || null);
    const customEntries = await getDentalChartCustomEntries(patientId, visitId || null);

    return NextResponse.json({
      entries: entries.map((entry) => ({
        toothNumber: entry.toothNumber,
        surface: entry.surface,
        category: entry.category,
        conditionType: entry.conditionType,
        notes: entry.notes,
      })),
      customEntries: customEntries.map((entry) => ({
        toothNumber: entry.toothNumber,
        text: entry.customText,
      })),
    });
  } catch (error: any) {
    console.error("Error fetching dental chart:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || (user.role !== "admin" && user.role !== "superadmin")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { visitId, patientId, entry } = body;

    if (!visitId || !patientId || !entry) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
    }

    const id = await saveDentalChartEntry({
      visitId,
      patientId,
      toothNumber: entry.toothNumber,
      surface: entry.surface || null,
      category: entry.category,
      conditionType: entry.conditionType,
      notes: entry.notes || null,
      createdBy: user.id,
    });

    return NextResponse.json({ success: true, id });
  } catch (error: any) {
    console.error("Error saving dental chart entry:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function DELETE(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || (user.role !== "admin" && user.role !== "superadmin")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { visitId, patientId, toothNumber } = body;

    if (!visitId || !patientId || !toothNumber) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
    }

    await deleteDentalChartEntries(visitId, patientId, toothNumber);

    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error("Error deleting dental chart entries:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

