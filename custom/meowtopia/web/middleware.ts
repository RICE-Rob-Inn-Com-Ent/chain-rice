import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { getToken } from "next-auth/jwt";
import { isValidUserId, isNewRoleBasedFormat, getRoleFromId } from "./lib/user-id-utils";
import { getRoleSessionCookieName, getSessionCookieMaxAge } from "./lib/cookie-utils";

/**
 * Simplified middleware for Meowtopia
 * Uses GraphQL for database queries (via API routes)
 * Only handles routing logic - no direct database access
 */

const ADMIN_ROLES = new Set(["ADMIN", "MANAGER", "OWNER", "SUPERADMIN"]);
const ROLE_ROUTE_MAP: Record<string, string> = {
  USER: "user",
  CUSTOMER: "user", // Legacy support
  VOLUNTEER: "vol",
  MANAGER: "mgr",
  ADMIN: "adm",
  OWNER: "own",
};

export async function middleware(request: NextRequest) {
  const url = request.nextUrl.clone();
  const pathname = url.pathname;
  const hostname = request.headers.get("host") || "";

  // Redirect legacy cart paths to new English path
  if (pathname === "/cart" || pathname === "/koszyk") {
    url.pathname = "/shopping-bag";
    return NextResponse.redirect(url);
  }

  // Check if request is from panel subdomain
  const isPanelSubdomain = hostname.startsWith("panel.") || hostname === "panel.meowtopia.ltd";
  
  // Get NextAuth token to check authentication and role
  const token = await getToken({ req: request, secret: process.env.NEXTAUTH_SECRET });
  const userRole = (token?.role as string)?.toUpperCase() || "USER";
  
  // Debug: Log token check
  if (pathname === "/" || pathname === "/signin") {
    try {
      console.log("Middleware token check:", { 
        pathname, 
        hostname, 
        hasToken: !!token, 
        role: token?.role, 
        username: (token as any)?.username,
        hasSecret: !!process.env.NEXTAUTH_SECRET 
      });
    } catch (error) {
      console.error("Middleware token error:", error);
    }
  }

  // Helper function to set role-based cookie on response
  const setRoleCookieOnResponse = (resp: NextResponse): NextResponse => {
    if (token && token.uid) {
      const roleCookieName = getRoleSessionCookieName(userRole);
      const nextAuthSessionToken = request.cookies.get("next-auth.session-token")?.value;
      
      // Check if role-based cookie exists, if not, set it from NextAuth session token
      const existingRoleCookie = request.cookies.get(roleCookieName);
      
      if (nextAuthSessionToken && !existingRoleCookie) {
        // Set role-based session cookie
        const cookieDomain = process.env.NODE_ENV === "production" ? ".meowtopia.ltd" : undefined;
        const maxAge = getSessionCookieMaxAge();
        
        resp.cookies.set(roleCookieName, nextAuthSessionToken, {
          httpOnly: true,
          secure: process.env.NODE_ENV === "production",
          sameSite: "lax",
          path: "/",
          domain: cookieDomain,
          maxAge: maxAge,
        });
        
        console.log(`[Middleware] Set role-based cookie: ${roleCookieName} for role: ${userRole}`);
      }
    }
    return resp;
  };

  // If accessing panel subdomain, handle user ID-based routing
  if (isPanelSubdomain) {
    // Skip rewrite for API, static files, uploads, and auth routes - let them through
    if (pathname.startsWith("/api") || pathname.startsWith("/_next") || pathname.startsWith("/signin") || pathname.startsWith("/signup") || pathname.startsWith("/uploads")) {
      return setRoleCookieOnResponse(NextResponse.next());
    }
    
    const token = await getToken({ req: request, secret: process.env.NEXTAUTH_SECRET });
    
    // Check if this looks like a username-based route (e.g., /adm_own/dashboard)
    const pathParts = pathname.split("/").filter(Boolean);
    const firstSegment = pathParts[0];
    const looksLikeUsernameRoute = firstSegment && 
      !firstSegment.startsWith("api") && 
      !firstSegment.startsWith("_next") &&
      !firstSegment.startsWith("signin") &&
      !firstSegment.startsWith("signup") &&
      !firstSegment.startsWith("panel");
    
    // If no token or not admin, check if we should allow through
    // Allow username routes through even without token (cookies may still be setting after login)
    // Layout will handle authentication check
    if (!token || !ADMIN_ROLES.has((token.role as string) ?? "USER")) {
      // Don't redirect if already on signin/signup - let it through to avoid loops
      if (pathname.startsWith("/signin") || pathname.startsWith("/signup")) {
        return NextResponse.next();
      }
      
      // If this looks like a username route and we don't have token, allow through
      // Cookies might still be setting after redirect from signin
      // Layout will handle showing error/redirect if needed
      if (looksLikeUsernameRoute) {
        console.log(`[Middleware] Username route without token, allowing through for layout to handle: ${pathname}`);
        // Continue to routing logic below - will rewrite and let layout handle auth
      } else {
        // Not a username route and no token - redirect to signin
        const signinUrl = new URL("/signin", request.url);
        signinUrl.hostname = hostname.replace("panel.", "");
        signinUrl.port = "";
        return NextResponse.redirect(signinUrl);
      }
    }
    
    // Check if pathname is a username (not a user ID)
    // pathParts and firstSegment already defined above
    
    // Check if it's a user ID (old format) or username (new format)
    const isUserId = firstSegment && isValidUserId(firstSegment) && isNewRoleBasedFormat(firstSegment);
    
    if (isUserId) {
      // User ID-based routing on panel subdomain - rewrite to role-based route
      const role = getRoleFromId(firstSegment) || "USER";
      const routePrefix = ROLE_ROUTE_MAP[role.toUpperCase()] || "user";
      const remainingPath = pathParts.slice(1).join("/") || "dashboard";
      url.pathname = `/${routePrefix}/${remainingPath}`;
      const response = NextResponse.rewrite(url);
      response.headers.set("x-user-id", firstSegment);
      return setRoleCookieOnResponse(response);
    } else if (firstSegment && !pathname.startsWith("/panel") && !pathname.startsWith("/api") && !pathname.startsWith("/_next") && !pathname.startsWith("/uploads")) {
      // Username-based routing on panel subdomain
      // Path format: /{username}/{route} (e.g., /adm_own/dashboard)
      // Rewrite to /panel/[username]/{route} internally but keep original URL
      const remainingPath = pathParts.slice(1).join("/") || "dashboard";
      // Rewrite to /panel/[username]/route where [username] is dynamic segment
      // Next.js will match this to app/(panel)/panel/[username]/dashboard/page.tsx
      url.pathname = `/panel/${firstSegment}/${remainingPath}`;
      const response = NextResponse.rewrite(url);
      response.headers.set("x-username", firstSegment);
      // Don't redirect - keep the original URL with username visible
      return setRoleCookieOnResponse(response);
    } else if (pathname === "/" || pathname === "") {
      // Root path on panel subdomain - redirect to user's username/dashboard
      const username = (token as any)?.username || null;
      if (username && username.trim()) {
        const redirectUrl = new URL(`/${username}/dashboard`, request.url);
        console.log(`[Middleware] Redirecting root to username dashboard: ${username}`);
        return NextResponse.redirect(redirectUrl);
      }
      // If no username but user is authenticated, don't redirect aggressively
      // Let the panel page handle it - username might still be loading in cookies
      console.log(`[Middleware] User authenticated but username not yet available, allowing /panel`);
      url.pathname = "/panel";
      return setRoleCookieOnResponse(NextResponse.rewrite(url));
    } else if (pathname.startsWith("/panel")) {
      // Panel routes on panel subdomain - just rewrite (authentication already checked above)
      return setRoleCookieOnResponse(NextResponse.rewrite(url));
    } else {
      // Other paths - rewrite to /panel route (authentication already checked above)
      url.pathname = `/panel${pathname}`;
      return NextResponse.rewrite(url);
    }
  }

  // Skip middleware for API routes, static files, and uploads
  if (
    pathname.startsWith("/api") ||
    pathname.startsWith("/_next") ||
    pathname.startsWith("/uploads") ||
    pathname.match(/\.(svg|png|jpg|jpeg|gif|webp|ico|css|js)$/)
  ) {
    return setRoleCookieOnResponse(NextResponse.next());
  }
  
  // Handle signin/signup - redirect if already logged in (but only on main domain)
  if ((pathname.startsWith("/signin") || pathname.startsWith("/signup")) && !isPanelSubdomain) {
    try {
      const token = await getToken({ req: request, secret: process.env.NEXTAUTH_SECRET });
      if (token) {
        const role = (token.role as string) ?? "USER";
        const username = (token as any)?.username || null;
        const adminRoles = ["ADMIN", "MANAGER", "OWNER", "SUPERADMIN"];
        
        if (adminRoles.includes(role)) {
          // Redirect to panel subdomain
          const panelUrl = new URL(request.url);
          panelUrl.hostname = `panel.${hostname.split(".").slice(-2).join(".")}`;
          panelUrl.port = "";
          // Only use username if it's available and not empty
          panelUrl.pathname = (username && username.trim()) ? `/${username}` : "/";
          console.log(`[Middleware] Redirecting admin from signin to panel: ${panelUrl.pathname}`);
          return NextResponse.redirect(panelUrl);
        } else if (username && username.trim()) {
          return NextResponse.redirect(new URL(`/${username}/dashboard`, request.url));
        } else {
          return NextResponse.redirect(new URL("/", request.url));
        }
      }
    } catch (error) {
      // If token decoding fails, let user through to signin page
      console.error("Token decode error:", error);
    }
    return setRoleCookieOnResponse(NextResponse.next());
  }
  
  // Skip signin/signup on panel subdomain - let them through
  if ((pathname.startsWith("/signin") || pathname.startsWith("/signup")) && isPanelSubdomain) {
    return setRoleCookieOnResponse(NextResponse.next());
  }

  const pathParts = pathname.split("/").filter(Boolean);
  const firstSegment = pathParts[0];

  // User ID-based routing: /USR-20251123-143025-000001 -> /user/dashboard
  if (firstSegment && isValidUserId(firstSegment) && isNewRoleBasedFormat(firstSegment)) {
    const role = getRoleFromId(firstSegment) || "CUSTOMER";
    const routePrefix = ROLE_ROUTE_MAP[role.toUpperCase()] || "cus";
    const token = await getToken({ req: request, secret: process.env.NEXTAUTH_SECRET });
    
    if (token) {
      const remainingPath = pathParts.slice(1).join("/") || "dashboard";
      url.pathname = `/${routePrefix}/${remainingPath}`;
      const response = NextResponse.rewrite(url);
      response.headers.set("x-user-id", firstSegment);
      return setRoleCookieOnResponse(response);
    }
    
    return NextResponse.redirect(new URL(`/signin?callbackUrl=${pathname}`, request.url));
  }

  // Panel routes - require authentication and admin role
  if (pathname.startsWith("/panel")) {
    const panelToken = await getToken({ req: request, secret: process.env.NEXTAUTH_SECRET });
    if (!panelToken || !ADMIN_ROLES.has((panelToken.role as string) ?? "USER")) {
      return NextResponse.redirect(new URL("/signin?callbackUrl=" + pathname, request.url));
    }
    return setRoleCookieOnResponse(NextResponse.next());
  }

  // Admin routes - require authentication
  if (pathname.startsWith("/admin")) {
    const adminToken = await getToken({ req: request, secret: process.env.NEXTAUTH_SECRET });
    if (!adminToken || !ADMIN_ROLES.has((adminToken.role as string) ?? "USER")) {
      return NextResponse.redirect(new URL("/", request.url));
    }
    return setRoleCookieOnResponse(NextResponse.next());
  }

  // Root path - redirect based on role
  if (pathname === "/" || pathname === "") {
    try {
      const token = await getToken({ req: request, secret: process.env.NEXTAUTH_SECRET });
      if (token) {
        const role = (token.role as string) ?? "USER";
        const username = (token as any)?.username || null;
        const adminRoles = ["ADMIN", "MANAGER", "OWNER", "SUPERADMIN"];
        
        console.log("Root path - token found:", { role, username, isPanelSubdomain });
        
        if (adminRoles.includes(role)) {
          // Redirect to panel subdomain with username if not already there
          if (!isPanelSubdomain) {
            const baseDomain = hostname.split(".").slice(-2).join(".");
            // Only use username if it's available and not empty
            const usernamePath = (username && username.trim()) ? `/${username}` : "/";
            const panelUrl = new URL(`http://panel.${baseDomain}${usernamePath}`);
            console.log(`[Middleware] Root path - redirecting admin to panel: ${panelUrl.toString()}`);
            return NextResponse.redirect(panelUrl);
          }
          // Already on panel subdomain - redirect to username if available
          if (username && username.trim()) {
            console.log(`[Middleware] Already on panel, redirecting to username: ${username}`);
            return NextResponse.redirect(new URL(`/${username}`, request.url));
          }
          // No username yet - let /panel handle it
          console.log(`[Middleware] On panel but username not available, rewriting to /panel`);
          return NextResponse.rewrite(new URL("/panel", request.url));
        }
        // Non-admin users - don't redirect, let them stay on home
        return setRoleCookieOnResponse(NextResponse.next());
      }
    } catch (error) {
      console.error("Error checking token on root path:", error);
    }
    return setRoleCookieOnResponse(NextResponse.next());
  }

  // /me route - require authentication
  if (pathname === "/me") {
    const meToken = await getToken({ req: request, secret: process.env.NEXTAUTH_SECRET });
    return meToken ? setRoleCookieOnResponse(NextResponse.next()) : NextResponse.redirect(new URL("/signin", request.url));
  }

  return setRoleCookieOnResponse(NextResponse.next());
}

export const config = {
  matcher: ["/((?!_next/static|_next/image|favicon.ico|api).*)"],
};
