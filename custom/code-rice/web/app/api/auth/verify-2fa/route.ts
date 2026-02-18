import { NextResponse } from "next/server";

export async function POST() {
  return NextResponse.json(
    { error: "Weryfikacja dwuetapowa nie jest jeszcze dostępna w Code Rice" },
    { status: 501 },
  );
}


