import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { isValidUserId, isNewRoleBasedFormat, getRoleFromId } from "@/lib/user-id-utils";

/**
 * GitHub-style routing middleware for Code-Rice
 * Routes based on user ID in URL: code-rice.ltd/OWN-20251123-143025-000001
 */

const SESSION_COOKIE = "code_rice_session";

export function middleware(request: NextRequest) {
  const hostname = request.headers.get("host") || "";
  const url = request.nextUrl.clone();
  const pathname = url.pathname;

  // Skip middleware for API routes, static files, and auth routes
  if (
    pathname.startsWith("/api") ||
    pathname.startsWith("/_next") ||
    pathname.startsWith("/signin") ||
    pathname.startsWith("/signup") ||
    pathname.startsWith("/auth") ||
    pathname.match(/\.(svg|png|jpg|jpeg|gif|webp|ico|css|js)$/)
  ) {
    return NextResponse.next();
  }

  // Extract potential user ID from pathname
  const pathParts = pathname.split("/").filter(Boolean);
  const firstSegment = pathParts[0];

  // Check if first segment looks like a user ID
  if (firstSegment && isValidUserId(firstSegment) && isNewRoleBasedFormat(firstSegment)) {
    const userId = firstSegment;
    const role = getRoleFromId(userId) || "user";
    
    // Map role to route prefix
    const roleRouteMap: Record<string, string> = {
      developer: "dev",
      admin: "adm",
      manager: "mgr",
      owner: "own",
      user: "dev",
    };
    
    const routePrefix = roleRouteMap[role] || "dev";
    
    // Check session
    const sessionCookie = request.cookies.get(SESSION_COOKIE);
    
    if (sessionCookie) {
      // Rewrite to role-specific route
      const remainingPath = pathParts.slice(1).join("/") || "dashboard";
      url.pathname = `/${routePrefix}/${remainingPath}`;
      
      const response = NextResponse.rewrite(url);
      response.headers.set("x-user-id", userId);
      return response;
    } else {
      // Not logged in - redirect to sign in
      const loginUrl = new URL("/signin", request.url);
      loginUrl.searchParams.set("redirect", pathname);
      return NextResponse.redirect(loginUrl);
    }
  }

  // Handle legacy /admin routes - redirect to user ID-based routing
  if (pathname.startsWith("/admin")) {
    const sessionCookie = request.cookies.get(SESSION_COOKIE);
    if (!sessionCookie) {
      const loginUrl = new URL("/signin", request.url);
      loginUrl.searchParams.set("redirect", pathname);
      return NextResponse.redirect(loginUrl);
    }
    // These routes will redirect to user ID in the page component
    return NextResponse.next();
  }

  // Handle root path - redirect to user dashboard if logged in
  if (pathname === "/" || pathname === "") {
    const sessionCookie = request.cookies.get(SESSION_COOKIE);
    if (sessionCookie) {
      url.pathname = "/me";
      return NextResponse.redirect(url);
    }
    return NextResponse.next();
  }

  // Handle /me route - redirect to user's ID-based URL
  if (pathname === "/me") {
    const sessionCookie = request.cookies.get(SESSION_COOKIE);
    if (!sessionCookie) {
      return NextResponse.redirect(new URL("/signin", request.url));
    }
    return NextResponse.next();
  }

  // Subdomain routing (legacy)
  const subdomainMatch = hostname.match(/^([^.]+)\./);
  const subdomain = subdomainMatch ? subdomainMatch[1] : null;

  if (!subdomain || subdomain === "localhost" || subdomain === "127.0.0.1") {
    return NextResponse.next();
  }

  switch (subdomain) {
    case "admin":
      if (!pathname.startsWith("/admin")) {
        url.pathname = `/admin${pathname === "/" ? "" : pathname}`;
        return NextResponse.rewrite(url);
      }
      break;
    case "auth":
      if (!pathname.startsWith("/auth")) {
        url.pathname = `/auth${pathname === "/" ? "" : pathname}`;
        return NextResponse.rewrite(url);
      }
      break;
    case "main":
    default:
      if (pathname.startsWith("/admin") || pathname.startsWith("/auth")) {
        url.pathname = pathname.replace(/^\/(admin|auth)/, "") || "/";
        return NextResponse.rewrite(url);
      }
      break;
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/((?!api|_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico|css|js)).*)",
  ],
};
