import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { saveDentalChartCustomEntry } from "@/lib/mongodb-dental";

export async function POST(request: NextRequest) {
  try {
    const user = await getCurrentUser();
    if (!user || (user.role !== "admin" && user.role !== "superadmin")) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const body = await request.json();
    const { visitId, patientId, toothNumber, customText } = body;

    if (!visitId || !patientId || !toothNumber || !customText) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 });
    }

    const id = await saveDentalChartCustomEntry({
      visitId,
      patientId,
      toothNumber,
      customText,
      createdBy: user.id,
    });

    return NextResponse.json({ success: true, id });
  } catch (error: any) {
    console.error("Error saving custom entry:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}


