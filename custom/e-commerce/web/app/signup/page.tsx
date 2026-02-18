"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { Mail, Lock, User, ArrowLeft, Cat, Check } from "lucide-react";

export default function SignUpPage() {
  const router = useRouter();
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    password: "",
    confirmPassword: "",
  });
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");

    if (formData.password !== formData.confirmPassword) {
      setError("Hasła nie są identyczne");
      return;
    }

    if (formData.password.length < 8) {
      setError("Hasło musi mieć co najmniej 8 znaków");
      return;
    }

    setLoading(true);

    try {
      const response = await fetch("/api/auth/register", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: formData.name.trim(),
          email: formData.email.trim(),
          password: formData.password,
        }),
      });

      const data = await response.json();
      if (!response.ok) {
        setError(data?.error || "Nie udało się utworzyć konta");
        return;
      }

      router.push("/signin?registered=true");
    } catch (error: any) {
      setError(error?.message || "Wystąpił błąd podczas rejestracji");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-jungle-950 via-jungle-900 to-jungle-950 px-6 py-12">
      <div className="w-full max-w-md">
        <Link href="/" className="mb-8 inline-flex items-center gap-2 text-foam-100/60 hover:text-foam-50">
          <ArrowLeft className="h-4 w-4" />
          <span className="text-sm">Powrót do strony głównej</span>
        </Link>

        <div className="rounded-2xl border border-white/10 bg-gradient-to-br from-jungle-900 to-jungle-950 p-8 shadow-2xl">
          <div className="mb-8 text-center">
            <div className="mb-4 inline-flex h-16 w-16 items-center justify-center rounded-xl bg-gradient-to-br from-jungle-500 to-jungle-600">
              <Cat className="h-8 w-8 text-white" />
            </div>
            <h1 className="mb-2 font-heading text-3xl font-bold text-foam-50">Utwórz konto</h1>
            <p className="text-foam-100/60">Rozpocznij swoją przygodę z <span style={{ fontFamily: 'Poppins, serif', fontWeight: 900, color: 'black' }}>MeoWTopia</span></p>
          </div>

          {error && (
            <div className="mb-6 rounded-lg border border-red-500/50 bg-red-500/10 p-3 text-sm text-red-300">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label htmlFor="name" className="mb-2 block text-sm font-medium text-foam-50">
                Imię i nazwisko
              </label>
              <div className="relative">
                <User className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-foam-100/40" />
                <input
                  id="name"
                  name="name"
                  type="text"
                  value={formData.name}
                  onChange={handleChange}
                  required
                  className="w-full rounded-lg border border-white/10 bg-white/5 pl-10 pr-4 py-3 text-foam-50 placeholder:text-foam-100/40 focus:border-jungle-500 focus:outline-none focus:ring-2 focus:ring-jungle-500/20"
                  placeholder="Jan Kowalski"
                />
              </div>
            </div>

            <div>
              <label htmlFor="email" className="mb-2 block text-sm font-medium text-foam-50">
                Email
              </label>
              <div className="relative">
                <Mail className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-foam-100/40" />
                <input
                  id="email"
                  name="email"
                  type="email"
                  value={formData.email}
                  onChange={handleChange}
                  required
                  className="w-full rounded-lg border border-white/10 bg-white/5 pl-10 pr-4 py-3 text-foam-50 placeholder:text-foam-100/40 focus:border-jungle-500 focus:outline-none focus:ring-2 focus:ring-jungle-500/20"
                  placeholder="twoj@email.pl"
                />
              </div>
            </div>

            <div>
              <label htmlFor="password" className="mb-2 block text-sm font-medium text-foam-50">
                Hasło
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-foam-100/40" />
                <input
                  id="password"
                  name="password"
                  type="password"
                  value={formData.password}
                  onChange={handleChange}
                  required
                  minLength={8}
                  className="w-full rounded-lg border border-white/10 bg-white/5 pl-10 pr-4 py-3 text-foam-50 placeholder:text-foam-100/40 focus:border-jungle-500 focus:outline-none focus:ring-2 focus:ring-jungle-500/20"
                  placeholder="Minimum 8 znaków"
                />
              </div>
            </div>

            <div>
              <label htmlFor="confirmPassword" className="mb-2 block text-sm font-medium text-foam-50">
                Potwierdź hasło
              </label>
              <div className="relative">
                <Lock className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-foam-100/40" />
                <input
                  id="confirmPassword"
                  name="confirmPassword"
                  type="password"
                  value={formData.confirmPassword}
                  onChange={handleChange}
                  required
                  className="w-full rounded-lg border border-white/10 bg-white/5 pl-10 pr-4 py-3 text-foam-50 placeholder:text-foam-100/40 focus:border-jungle-500 focus:outline-none focus:ring-2 focus:ring-jungle-500/20"
                  placeholder="Powtórz hasło"
                />
              </div>
            </div>

            <div className="flex items-start gap-2 text-sm text-foam-100/60">
              <input type="checkbox" required className="mt-1 rounded border-white/20 bg-white/5" />
              <span>
                Akceptuję{" "}
                <Link href="/regulamin" className="text-jungle-400 hover:text-jungle-300">
                  regulamin
                </Link>{" "}
                i{" "}
                <Link href="/polityka" className="text-jungle-400 hover:text-jungle-300">
                  politykę prywatności
                </Link>
              </span>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full rounded-lg bg-gradient-to-r from-jungle-500 to-jungle-600 px-4 py-3 font-semibold text-white shadow-lg shadow-jungle-500/25 transition hover:from-jungle-400 hover:to-jungle-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? "Tworzenie konta..." : "Utwórz konto"}
            </button>
          </form>

          <div className="mt-6 text-center">
            <p className="text-sm text-foam-100/60">
              Masz już konto?{" "}
              <Link href="/signin" className="font-semibold text-jungle-400 hover:text-jungle-300">
                Zaloguj się
              </Link>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

