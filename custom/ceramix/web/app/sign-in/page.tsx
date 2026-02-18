"use client";

import { useState, useEffect, Suspense } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { Sparkles, Shield, AlertCircle } from "lucide-react";

function LoginForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [step, setStep] = useState<"login" | "2fa">("login");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [twoFactorCode, setTwoFactorCode] = useState("");
  const [backupCode, setBackupCode] = useState("");
  const [useBackupCode, setUseBackupCode] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const errorParam = searchParams.get("error");
    if (errorParam) {
      setError(decodeURIComponent(errorParam));
    }
  }, [searchParams]);

  const getRedirectUrl = (role?: string) => {
    const redirect = searchParams.get("redirect");
    if (redirect) return redirect;
    
    // Default redirect - will be handled by API response
    return "/me";
  };

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const res = await fetch("/api/auth/sign-in", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Błąd logowania");
        setLoading(false);
        return;
      }

      if (data.requires2FA) {
        setStep("2fa");
        setLoading(false);
      } else {
        // After successful login, ALWAYS redirect to panel subdomain (no exceptions)
        // This is mandatory - logged-in users cannot stay on ceramix.ltd
        if (typeof window !== 'undefined') {
          const protocol = window.location.protocol;
          const panelDomain = data.panelDomain || process.env.NEXT_PUBLIC_PANEL_URL?.replace(/^https?:\/\//, '') || 'panel.ceramix.ltd';
          const redirectPath = data.redirect || "/me"; // Default to /me which redirects to dashboard
          const redirectUrl = `${protocol}//${panelDomain}${redirectPath}`;
          
          console.log(`[sign-in] Redirecting to panel: ${redirectUrl}`);
          // Use window.location.href for full page redirect (including domain change)
          window.location.href = redirectUrl;
          return;
        }
        
        router.push(data.redirect || "/me");
        router.refresh();
      }
    } catch (err) {
      setError("Wystąpił błąd. Spróbuj ponownie.");
      setLoading(false);
    }
  };

  const handle2FA = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const code = useBackupCode ? backupCode : twoFactorCode;
      const res = await fetch("/api/auth/verify-2fa", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, code, isBackupCode: useBackupCode }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Nieprawidłowy kod");
        setLoading(false);
        return;
      }

      // After successful 2FA verification, ALWAYS redirect to panel subdomain (no exceptions)
      // This is mandatory - logged-in users cannot stay on ceramix.ltd
      if (typeof window !== 'undefined') {
        const protocol = window.location.protocol;
        const panelDomain = data.panelDomain || process.env.NEXT_PUBLIC_PANEL_URL?.replace(/^https?:\/\//, '') || 'panel.ceramix.ltd';
        const redirectPath = data.redirect || "/me"; // Default to /me which redirects to dashboard
        const redirectUrl = `${protocol}//${panelDomain}${redirectPath}`;
        
        console.log(`[sign-in 2FA] Redirecting to panel: ${redirectUrl}`);
        // Use window.location.href for full page redirect (including domain change)
        window.location.href = redirectUrl;
        return;
      }
      
      router.push(data.redirect || "/me");
      router.refresh();
    } catch (err) {
      setError("Wystąpił błąd. Spróbuj ponownie.");
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#050505] flex items-center justify-center p-6">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="inline-flex items-center gap-3 mb-4">
            <div className="w-12 h-12 bg-gradient-to-br from-[#eb520a] to-[#cb3906] rounded-lg flex items-center justify-center">
              <Sparkles className="w-7 h-7 text-white" />
            </div>
            <span className="text-3xl font-display font-bold text-[#f8f3e7]">Ceramix</span>
          </div>
          <h1 className="text-2xl font-semibold text-[#f8f3e7] mb-2">
            {step === "login" ? "Zaloguj się" : "Weryfikacja dwuetapowa"}
          </h1>
          <p className="text-[#f8f3e7]/70">
            {step === "login"
              ? "Wprowadź dane logowania"
              : "Wprowadź kod z aplikacji autoryzującej"}
          </p>
        </div>

        <div className="marble-card p-8">
          {error && (
            <div className="mb-6 flex items-center gap-3 rounded-lg bg-red-500/20 border border-red-500/50 p-4 text-red-400">
              <AlertCircle className="h-5 w-5 flex-shrink-0" />
              <span className="text-sm">{error}</span>
            </div>
          )}

          {step === "login" ? (
            <>
              {/* OAuth Buttons */}
              <div className="space-y-3 mb-6">
                <a
                  href="/api/auth/oauth/google"
                  className="flex items-center justify-center gap-3 w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] hover:bg-[#171717]/70 hover:border-[#eb520a]/50 transition-all"
                >
                  <svg className="w-5 h-5" viewBox="0 0 24 24">
                    <path
                      fill="currentColor"
                      d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
                    />
                    <path
                      fill="currentColor"
                      d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
                    />
                    <path
                      fill="currentColor"
                      d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
                    />
                    <path
                      fill="currentColor"
                      d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
                    />
                  </svg>
                  Zaloguj się przez Google
                </a>
              </div>

              <div className="relative mb-6">
                <div className="absolute inset-0 flex items-center">
                  <div className="w-full border-t border-[#f8f3e7]/20"></div>
                </div>
                <div className="relative flex justify-center text-sm">
                  <span className="px-2 bg-[#171717] text-[#f8f3e7]/60">lub</span>
                </div>
              </div>

              <form onSubmit={handleLogin} className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Email
                  </label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                    placeholder="twoj@email.pl"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Hasło
                  </label>
                  <input
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                    placeholder="••••••••"
                  />
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="btn-primary w-full disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {loading ? "Logowanie..." : "Zaloguj się"}
                </button>
              </form>
            </>
          ) : (
            <form onSubmit={handle2FA} className="space-y-6">
              <div className="flex items-center gap-3 p-4 bg-blue-500/10 border border-blue-500/30 rounded-lg">
                <Shield className="h-5 w-5 text-blue-400 flex-shrink-0" />
                <p className="text-sm text-[#f8f3e7]/80">
                  {useBackupCode
                    ? "Wprowadź kod zapasowy"
                    : "Otwórz aplikację autoryzującą i wprowadź 6-cyfrowy kod"}
                </p>
              </div>

              {!useBackupCode ? (
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Kod weryfikacyjny
                  </label>
                  <input
                    type="text"
                    value={twoFactorCode}
                    onChange={(e) => setTwoFactorCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
                    required
                    maxLength={6}
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] text-center text-2xl tracking-widest focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                    placeholder="000000"
                  />
                </div>
              ) : (
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Kod zapasowy
                  </label>
                  <input
                    type="text"
                    value={backupCode}
                    onChange={(e) => setBackupCode(e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 8))}
                    required
                    maxLength={8}
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] text-center text-lg tracking-wider focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                    placeholder="XXXXXXXX"
                  />
                </div>
              )}

              <button
                type="button"
                onClick={() => {
                  setUseBackupCode(!useBackupCode);
                  setTwoFactorCode("");
                  setBackupCode("");
                  setError("");
                }}
                className="text-sm text-[#f6823c] hover:text-[#eb520a] transition-colors"
              >
                {useBackupCode ? "Użyj kodu z aplikacji" : "Użyj kodu zapasowego"}
              </button>

              <button
                type="submit"
                disabled={loading || (!useBackupCode && twoFactorCode.length !== 6) || (useBackupCode && !backupCode)}
                className="btn-primary w-full disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {loading ? "Weryfikacja..." : "Zweryfikuj"}
              </button>

              <button
                type="button"
                onClick={() => {
                  setStep("login");
                  setTwoFactorCode("");
                  setBackupCode("");
                  setError("");
                }}
                className="text-sm text-[#f8f3e7]/60 hover:text-[#f8f3e7] transition-colors w-full"
              >
                ← Wróć do logowania
              </button>
            </form>
          )}

          <div className="mt-6 pt-6 border-t border-[#f8f3e7]/10">
            <p className="text-sm text-[#f8f3e7]/60 text-center mb-4">
              Nie masz konta?{" "}
              <Link
                href="/sign-up"
                className="text-[#f6823c] hover:text-[#eb520a] transition-colors font-medium"
              >
                Zarejestruj się
              </Link>
            </p>
            <Link
              href="/"
              className="text-sm text-[#f8f3e7]/60 hover:text-[#f6823c] transition-colors block text-center"
            >
              ← Powrót do strony głównej
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function SignInPage() {
  return (
    <Suspense fallback={<div className="min-h-screen bg-[#050505] flex items-center justify-center"><div className="text-[#f8f3e7]">Ładowanie...</div></div>}>
      <LoginForm />
    </Suspense>
  );
}

