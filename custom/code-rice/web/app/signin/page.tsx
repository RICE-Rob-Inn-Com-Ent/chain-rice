"use client";

import { useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { Mail, Lock, AlertCircle, Zap, ArrowLeft, CheckCircle2 } from "lucide-react";

export default function SignInPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (searchParams.get("registered")) {
      setSuccess("Konto zostało utworzone. Możesz się zalogować.");
    }
    if (searchParams.get("redirect")) {
      setSuccess("Zaloguj się, aby kontynuować.");
    }
  }, [searchParams]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setSuccess("");
    setLoading(true);

    try {
      const res = await fetch("/api/auth/sign-in", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Nie udało się zalogować");
        return;
      }

      // IMMEDIATE check - if owner/admin, redirect RIGHT NOW, no questions asked
      const userRole = String(data.role || "").trim();
      const roleLower = userRole.toLowerCase();
      const isOwner = roleLower === "owner" || userRole === "OWN" || userRole === "own";
      const isAdmin = roleLower === "admin" || userRole === "ADM" || userRole === "adm" || roleLower === "superadmin";
      
      // Also check user ID format as fallback (OWN- prefix means owner)
      const userId = String(data.userId || data.id || "").trim();
      const isOwnerById = userId.startsWith("OWN-");
      const isAdminById = userId.startsWith("ADM-");
      
      // DEBUG: Log everything
      console.log("[signin] ========== FULL DEBUG ==========");
      console.log("[signin] API Response:", JSON.stringify(data, null, 2));
      console.log("[signin] userRole:", userRole);
      console.log("[signin] roleLower:", roleLower);
      console.log("[signin] userId:", userId);
      console.log("[signin] isOwner:", isOwner);
      console.log("[signin] isAdmin:", isAdmin);
      console.log("[signin] isOwnerById:", isOwnerById);
      console.log("[signin] isAdminById:", isAdminById);
      console.log("[signin] ===============================");
      
      if (isOwner || isAdmin || isOwnerById || isAdminById) {
        console.log("[signin] ⚡ OWNER/ADMIN DETECTED - IMMEDIATE REDIRECT TO /admin/dashboard");
        // IMMEDIATE redirect with full URL - don't wait, don't check anything else
        const fullUrl = window.location.origin + "/admin/dashboard";
        console.log("[signin] Redirecting to:", fullUrl);
        // Force redirect - use replace to prevent back button
        window.location.replace(fullUrl);
        return; // Stop execution immediately
      }

      // Only regular users get here
      const redirectUrl = data.redirect || searchParams.get("redirect") || "/";
      console.log("[signin] Regular user redirect:", redirectUrl);
      window.location.href = redirectUrl;
    } catch (err: any) {
      setError(err.message || "Wystąpił błąd podczas logowania");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-void-950 via-void-900 to-void-950 px-6 py-12">
      <div className="w-full max-w-md">
        <Link href="/" className="mb-8 inline-flex items-center gap-2 text-white/60 hover:text-white">
          <ArrowLeft className="h-4 w-4" />
          <span className="text-sm">Powrót do strony głównej</span>
        </Link>

        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-void-900 to-void-950 p-8 shadow-2xl">
          <div className="mb-8 text-center">
            <div className="mb-4 inline-flex h-16 w-16 items-center justify-center rounded-xl bg-gradient-to-br from-ion-500 to-ion-600">
              <Zap className="h-8 w-8 text-white" />
            </div>
            <h1 className="mb-2 font-display text-3xl font-bold text-white">Zaloguj się</h1>
            <p className="text-white/60">Witaj z powrotem w RICE</p>
          </div>

          {success && (
            <div className="mb-6 flex items-center gap-2 rounded-lg border border-green-500/40 bg-green-500/10 p-3 text-sm text-green-300">
              <CheckCircle2 className="h-4 w-4" />
              <span>{success}</span>
            </div>
          )}

          {error && (
            <div className="mb-6 flex items-center gap-2 rounded-lg border border-red-500/50 bg-red-500/10 p-3 text-sm text-red-300">
              <AlertCircle className="h-4 w-4" />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label htmlFor="email" className="mb-2 block text-sm font-medium text-white">
                Email
              </label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-white/40" />
                <input
                  id="email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  className="w-full rounded-lg border border-white/10 bg-white/5 pl-10 pr-4 py-3 text-white placeholder:text-white/40 focus:border-ion-500 focus:outline-none focus:ring-2 focus:ring-ion-500/20"
                  placeholder="twoj@email.pl"
                />
              </div>
            </div>

            <div>
              <label htmlFor="password" className="mb-2 block text-sm font-medium text-white">
                Hasło
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-white/40" />
                <input
                  id="password"
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  required
                  className="w-full rounded-lg border border-white/10 bg-white/5 pl-10 pr-4 py-3 text-white placeholder:text-white/40 focus:border-ion-500 focus:outline-none focus:ring-2 focus:ring-ion-500/20"
                  placeholder="••••••••"
                />
              </div>
            </div>

            <div className="flex items-center justify-between">
              <label className="flex items-center gap-2 text-sm text-white/60">
                <input type="checkbox" className="rounded border-white/20 bg-white/5" />
                <span>Zapamiętaj mnie</span>
              </label>
              <Link href="/forgotpassword" className="text-sm text-ion-400 hover:text-ion-300">
                Zapomniałeś hasła?
              </Link>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-lg bg-gradient-to-r from-ion-500 to-ion-600 px-4 py-3 font-semibold text-white shadow-lg shadow-ion-500/25 transition hover:from-ion-400 hover:to-ion-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? "Logowanie..." : "Zaloguj się"}
            </button>
          </form>

          <div className="mt-6 text-center">
            <p className="text-sm text-white/60">
              Nie masz konta?{" "}
              <Link href="/signup" className="font-semibold text-ion-400 hover:text-ion-300">
                Zarejestruj się
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

