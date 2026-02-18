import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { getRoleFromId, isValidUserId, isNewRoleBasedFormat } from './lib/user-id-utils';

/**
 * GitHub-style routing middleware for Code-Rice
 * Routes based on user ID in URL: code-rice.ltd/DEV-20251123-143025-000001
 * 
 * URL Patterns:
 * - /[USER_ID] -> User's dashboard based on role prefix
 * - /[USER_ID]/settings -> User settings
 * - /api/* -> API routes (no changes)
 * - /signin, /signup -> Auth routes (no changes)
 */

export function middleware(request: NextRequest) {
  const hostname = request.headers.get('host') || '';
  const url = request.nextUrl.clone();
  const pathname = url.pathname;

  // Skip middleware for API routes, static files, and auth routes
  if (
    pathname.startsWith('/api') ||
    pathname.startsWith('/_next') ||
    pathname.startsWith('/signin') ||
    pathname.startsWith('/signup') ||
    pathname.startsWith('/auth') ||
    pathname.match(/\.(svg|png|jpg|jpeg|gif|webp|ico|css|js)$/)
  ) {
    return NextResponse.next();
  }

  // Extract potential user ID from pathname
  // Pattern: /DEV-20251123-143025-000001 or /OWN-20251123-143025-000001
  const pathParts = pathname.split('/').filter(Boolean);
  const firstSegment = pathParts[0];

  // Check if first segment looks like a user ID
  if (firstSegment && isValidUserId(firstSegment) && isNewRoleBasedFormat(firstSegment)) {
    const userId = firstSegment;
    const role = getRoleFromId(userId) || 'user';
    
    // Map role to route prefix
    const roleRouteMap: Record<string, string> = {
      developer: 'dev',
      admin: 'adm',
      manager: 'mgr',
      owner: 'own',
      user: 'dev', // default
    };
    
    const routePrefix = roleRouteMap[role] || 'dev';
    
    // If user is accessing their own ID, route to their dashboard
    // Check session to verify it's the logged-in user
    const sessionCookie = request.cookies.get('code_rice_session');
    
    if (sessionCookie) {
      // Rewrite to role-specific route
      // /DEV-20251123-143025-000001 -> /dev/dashboard
      // /DEV-20251123-143025-000001/settings -> /dev/settings
      const remainingPath = pathParts.slice(1).join('/') || 'dashboard';
      url.pathname = `/${routePrefix}/${remainingPath}`;
      
      // Add user ID as header for the page to use
      const response = NextResponse.rewrite(url);
      response.headers.set('x-user-id', userId);
      response.headers.set('x-requested-user-id', userId);
      return response;
    } else {
      // Not logged in - redirect to sign in
      const loginUrl = new URL('/signin', request.url);
      loginUrl.searchParams.set('redirect', pathname);
      return NextResponse.redirect(loginUrl);
    }
  }

  // Handle admin console routes - require auth but do not reroute
  if (pathname.startsWith('/admin')) {
    const sessionCookie = request.cookies.get('code_rice_session');
    if (!sessionCookie) {
      const loginUrl = new URL('/signin', request.url);
      loginUrl.searchParams.set('redirect', pathname);
      return NextResponse.redirect(loginUrl);
    }
    return NextResponse.next();
  }

  // Handle root path - redirect to user dashboard if logged in
  if (pathname === '/' || pathname === '') {
    const sessionCookie = request.cookies.get('code_rice_session');
    if (sessionCookie) {
      // We can't get user ID from session in middleware easily
      // So we'll redirect to a special route that will handle it
      url.pathname = '/me';
      return NextResponse.redirect(url);
    }
    // Not logged in - show landing page
    return NextResponse.next();
  }

  // Handle /me route - redirect to user's ID-based URL
  if (pathname === '/me') {
    const sessionCookie = request.cookies.get('code_rice_session');
    if (!sessionCookie) {
      return NextResponse.redirect(new URL('/signin', request.url));
    }
    // The /me route handler will fetch user ID and redirect
    return NextResponse.next();
  }

  return NextResponse.next();
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

