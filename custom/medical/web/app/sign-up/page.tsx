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
  const [phone, setPhone] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [patientProfile, setPatientProfile] = useState({
    pesel: "",
    peselStatus: "",
    childNumber: "",
    dateOfBirth: "",
    gender: "",
    nfzBranch: "",
    insuranceEntitlement: "",
    insuranceConfirmationStatus: "N",
    additionalEntitlements: "",
    ekuNumber: "",
    euPatientNumber: "",
    maidenName: "",
    fatherName: "",
    motherName: "",
    authorizedPerson: "",
    documentsInfo: "",
    consentAccepted: false,
    // Medical history
    allergies: "",
    asthma: false,
    jaundice: "",
    hypertension: "",
    heartDiseases: false,
    kidneyDiseases: false,
    diabetes: false,
    tuberculosis: false,
    rheumaticDisease: false,
    bloodClottingDisorders: false,
    hormonalDisorders: false,
    porphyria: false,
    thyroidDiseases: false,
    otherDiseases: "",
    currentMedications: "",
    treatmentConsent: false,
  });

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setSuccess(false);
    setLoading(true);

    try {
      if (!patientProfile.pesel || patientProfile.pesel.length !== 11) {
        setError("PESEL jest wymagany i musi mieć 11 cyfr.");
        setLoading(false);
        return;
      }
      if (!patientProfile.dateOfBirth) {
        setError("Podaj datę urodzenia.");
        setLoading(false);
        return;
      }
      if (!patientProfile.gender) {
        setError("Wybierz płeć.");
        setLoading(false);
        return;
      }
      if (!phone) {
        setError("Numer telefonu jest wymagany.");
        setLoading(false);
        return;
      }
      if (!patientProfile.consentAccepted) {
        setError("Musisz wyrazić zgodę na przetwarzanie danych medycznych.");
        setLoading(false);
        return;
      }

      const res = await fetch("/api/auth/signup", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email,
          password,
          displayName,
          firstName,
          lastName,
          patientProfile,
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
        // After successful signup, redirect to panel subdomain if usePanelDomain is true (standardized)
        if (data.usePanelDomain && typeof window !== 'undefined') {
          const protocol = window.location.protocol;
          const panelDomain = data.panelDomain || process.env.NEXT_PUBLIC_PANEL_URL?.replace(/^https?:\/\//, '') || 'panel.ceramix.ltd';
          const redirectUrl = `${protocol}//${panelDomain}${data.redirect || "/account"}`;
          window.location.href = redirectUrl;
          return;
        }
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
                Email <span className="text-[#eb520a]">*</span>
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
                Hasło <span className="text-[#eb520a]">*</span>
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
                Nazwa wyświetlana <span className="text-[#eb520a]">*</span>
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
                  Imię <span className="text-[#eb520a]">*</span>
                </label>
                <input
                  type="text"
                  required
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  placeholder="Jan"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                  Nazwisko <span className="text-[#eb520a]">*</span>
                </label>
                <input
                  type="text"
                  required
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  placeholder="Kowalski"
                />
              </div>
            </div>

            <div className="space-y-4 border border-[#f8f3e7]/10 rounded-2xl p-4">
              <div>
                <p className="text-xs uppercase tracking-[0.3em] text-[#f8f3e7]/40">1. Dane podstawowe</p>
                <h3 className="text-lg font-semibold text-[#f8f3e7]">Dane pacjenta</h3>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    PESEL <span className="text-[#eb520a]">*</span>
                  </label>
                  <input
                    type="text"
                    value={patientProfile.pesel}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({
                        ...prev,
                        pesel: e.target.value.replace(/\D/g, "").slice(0, 11),
                      }))
                    }
                    required
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Status PESEL
                  </label>
                  <input
                    type="text"
                    value={patientProfile.peselStatus}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, peselStatus: e.target.value }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Nr dziecka
                  </label>
                  <input
                    type="text"
                    value={patientProfile.childNumber}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, childNumber: e.target.value }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Data urodzenia <span className="text-[#eb520a]">*</span>
                  </label>
                  <input
                    type="date"
                    value={patientProfile.dateOfBirth}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, dateOfBirth: e.target.value }))
                    }
                    required
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Płeć <span className="text-[#eb520a]">*</span>
                  </label>
                  <select
                    value={patientProfile.gender}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, gender: e.target.value }))
                    }
                    required
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  >
                    <option value="">Wybierz</option>
                    <option value="F">Kobieta</option>
                    <option value="M">Mężczyzna</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Numer telefonu <span className="text-[#eb520a]">*</span>
                  </label>
                  <input
                    type="tel"
                    required
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                    placeholder="+48 123 456 789"
                  />
                </div>
              </div>
            </div>

            <div className="space-y-4 border border-[#f8f3e7]/10 rounded-2xl p-4">
              <div>
                <p className="text-xs uppercase tracking-[0.3em] text-[#f8f3e7]/40">2. Ubezpieczyciel</p>
                <h3 className="text-lg font-semibold text-[#f8f3e7]">Informacje NFZ</h3>
              </div>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Oddział NFZ *
                  </label>
                  <input
                    type="text"
                    value={patientProfile.nfzBranch}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, nfzBranch: e.target.value }))
                    }
                    required
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                    placeholder="np. 12 - Śląski Oddział NFZ"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Uprawnienie
                  </label>
                  <input
                    type="text"
                    value={patientProfile.insuranceEntitlement}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({
                        ...prev,
                        insuranceEntitlement: e.target.value,
                      }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Status potwierdzenia ubezpieczenia *
                  </label>
                  <select
                    value={patientProfile.insuranceConfirmationStatus}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({
                        ...prev,
                        insuranceConfirmationStatus: e.target.value,
                      }))
                    }
                    required
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  >
                    <option value="N">N - Nie dotyczy</option>
                    <option value="P">P - Potwierdzone</option>
                    <option value="O">O - Odrzucone</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Uprawnienia dodatkowe
                  </label>
                  <input
                    type="text"
                    value={patientProfile.additionalEntitlements}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({
                        ...prev,
                        additionalEntitlements: e.target.value,
                      }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Nr EKUZ
                  </label>
                  <input
                    type="text"
                    value={patientProfile.ekuNumber}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, ekuNumber: e.target.value }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Nr pacjenta w UE
                  </label>
                  <input
                    type="text"
                    value={patientProfile.euPatientNumber}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, euPatientNumber: e.target.value }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  />
                </div>
              </div>
            </div>

            <div className="space-y-4 border border-[#f8f3e7]/10 rounded-2xl p-4">
              <div>
                <p className="text-xs uppercase tracking-[0.3em] text-[#f8f3e7]/40">3. Informacje dodatkowe</p>
                <h3 className="text-lg font-semibold text-[#f8f3e7]">Rodzina i dokumenty</h3>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Nazwisko rodowe *
                  </label>
                  <input
                    type="text"
                    value={patientProfile.maidenName}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, maidenName: e.target.value }))
                    }
                    required
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Imię ojca
                  </label>
                  <input
                    type="text"
                    value={patientProfile.fatherName}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, fatherName: e.target.value }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Imię matki
                  </label>
                  <input
                    type="text"
                    value={patientProfile.motherName}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, motherName: e.target.value }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Upoważniona osoba do odbierania danych medycznych
                  </label>
                  <input
                    type="text"
                    value={patientProfile.authorizedPerson}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, authorizedPerson: e.target.value }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                    placeholder="Imię i nazwisko"
                  />
                </div>
              </div>
              <div>
                <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                  Dokumenty / uwagi
                </label>
                <textarea
                  rows={3}
                  value={patientProfile.documentsInfo}
                  onChange={(e) =>
                    setPatientProfile((prev) => ({ ...prev, documentsInfo: e.target.value }))
                  }
                  className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                  placeholder="Np. dokumenty potwierdzające uprawnienia"
                />
              </div>
              <label className="flex items-start gap-3 text-sm text-[#f8f3e7]/80">
                <input
                  type="checkbox"
                checked={patientProfile.consentAccepted}
                onChange={(e) =>
                  setPatientProfile((prev) => ({
                    ...prev,
                    consentAccepted: e.target.checked,
                  }))
                }
                required
                className="mt-1 h-4 w-4 rounded border border-[#f8f3e7]/30 bg-transparent text-[#eb520a] focus:ring-[#eb520a]"
              />
              <span>
                Wyrażam zgodę na przetwarzanie danych medycznych w celu prowadzenia dokumentacji
                pacjenta i obsługi wizyt. <span className="text-[#eb520a]">*</span>
              </span>
              </label>
            </div>

            {/* Historia medyczna */}
            <div className="space-y-4 border border-[#f8f3e7]/10 rounded-2xl p-4">
              <div>
                <p className="text-xs uppercase tracking-[0.3em] text-[#f8f3e7]/40">
                  2. Historia medyczna
                </p>
                <h3 className="text-lg font-semibold text-[#f8f3e7] mt-1">
                  Schorzenia (obecne, przebyte) i leki
                </h3>
              </div>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Alergie - na co?
                  </label>
                  <input
                    type="text"
                    value={patientProfile.allergies}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, allergies: e.target.value }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                    placeholder="Np. penicylina, jad owadów lub 'brak'"
                  />
                </div>

                <div className="grid md:grid-cols-2 gap-4">
                  <label className="flex items-center gap-3 text-sm text-[#f8f3e7]/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={patientProfile.asthma}
                      onChange={(e) =>
                        setPatientProfile((prev) => ({ ...prev, asthma: e.target.checked }))
                      }
                      className="h-4 w-4 rounded border border-[#f8f3e7]/30 bg-transparent text-[#eb520a] focus:ring-[#eb520a]"
                    />
                    <span>Astma</span>
                  </label>

                  <label className="flex items-center gap-3 text-sm text-[#f8f3e7]/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={patientProfile.heartDiseases}
                      onChange={(e) =>
                        setPatientProfile((prev) => ({ ...prev, heartDiseases: e.target.checked }))
                      }
                      className="h-4 w-4 rounded border border-[#f8f3e7]/30 bg-transparent text-[#eb520a] focus:ring-[#eb520a]"
                    />
                    <span>Choroby serca</span>
                  </label>

                  <label className="flex items-center gap-3 text-sm text-[#f8f3e7]/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={patientProfile.kidneyDiseases}
                      onChange={(e) =>
                        setPatientProfile((prev) => ({ ...prev, kidneyDiseases: e.target.checked }))
                      }
                      className="h-4 w-4 rounded border border-[#f8f3e7]/30 bg-transparent text-[#eb520a] focus:ring-[#eb520a]"
                    />
                    <span>Choroby nerek</span>
                  </label>

                  <label className="flex items-center gap-3 text-sm text-[#f8f3e7]/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={patientProfile.diabetes}
                      onChange={(e) =>
                        setPatientProfile((prev) => ({ ...prev, diabetes: e.target.checked }))
                      }
                      className="h-4 w-4 rounded border border-[#f8f3e7]/30 bg-transparent text-[#eb520a] focus:ring-[#eb520a]"
                    />
                    <span>Cukrzyca</span>
                  </label>

                  <label className="flex items-center gap-3 text-sm text-[#f8f3e7]/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={patientProfile.tuberculosis}
                      onChange={(e) =>
                        setPatientProfile((prev) => ({ ...prev, tuberculosis: e.target.checked }))
                      }
                      className="h-4 w-4 rounded border border-[#f8f3e7]/30 bg-transparent text-[#eb520a] focus:ring-[#eb520a]"
                    />
                    <span>Gruźlica</span>
                  </label>

                  <label className="flex items-center gap-3 text-sm text-[#f8f3e7]/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={patientProfile.rheumaticDisease}
                      onChange={(e) =>
                        setPatientProfile((prev) => ({
                          ...prev,
                          rheumaticDisease: e.target.checked,
                        }))
                      }
                      className="h-4 w-4 rounded border border-[#f8f3e7]/30 bg-transparent text-[#eb520a] focus:ring-[#eb520a]"
                    />
                    <span>Choroba reumatyczna</span>
                  </label>

                  <label className="flex items-center gap-3 text-sm text-[#f8f3e7]/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={patientProfile.bloodClottingDisorders}
                      onChange={(e) =>
                        setPatientProfile((prev) => ({
                          ...prev,
                          bloodClottingDisorders: e.target.checked,
                        }))
                      }
                      className="h-4 w-4 rounded border border-[#f8f3e7]/30 bg-transparent text-[#eb520a] focus:ring-[#eb520a]"
                    />
                    <span>Zaburzenia krzepnięcia krwi</span>
                  </label>

                  <label className="flex items-center gap-3 text-sm text-[#f8f3e7]/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={patientProfile.hormonalDisorders}
                      onChange={(e) =>
                        setPatientProfile((prev) => ({
                          ...prev,
                          hormonalDisorders: e.target.checked,
                        }))
                      }
                      className="h-4 w-4 rounded border border-[#f8f3e7]/30 bg-transparent text-[#eb520a] focus:ring-[#eb520a]"
                    />
                    <span>Zaburzenia hormonalne</span>
                  </label>

                  <label className="flex items-center gap-3 text-sm text-[#f8f3e7]/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={patientProfile.porphyria}
                      onChange={(e) =>
                        setPatientProfile((prev) => ({ ...prev, porphyria: e.target.checked }))
                      }
                      className="h-4 w-4 rounded border border-[#f8f3e7]/30 bg-transparent text-[#eb520a] focus:ring-[#eb520a]"
                    />
                    <span>Porfiria</span>
                  </label>

                  <label className="flex items-center gap-3 text-sm text-[#f8f3e7]/80 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={patientProfile.thyroidDiseases}
                      onChange={(e) =>
                        setPatientProfile((prev) => ({
                          ...prev,
                          thyroidDiseases: e.target.checked,
                        }))
                      }
                      className="h-4 w-4 rounded border border-[#f8f3e7]/30 bg-transparent text-[#eb520a] focus:ring-[#eb520a]"
                    />
                    <span>Choroby tarczycy</span>
                  </label>
                </div>

                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Żółtaczka - kiedy?
                  </label>
                  <input
                    type="text"
                    value={patientProfile.jaundice}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, jaundice: e.target.value }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                    placeholder="Np. 2010, brak"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Nadciśnienie - jakie leki?
                  </label>
                  <input
                    type="text"
                    value={patientProfile.hypertension}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, hypertension: e.target.value }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                    placeholder="Np. enalapril, brak"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Inne schorzenia
                  </label>
                  <input
                    type="text"
                    value={patientProfile.otherDiseases}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, otherDiseases: e.target.value }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                    placeholder="Np. brak, migreny"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-[#f8f3e7]/80 mb-2">
                    Zażywa obecnie leki
                  </label>
                  <textarea
                    rows={3}
                    value={patientProfile.currentMedications}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({
                        ...prev,
                        currentMedications: e.target.value,
                      }))
                    }
                    className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a] focus:ring-2 focus:ring-[#eb520a]/20"
                    placeholder="Wymień wszystkie przyjmowane leki, dawki i częstotliwość. Np. brak, lub: Metformina 500mg 2x dziennie"
                  />
                </div>
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
                href="/sign-in"
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

