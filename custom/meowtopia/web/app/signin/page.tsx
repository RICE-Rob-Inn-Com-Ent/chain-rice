"use client";

import { signIn, getSession } from "next-auth/react";
import { useState, useEffect } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";

export default function SignIn() {
  const [isLoading, setIsLoading] = useState(false);
  const [credentialsLoading, setCredentialsLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const router = useRouter();
  const searchParams = useSearchParams();

  // Check if user is already logged in and redirect accordingly
  // But only if we're on the main domain (not panel subdomain)
  useEffect(() => {
    let mounted = true;
    const checkAndRedirect = async () => {
      // Only redirect if on main domain
      const currentHost = window.location.hostname;
      const isPanel = currentHost.startsWith("panel.");
      
      if (isPanel) {
        // On panel subdomain - don't redirect, let middleware handle it
        if (searchParams?.get("registered")) {
          setSuccess("Konto zostało utworzone. Możesz się zalogować.");
        }
        return;
      }
      
      // Wait longer to ensure session is fully loaded
      await new Promise(resolve => setTimeout(resolve, 500));
      if (!mounted) return;
      
      // Try multiple times to get session
      let session = null;
      for (let i = 0; i < 5; i++) {
        session = await getSession();
        if (session?.user) break;
        if (i < 4) await new Promise(resolve => setTimeout(resolve, 300));
      }
      
      if (!mounted) return;
      
      if (session?.user) {
        const userRole = (session.user as any)?.role || "USER";
        const username = (session.user as any)?.username || null;
        const adminRoles = ["ADMIN", "MANAGER", "OWNER", "SUPERADMIN"];
        
        if (adminRoles.includes(userRole)) {
          // Redirect admin to panel subdomain with username
          const baseDomain = currentHost.includes(".") 
            ? currentHost.split(".").slice(-2).join(".") 
            : "meowtopia.ltd";
          const protocol = window.location.protocol;
          const panelUrl = username 
            ? `${protocol}//panel.${baseDomain}/${username}`
            : `${protocol}//panel.${baseDomain}/`;
          console.log("Redirecting admin to:", panelUrl);
          window.location.href = panelUrl; // Use href instead of replace for debugging
          return;
        } else if (username) {
          window.location.href = `/${username}/dashboard`;
          return;
        } else {
          window.location.href = "/";
          return;
        }
      }
      
      // Check for registration success message
      if (searchParams?.get("registered")) {
        setSuccess("Konto zostało utworzone. Możesz się zalogować.");
      }
    };
    
    checkAndRedirect();
    
    return () => {
      mounted = false;
    };
  }, [searchParams]);

  const handleOAuthSignIn = async (provider: string) => {
    setIsLoading(true);
    setError("");

    try {
      const result = await signIn(provider, {
        redirect: false,
        callbackUrl: "/",
      });

      if (result?.error) {
        setError("Wystąpił błąd podczas logowania. Spróbuj ponownie.");
      } else if (result?.ok) {
        router.push(result.url ?? "/");
      }
    } catch (err) {
      setError("Wystąpił błąd podczas logowania. Spróbuj ponownie.");
    } finally {
      setIsLoading(false);
    }
  };

  const handleCredentialsSignIn = async (event: React.FormEvent) => {
    event.preventDefault();
    setError("");
    setCredentialsLoading(true);

    try {
      const result = await signIn("credentials", {
        redirect: false,
        email,
        password,
      });

      if (!result || result.error) {
        setError(result?.error === "CredentialsSignin" ? "Nieprawidłowy email lub hasło" : result?.error || "Logowanie nie powiodło się");
        return;
      }

      // Wait for session to be established - NextAuth needs time to set cookies
      // Important: Wait longer when redirecting to different subdomain to ensure cookies are set
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      // Try to get session - limit attempts to avoid loops
      let session = null;
      let userRole = "USER";
      let username = null;
      
      // Try up to 10 times with delays - need more attempts for cross-subdomain cookies
      for (let i = 0; i < 10; i++) {
        session = await getSession();
        if (session?.user) {
          userRole = (session.user as any)?.role || "USER";
          username = (session.user as any)?.username || null;
          // Verify session is stable - check twice to ensure cookies are set
          if (username && i > 2) {
            const verifySession = await getSession();
            if (verifySession?.user) break; // Session is stable
          }
        }
        if (i < 9) await new Promise(resolve => setTimeout(resolve, 500));
      }
      
      // If we still don't have a session, don't redirect - let user try again
      if (!session?.user) {
        console.log(`[SignIn] Session not established after login attempts`);
        setError("Sesja nie została ustanowiona. Spróbuj ponownie.");
        return;
      }
      
      console.log(`[SignIn] Session established:`, { 
        role: userRole, 
        username: username || 'not set',
        hasUser: !!session.user 
      });
      
      const adminRoles = ["ADMIN", "MANAGER", "OWNER", "SUPERADMIN"];
      
      if (adminRoles.includes(userRole)) {
        // Always redirect admin to panel subdomain with username
        const currentHost = window.location.hostname;
        const baseDomain = currentHost.includes(".") 
          ? currentHost.split(".").slice(-2).join(".") 
          : "meowtopia.ltd";
        const protocol = window.location.protocol;
        
        // If we have username, redirect directly - use location.replace to prevent back button
        if (username && username.trim()) {
          const panelUrl = `${protocol}//panel.${baseDomain}/${username}/dashboard`;
          console.log(`[SignIn] Redirecting admin with username to: ${panelUrl}`);
          // Use replace to prevent back button and loops
          // Add small delay to ensure cookies are fully set before redirect
          await new Promise(resolve => setTimeout(resolve, 300));
          window.location.replace(panelUrl);
          return;
        }
        
        console.log(`[SignIn] Admin role but username not available yet, redirecting to panel root`);
        
        // If no username, redirect to panel root
        const panelUrl = `${protocol}//panel.${baseDomain}/`;
        await new Promise(resolve => setTimeout(resolve, 300));
        window.location.replace(panelUrl);
        return;
      } else {
        // For customers (non-admin users), always redirect to home/shop
        await new Promise(resolve => setTimeout(resolve, 300));
        window.location.replace("/");
        return;
      }
    } catch (err) {
      setError("Wystąpił nieoczekiwany błąd podczas logowania");
    } finally {
      setCredentialsLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-jungle-950 via-jungle-900 to-jungle-950 px-6 py-12">
      <div className="w-full max-w-md">
        <Link href="/" className="mb-8 inline-flex items-center gap-2 text-foam-100/60 hover:text-foam-50">
          <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
          </svg>
          <span className="text-sm">Powrót do sklepu</span>
        </Link>

        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-jungle-900 to-jungle-950 p-8 shadow-2xl">
          <div className="mb-8 text-center">
            <div className="mb-4 inline-flex h-16 w-16 items-center justify-center rounded-xl bg-gradient-to-br from-jungle-500 to-jungle-600">
              <span className="text-2xl">🐱</span>
            </div>
            <h1 className="text-2xl font-bold text-foam-50 mb-2">
              Zaloguj się do MeoWTopia
            </h1>
            <p className="text-foam-200/70">
              Kontynuuj zakupy w naszym kocim sklepiku
            </p>
          </div>

          {success && (
            <div className="mb-6 rounded-lg border border-green-500/40 bg-green-500/10 p-3 text-sm text-green-200">
              {success}
            </div>
          )}

          {error && (
            <div className="mb-6 p-4 bg-red-500/10 border border-red-500/20 text-red-400 rounded-lg text-sm">
              {error}
            </div>
          )}

          <form onSubmit={handleCredentialsSignIn} className="mb-8 space-y-4">
            <div>
              <label htmlFor="email" className="mb-2 block text-sm font-medium text-foam-50">
                Email
              </label>
              <div className="relative">
                <input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  className="w-full rounded-lg border border-white/10 bg-white/5 px-4 py-3 text-foam-50 placeholder:text-foam-100/40 focus:border-jungle-500 focus:outline-none focus:ring-2 focus:ring-jungle-500/20"
                  placeholder="kot@meowtopia.pl"
                />
              </div>
            </div>

            <div>
              <label htmlFor="password" className="mb-2 block text-sm font-medium text-foam-50">
                Hasło
              </label>
              <div className="relative">
                <input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="w-full rounded-lg border border-white/10 bg-white/5 px-4 py-3 text-foam-50 placeholder:text-foam-100/40 focus:border-jungle-500 focus:outline-none focus:ring-2 focus:ring-jungle-500/20"
                  placeholder="••••••••"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={credentialsLoading}
              className="w-full rounded-lg bg-gradient-to-r from-jungle-500 to-jungle-600 px-4 py-3 font-semibold text-white shadow-lg shadow-jungle-500/25 transition hover:from-jungle-400 hover:to-jungle-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {credentialsLoading ? "Logowanie..." : "Zaloguj się"}
            </button>

            <div className="text-center">
              <p className="text-sm text-foam-200/60">
                Nie masz konta?{" "}
                <Link href="/signup" className="font-semibold text-jungle-400 hover:text-jungle-300">
                  Zarejestruj się
                </Link>
              </p>
            </div>
          </form>

          <div className="space-y-3">
            <button
              onClick={() => handleOAuthSignIn("google")}
              disabled={isLoading}
              className="w-full flex items-center justify-center gap-3 px-4 py-3 bg-white text-gray-900 rounded-lg hover:bg-gray-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
            >
              <svg className="w-5 h-5" viewBox="0 0 24 24">
                <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
                <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/>
                <path fill="#FBBC04" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/>
                <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/>
              </svg>
              {isLoading ? "Łączenie..." : "Kontynuuj z Google"}
            </button>

            <button
              onClick={() => handleOAuthSignIn("facebook")}
              disabled={isLoading}
              className="w-full flex items-center justify-center gap-3 px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
            >
              <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"/>
              </svg>
              {isLoading ? "Łączenie..." : "Kontynuuj z Facebook"}
            </button>
          </div>

          <div className="mt-6 text-center">
            <p className="text-sm text-foam-200/60">
              Logując się, akceptujesz nasze warunki korzystania z serwisu
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

