import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { cookies } from "next/headers";
import { getCurrentUser } from "@/lib/auth";

/**
 * GET /api/auth/me
 * Returns the current authenticated user
 */
export async function GET(request: NextRequest) {
  try {
    // Debug: log all cookies from request headers AND from cookies() function
    const cookieHeader = request.headers.get('cookie') || '';
    console.log(`[API /me] Cookie header: ${cookieHeader.substring(0, 200)}...`);
    
    const cookieStore = await cookies();
    const allCookies = ['owner_session', 'doctor_session', 'admin_session', 'patient_session', 'ceramix_session'];
    const foundCookies: Record<string, string> = {};
    const allCookiesFromStore: Record<string, any> = {};
    
    allCookies.forEach(name => {
      const cookie = cookieStore.get(name);
      allCookiesFromStore[name] = {
        exists: !!cookie,
        hasValue: !!cookie?.value,
        valueLength: cookie?.value?.length || 0,
        valuePreview: cookie?.value ? cookie.value.substring(0, 20) + '...' : null,
      };
      if (cookie?.value) {
        foundCookies[name] = cookie.value.substring(0, 20) + '...';
      }
    });
    
    console.log(`[API /me] Cookies from store:`, JSON.stringify(allCookiesFromStore, null, 2));
    console.log(`[API /me] Found session cookies:`, foundCookies);
    
    const user = await getCurrentUser();

    if (!user) {
      console.log(`[API /me] No user found - returning 401`);
      return NextResponse.json({ 
        error: "Not authenticated",
        debug: {
          cookiesInHeader: cookieHeader.includes('_session'),
          cookiesFromStore: allCookiesFromStore,
        }
      }, { status: 401 });
    }

    console.log(`[API /me] User found: ${user.email}, role: ${user.role}`);
    return NextResponse.json({ user: { id: user.id, email: user.email, role: user.role, display_name: user.display_name } });
  } catch (error) {
    console.error("[API /me] Error fetching current user:", error);
    return NextResponse.json({ error: "Internal server error" }, { status: 500 });
  }
}
