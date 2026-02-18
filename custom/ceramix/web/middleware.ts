import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { isValidUsername } from './lib/username-utils';

// Standardized domain configuration from environment variables
const PROJECT_DOMAIN = process.env.PROJECT_DOMAIN || 'ceramix.ltd';
const PROJECT_PANEL_DOMAIN = process.env.PROJECT_PANEL_DOMAIN || 'panel.ceramix.ltd';

/**
 * Simplified middleware for Ceramix
 * Uses GraphQL for database queries (via API routes)
 * Only handles routing logic - no direct database access
 */

const ROLE_ROUTE_MAP: Record<string, string> = {
  patient: 'pat',
  doctor: 'doc',
  admin: 'adm',
  owner: 'own',
  user: 'pat',
};


// Helper function to generate CSRF token (using Web Crypto API for Edge Runtime)
async function generateCSRFToken(): Promise<string> {
  const array = new Uint8Array(32);
  crypto.getRandomValues(array);
  return Array.from(array, byte => byte.toString(16).padStart(2, '0')).join('');
}

// Helper function to add CSRF token to any response
async function addCSRFTokenIfNeeded(request: NextRequest, response: NextResponse): Promise<NextResponse> {
  const csrfToken = request.cookies.get('ceramix_csrf');
  if (!csrfToken) {
    const newCsrfToken = await generateCSRFToken();
    const projectDomain = process.env.PROJECT_DOMAIN || 'ceramix.ltd';
    const cookieDomain = projectDomain.includes('localhost') 
      ? undefined 
      : `.${projectDomain}`; // Use .ceramix.ltd for subdomain sharing
    
    response.cookies.set('ceramix_csrf', newCsrfToken, {
      httpOnly: false, // Must be readable by JavaScript
      secure: process.env.NODE_ENV === "production",
      sameSite: "lax",
      path: "/",
      domain: cookieDomain, // Set domain to share cookie between subdomains
      maxAge: 60 * 60 * 24, // 24 hours
    });
  }
  return response;
}

