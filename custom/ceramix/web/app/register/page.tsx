"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Sparkles, AlertCircle, CheckCircle2 } from "lucide-react";

export default function SignUpPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [displayName, setDisplayName] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setSuccess(false);
    setLoading(true);

    try {
      const res = await fetch("/api/auth/signup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email,
          password,
          displayName,
          firstName,
          lastName,
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Błąd rejestracji");
        setLoading(false);
        return;
      }

      setSuccess(true);
      setTimeout(() => {
        router.push(data.redirect || "/account");
        router.refresh();
      }, 1500);
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
            Utwórz konto
          </h1>
          <p className="text-[#f8f3e7]/70">
            Dołącz do Ceramix i zarządzaj swoimi wizytami
          </p>
        </div>

        <div className="marble-card p-8">
          {success && (
            <div className="mb-6 flex items-center gap-3 rounded-lg bg-green-500/20 border border-green-500/50 p-4 text-green-400">
              <CheckCircle2 className="h-5 w-5 flex-shrink-0" />
              <span className="text-sm">Konto zostało utworzone pomyślnie!</span>
            </div>
          )}

          {error && (
            <div className="mb-6 flex items-center gap-3 rounded-lg bg-red-500/20 border border-red-500/50 p-4 text-red-400">
              <AlertCircle className="h-5 w-5 flex-shrink-0" />
              <span className="text-sm">{error}</span>
            </div>
          )}

          <form onSubmit={handleSignUp} className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                Email *
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
                Hasło *
              </label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                minLength={8}
                className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                placeholder="Minimum 8 znaków"
              />
              <p className="mt-1 text-xs text-[#f8f3e7]/50">
                Hasło musi mieć co najmniej 8 znaków
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                Nazwa wyświetlana *
              </label>
              <input
                type="text"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                required
                className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                placeholder="Jan Kowalski"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                  Imię
                </label>
                <input
                  type="text"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  placeholder="Jan"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                  Nazwisko
                </label>
                <input
                  type="text"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  placeholder="Kowalski"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading || success}
              className="btn-primary w-full disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? "Tworzenie konta..." : success ? "Przekierowywanie..." : "Utwórz konto"}
            </button>
          </form>

          <div className="mt-6 pt-6 border-t border-[#f8f3e7]/10">
            <p className="text-sm text-[#f8f3e7]/60 text-center mb-4">
              Masz już konto?{" "}
              <Link
                href="/login"
                className="text-[#f6823c] hover:text-[#eb520a] transition-colors font-medium"
              >
                Zaloguj się
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













