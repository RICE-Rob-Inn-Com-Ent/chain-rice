import { NextResponse } from "next/server";
import { query } from "@/lib/db";

export async function GET() {
  try {
    // Debug: Log DATABASE_URL
    console.log("🔍 HEALTH CHECK - DATABASE_URL:", process.env.DATABASE_URL ? "SET" : "NOT SET");
    if (process.env.DATABASE_URL) {
      console.log("🔍 HEALTH CHECK - DATABASE_URL preview:", process.env.DATABASE_URL.replace(/:[^:@]+@/, ':****@').substring(0, 80));
    }
    
    // Test database connection
    await query("SELECT 1");
    
    return NextResponse.json({
      status: "ok",
      database: "connected",
      timestamp: new Date().toISOString(),
    });
  } catch (error: any) {
    return NextResponse.json(
      {
        status: "error",
        database: "disconnected",
        error: error?.message,
        code: error?.code,
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}