export async function middleware(request: NextRequest) {
  const url = request.nextUrl.clone();
  const pathname = url.pathname;
  let hostname = request.headers.get('host') || '';

  // Debug: log all requests
  console.log(`[MIDDLEWARE] Request: ${hostname}${pathname}`);

  // Remove port from hostname for standard ports (80 for HTTP, 443 for HTTPS)
  // This ensures URLs don't contain ports when accessed through Traefik
  if (hostname.includes(':')) {
    const [domain, port] = hostname.split(':');
    // Only keep non-standard ports for internal use
    // For standard ports (80, 443), remove them from hostname
    if (port === '80' || port === '443') {
      hostname = domain;
    }
  }

  // Check for ANY role-based session cookie (owner_session, doctor_session, etc.)
  // User with ANY session cookie MUST be on panel subdomain (ceramix.ltd is forbidden)
  const roleSessionCookies = [
    'owner_session',
    'doctor_session', 
    'admin_session',
    'patient_session',
    'ceramix_session', // legacy support
  ];
  
  // Debug: check which cookies exist
  const foundCookies: string[] = [];
  roleSessionCookies.forEach(cookieName => {
    const cookie = request.cookies.get(cookieName);
    if (cookie?.value) {
      foundCookies.push(cookieName);
    }
  });
  
  const hasSession = foundCookies.length > 0;
  
  // Debug logging
  if (hasSession) {
    console.log(`[MIDDLEWARE] Found session cookies: ${foundCookies.join(', ')}, hostname: ${hostname}, pathname: ${pathname}`);
  }

  // CRITICAL: If user has ANY session cookie, they MUST be on panel subdomain
  // ceramix.ltd is FORBIDDEN for logged-in users (except logout)
  // This is a hard requirement - no exceptions for auth pages
  if (hostname === PROJECT_DOMAIN || hostname.startsWith(`${PROJECT_DOMAIN}:`)) {
    if (hasSession) {
      const isStaticFile = pathname.match(/\.(svg|png|jpg|jpeg|gif|webp|ico|css|js)$/);
      
      // Only allow static files on base domain (images, CSS, JS)
      if (!isStaticFile) {
        // FORCE redirect to panel - no exceptions
        const panelUrl = new URL(url);
        panelUrl.host = PROJECT_PANEL_DOMAIN;
        panelUrl.port = '';
        
        // If on root or auth pages, redirect to /me (which redirects to dashboard)
        if (pathname === '/' || pathname === '' || 
            pathname.startsWith('/sign-in') || 
            pathname.startsWith('/sign-up') || 
            pathname.startsWith('/login') || 
            pathname.startsWith('/register')) {
          panelUrl.pathname = '/me';
        }
        
        console.log(`[MIDDLEWARE] Redirecting logged-in user from ${hostname}${pathname} to ${panelUrl.toString()}`);
        const redirectResponse = NextResponse.redirect(panelUrl);
        return await addCSRFTokenIfNeeded(request, redirectResponse);
      }
    }
  }
  
  // Redirect from panel.{projekt}.ltd to {projekt}.ltd for unauthenticated users on public pages (standardized)
  if (hostname === PROJECT_PANEL_DOMAIN || hostname.startsWith(`${PROJECT_PANEL_DOMAIN}:`)) {
    const isPublicPage = pathname.startsWith('/sign-in') || 
                        pathname.startsWith('/sign-up') || 
                        pathname.startsWith('/login') || 
                        pathname.startsWith('/register') ||
                        pathname === '/';
    
    // If user is NOT logged in and on a public page, redirect to base domain (without port)
    if (!hasSession && isPublicPage) {
      const publicUrl = new URL(url);
      publicUrl.host = PROJECT_DOMAIN;
      // Remove port from URL
      publicUrl.port = '';
      const redirectResponse = NextResponse.redirect(publicUrl);
      return await addCSRFTokenIfNeeded(request, redirectResponse);
    }
  }
  
  // If hostname contains a non-standard port (e.g., :3002), redirect to the same URL without port
  // This ensures all requests go through Traefik (ports 80/443)
  if (hostname.includes(':') && !hostname.match(/:80$|:443$/)) {
    const cleanUrl = new URL(url);
    const [domain] = hostname.split(':');
    cleanUrl.host = domain;
    return NextResponse.redirect(cleanUrl);
  }

  // Skip middleware for API routes, static files, and auth routes
  if (
    pathname.startsWith('/api') ||
    pathname.startsWith('/_next') ||
    pathname.startsWith('/sign-in') ||
    pathname.startsWith('/sign-up') ||
    pathname.startsWith('/login') ||
    pathname.startsWith('/register') ||
    pathname.match(/\.(svg|png|jpg|jpeg|gif|webp|ico|css|js)$/)
  ) {
    const response = NextResponse.next();
    return await addCSRFTokenIfNeeded(request, response);
  }

  const pathParts = pathname.split('/').filter(Boolean);
  const firstSegment = pathParts[0];

  // CRITICAL: Check legacy role prefix routes FIRST - before any other routing logic
  // This prevents Next.js from trying to render (roles)/ layouts
  // IMPORTANT: Only block EXACT matches (own, pat, doc, adm) - not usernames like "own1", "pat123", etc.
  const legacyRolePrefixes = ['own', 'pat', 'doc', 'adm'];
  const isExactLegacyRoute = firstSegment && legacyRolePrefixes.includes(firstSegment.toLowerCase()) && firstSegment.length <= 3;
  
  if (isExactLegacyRoute) {
    // Force immediate redirect to prevent Next.js from rendering (roles)/ layouts
    const redirectUrl = hasSession ? '/me' : `/sign-in?redirect=${encodeURIComponent(pathname)}`;
    console.log(`[MIDDLEWARE] BLOCKING legacy route ${pathname} - redirecting to ${redirectUrl} (hasSession: ${hasSession})`);
    const redirectResponse = NextResponse.redirect(new URL(redirectUrl, request.url));
    // Set cache headers to prevent caching this redirect
    redirectResponse.headers.set('Cache-Control', 'no-store, must-revalidate');
    redirectResponse.headers.set('Pragma', 'no-cache');
    redirectResponse.headers.set('Expires', '0');
    redirectResponse.headers.set('X-Redirect-Reason', 'legacy-role-prefix');
    return await addCSRFTokenIfNeeded(request, redirectResponse);
  }
  
  // CRITICAL: Block routes that start with legacy prefixes but are longer (e.g., "own1", "pat123")
  // These should be treated as usernames, not legacy routes
  // Next.js might try to match them to (roles)/own/* routes, so we need to explicitly handle them
  // by ensuring they're processed as username routes with a special header
  // This header can be checked in (roles)/own/* pages to prevent incorrect matching
  if (firstSegment && firstSegment.length > 3) {
    const startsWithLegacyPrefix = legacyRolePrefixes.some(prefix => 
      firstSegment.toLowerCase().startsWith(prefix.toLowerCase())
    );
    
    if (startsWithLegacyPrefix && isValidUsername(firstSegment)) {
      // This is a username that starts with a legacy prefix (e.g., "own1", "pat123")
      // Add a header to mark this as a username route, not a legacy role route
      // This allows (roles)/own/* pages to check and reject incorrect matches
      if (hasSession) {
        console.log(`[MIDDLEWARE] Marking username starting with legacy prefix as username route: ${firstSegment}`);
        const response = NextResponse.next();
        response.headers.set('X-Route-Type', 'username');
        response.headers.set('X-Username', firstSegment);
        response.headers.set('X-Is-Username-Route', 'true');
        return await addCSRFTokenIfNeeded(request, response);
      }
      
      // Not logged in - redirect to sign-in with redirect parameter
      const redirectResponse = NextResponse.redirect(new URL(`/sign-in?redirect=${pathname}`, request.url));
      return await addCSRFTokenIfNeeded(request, redirectResponse);
    }
  }

  // Only reserved route is /me - all others are username-based or legacy role prefixes
  const RESERVED_ROUTES = ['me', 'sign-in', 'sign-up', 'login', 'register', 'api', '_next'];
  
  // Block user IDs (format: PREFIX-YYYYMMDD-HHMMSS-XXXXXX or PREFIX-YYYYMMDD-XXXXXX)
  // These should not be treated as usernames - redirect to /me which will redirect to username
  const isUserIdFormat = firstSegment && /^(PAT|DOC|ADM|OWN|SUP|USR)-\d{8}(-\d{6})?(-\d{6})?$/.test(firstSegment);
  
  // If it's a user ID format, redirect to /me (which will redirect to user's username)
  if (isUserIdFormat) {
    const redirectResponse = NextResponse.redirect(new URL('/me', request.url));
    return await addCSRFTokenIfNeeded(request, redirectResponse);
  }
  
  // Username-based routing: /username, /username/dashboard, /username/users, etc.
  // Similar to GitHub: /username instead of /user-id or /role-prefix
  if (firstSegment && !RESERVED_ROUTES.includes(firstSegment.toLowerCase()) && isValidUsername(firstSegment)) {
    if (hasSession) {
      // Allow username-based routes - let the route handler check permissions
      const response = NextResponse.next();
      return await addCSRFTokenIfNeeded(request, response);
    }
    
    // Not logged in - redirect to sign-in with redirect parameter
    const redirectResponse = NextResponse.redirect(new URL(`/sign-in?redirect=${pathname}`, request.url));
    return await addCSRFTokenIfNeeded(request, redirectResponse);
  }

  // Legacy routes - redirect to /me
  if (pathname.startsWith('/ceramix') || pathname.startsWith('/admin')) {
    const redirectResponse = hasSession 
      ? NextResponse.redirect(new URL('/me', request.url))
      : NextResponse.redirect(new URL(`/sign-in?redirect=${pathname}`, request.url));
    return await addCSRFTokenIfNeeded(request, redirectResponse);
  }

  // Root path on panel domain - if logged in, redirect to /me
  if ((pathname === '/' || pathname === '') && (hostname === PROJECT_PANEL_DOMAIN || hostname.startsWith(`${PROJECT_PANEL_DOMAIN}:`))) {
    const response = hasSession 
      ? NextResponse.redirect(new URL('/me', request.url))
      : NextResponse.next();
    return await addCSRFTokenIfNeeded(request, response);
  }
  
  // Root path on base domain without session - show public page (already handled above if has session)
  // This is a fallback for cases where root path wasn't caught above
  if ((pathname === '/' || pathname === '') && (hostname === PROJECT_DOMAIN || hostname.startsWith(`${PROJECT_DOMAIN}:`))) {
    const response = NextResponse.next();
    return await addCSRFTokenIfNeeded(request, response);
  }

  // /me route - require authentication
  if (pathname === '/me') {
    const response = hasSession 
      ? NextResponse.next()
      : NextResponse.redirect(new URL('/sign-in', request.url));
    return await addCSRFTokenIfNeeded(request, response);
  }

  const response = NextResponse.next();
  return await addCSRFTokenIfNeeded(request, response);
}

// Match all routes except static files and API routes
export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     * - public files (public folder)
     */
    '/((?!api|_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico|css|js)).*)',
  ],
};
