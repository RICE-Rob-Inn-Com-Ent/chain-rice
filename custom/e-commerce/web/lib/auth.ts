import { NextAuthOptions } from "next-auth";
import GoogleProvider from "next-auth/providers/google";
import FacebookProvider from "next-auth/providers/facebook";
import CredentialsProvider from "next-auth/providers/credentials";
// PrismaAdapter - optional, commented out since adapter is not used with JWT strategy
// @ts-ignore - Package may not be installed
// import { PrismaAdapter } from "@next-auth/prisma-adapter";
import { prisma } from "./prisma";
import bcrypt from "bcryptjs";

// Ensure DATABASE_URL is loaded
if (typeof window === "undefined" && !process.env.DATABASE_URL) {
  try {
    // Try to load from .env.local if not already loaded
    const fs = require("fs");
    const path = require("path");
    const envPath = path.join(process.cwd(), ".env.local");
    if (fs.existsSync(envPath)) {
      const envContent = fs.readFileSync(envPath, "utf8");
      const dbUrlMatch = envContent.match(/^DATABASE_URL=(.+)$/m);
      if (dbUrlMatch) {
        process.env.DATABASE_URL = dbUrlMatch[1].trim().replace(/^["']|["']$/g, "");
      }
    }
  } catch (e) {
    console.warn("[NextAuth] Could not load DATABASE_URL from .env.local:", e);
  }
}

export const authOptions: NextAuthOptions & { trustHost?: boolean } = {
  // Trust the host header from reverse proxy (Traefik)
  // This allows NextAuth to work with multiple domains (meowtopia.ltd, panel.meowtopia.ltd)
  trustHost: true,
  // Note: PrismaAdapter is not needed when using JWT strategy
  // adapter: PrismaAdapter(prisma), // Disabled to avoid database queries on every request
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    }),
    FacebookProvider({
      clientId: process.env.FACEBOOK_CLIENT_ID!,
      clientSecret: process.env.FACEBOOK_CLIENT_SECRET!,
    }),
    CredentialsProvider({
      name: "Email i hasło",
      credentials: {
        email: { label: "Email", type: "email", placeholder: "jan@meowtopia.pl" },
        password: { label: "Hasło", type: "password" },
      },
      async authorize(credentials) {
        if (!credentials?.email || !credentials?.password) {
          throw new Error("Podaj adres email i hasło");
        }

        try {
          const user = await prisma.user.findUnique({
            where: { email: credentials.email.toLowerCase() },
          });

          if (!user || !user.passwordHash) {
            throw new Error("Nie znaleziono użytkownika lub konto korzysta z logowania społecznościowego");
          }

          const isValid = await bcrypt.compare(credentials.password, user.passwordHash);
          if (!isValid) {
            throw new Error("Nieprawidłowe dane logowania");
          }

          const fallbackName = `${user.firstName ?? ""} ${user.lastName ?? ""}`.trim() || user.email;

          return {
            id: user.id,
            email: user.email,
            name: user.name ?? fallbackName,
            image: user.image,
            role: user.role,
            username: user.username,
          } as any;
        } catch (error: any) {
          console.error("[NextAuth] Error in authorize:", error);
          // If it's a database connection error, provide a helpful message
          if (error?.code === 'P1001' || error?.message?.includes('Can\'t reach database server')) {
            throw new Error("Błąd połączenia z bazą danych. Sprawdź, czy serwer bazy danych jest uruchomiony.");
          }
          // Re-throw other errors
          throw error;
        }
      },
    }),
  ],
  callbacks: {
    session: async ({ session, token }) => {
      if (session?.user) {
        // Use token data instead of querying database on every request
        (session.user as any).id = token.uid;
        (session.user as any).role = (token.role as string | undefined) ?? "CUSTOMER";
        (session.user as any).username = token.username as string | undefined;
      }
      return session;
    },
    jwt: async ({ user, token }) => {
      if (user) {
        token.uid = user.id;
        token.role = (user as any).role ?? "CUSTOMER";
        token.username = (user as any).username;
      }
      return token;
    },
    redirect: async ({ url, baseUrl }) => {
      // Always use NEXTAUTH_URL if set, ignore baseUrl if it points to wrong domain (e.g., Grafana)
      // Check if baseUrl is invalid (contains localhost:3000, grafana, etc.)
      const isInvalidBaseUrl = baseUrl && (
        baseUrl.includes('localhost:3000') ||
        baseUrl.includes('grafana') ||
        baseUrl.includes('devcontainer-grafana')
      );
      
      // Use NEXTAUTH_URL if set, otherwise use baseUrl only if it's valid, fallback to meowtopia.ltd
      const appBaseUrl = process.env.NEXTAUTH_URL || (isInvalidBaseUrl ? 'http://meowtopia.ltd' : baseUrl) || 'http://meowtopia.ltd';
      
      console.log('[NextAuth] Redirect callback:', { url, baseUrl, appBaseUrl, isInvalidBaseUrl, hasNextAuthUrl: !!process.env.NEXTAUTH_URL });
      
      // For sign out, always redirect to home page
      if (url.includes("/api/auth/signout") || url.includes("callbackUrl=")) {
        try {
          const urlObj = new URL(url, appBaseUrl);
          const callbackUrl = urlObj.searchParams.get("callbackUrl");
          if (callbackUrl) {
            // If callbackUrl is absolute, validate it's from our domain
            if (callbackUrl.startsWith("http")) {
              const callbackUrlObj = new URL(callbackUrl);
              // Only allow redirects to our domain (not Grafana, not localhost:3000)
              if (callbackUrlObj.hostname.includes("meowtopia.ltd") || 
                  (callbackUrlObj.hostname === "localhost" && callbackUrlObj.port !== "3000")) {
                return callbackUrl;
              }
              // Invalid domain (Grafana, etc.), redirect to home
              console.log('[NextAuth] Invalid callbackUrl domain, redirecting to home:', callbackUrl);
              return new URL("/", appBaseUrl).toString();
            }
            // Ensure it's relative to app domain, not Grafana
            return new URL(callbackUrl.startsWith("/") ? callbackUrl : `/${callbackUrl}`, appBaseUrl).toString();
          }
        } catch (e) {
          console.error("[NextAuth] Error parsing callbackUrl:", e);
        }
        // Default to home page for sign out
        return new URL("/", appBaseUrl).toString();
      }
      
      // If redirecting after sign in, check the user's role and redirect accordingly
      if (url.startsWith(appBaseUrl) || url.startsWith("/")) {
        // Check if it's a panel callback
        if (url.includes("/panel") || url.includes("callbackUrl=/panel")) {
          return url.startsWith("/") ? new URL(url, appBaseUrl).toString() : url;
        }
        return url.startsWith("/") ? new URL(url, appBaseUrl).toString() : url;
      }
      
      // For external URLs or invalid URLs, redirect to home
      return new URL("/", appBaseUrl).toString();
    },
  },
  session: {
    strategy: "jwt",
  },
  pages: {
    signIn: "/signin",
  },
      cookies: {
        sessionToken: {
          name: `cus-session`, // Use cus-session for all users (customers)
          options: {
            httpOnly: true,
            sameSite: "lax",
            path: "/",
            // Set domain to allow cookies to work across subdomains in development
            // Use .meowtopia.ltd to allow cookies on both meowtopia.ltd and panel.meowtopia.ltd
            domain: ".meowtopia.ltd",
            secure: false, // Allow HTTP in development
          },
        },
        csrfToken: {
          name: `meowtopia-csrf`,
          options: {
            httpOnly: true,
            sameSite: "lax",
            path: "/",
            domain: ".meowtopia.ltd",
            secure: false, // Allow HTTP in development
          },
        },
        callbackUrl: {
          name: `next-auth.callback-url`,
          options: {
            httpOnly: true,
            sameSite: "lax",
            path: "/",
            domain: ".meowtopia.ltd",
            secure: false,
            maxAge: -1, // Disable by setting maxAge to -1 (immediate expiration)
          },
        },
      },
  // Ensure NEXTAUTH_URL is set correctly for subdomain support
  useSecureCookies: process.env.NODE_ENV === "production",
  secret: process.env.NEXTAUTH_SECRET || "fallback-secret-for-development-only-change-in-production", // Explicitly set secret with fallback
  debug: process.env.NODE_ENV === "development", // Enable debug in development
};

// Log secret status in development
if (process.env.NODE_ENV === "development") {
  console.log("NextAuth config:", {
    hasSecret: !!process.env.NEXTAUTH_SECRET,
    secretLength: process.env.NEXTAUTH_SECRET?.length || 0,
    useSecureCookies: false,
    cookieDomain: ".meowtopia.ltd",
  });
}

// Helper function to get role-based redirect path for Meowtopia
// Always returns user ID-based URL (GitHub style)
export function getRoleBasedRedirectPath(userId: string): string {
  return `/${userId}`;
}
