import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { deleteSession } from "@/lib/auth";
import { deleteAllSessionCookies } from "@/lib/cookie-utils";
import { redirect } from "next/navigation";

export async function POST() {
  try {
    const cookieStore = await cookies();
    
    // Get any role session cookie (owner_session, doctor_session, etc.)
    const allRoleCookies = ['owner_session', 'doctor_session', 'admin_session', 'patient_session', 'ceramix_session'];
    
    for (const cookieName of allRoleCookies) {
      const sessionToken = cookieStore.get(cookieName)?.value;
      if (sessionToken) {
        await deleteSession(sessionToken);
        break; // Only one session should exist
      }
    }
    
    // Delete all session cookies (including legacy)
    await deleteAllSessionCookies();

    redirect("/");
  } catch (error) {
    console.error("Logout error:", error);
    redirect("/");
  }
}


