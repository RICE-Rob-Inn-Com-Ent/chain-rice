"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, Save, RefreshCw } from "lucide-react";

export default function NewUserPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [formData, setFormData] = useState({
    email: "",
    password: "",
    firstName: "",
    lastName: "",
    role: "user",
    phone: "",
  });

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
    documentsInfo: "",
    consentAccepted: false,
    authorizedPerson: "",
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

  const inputClass =
    "w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20";

  // Generate secure password
  const generatePassword = (): string => {
    const length = 16;
    const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*";
    let password = "";
    if (typeof window !== "undefined" && window.crypto) {
      const array = new Uint32Array(length);
      window.crypto.getRandomValues(array);
      password = Array.from(array)
        .map((x) => charset[x % charset.length])
        .join("");
    } else {
      // Fallback for older browsers
      for (let i = 0; i < length; i++) {
        password += charset.charAt(Math.floor(Math.random() * charset.length));
      }
    }
    return password;
  };

  // Generate password on mount
  useEffect(() => {
    if (!formData.password) {
      setFormData((prev) => ({ ...prev, password: generatePassword() }));
    }
  }, []);

  const handleGeneratePassword = () => {
    setFormData((prev) => ({ ...prev, password: generatePassword() }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      // Validate required fields
      if (!formData.phone) {
        setError("Numer telefonu jest wymagany.");
        setLoading(false);
        return;
      }

      // Validate patient profile fields if role is 'user'
      if (formData.role === "user") {
        if (!patientProfile.consentAccepted) {
          setError("Musisz wyrazić zgodę na przetwarzanie danych medycznych.");
          setLoading(false);
          return;
        }
      }

      // Generate displayName from firstName and lastName, or use email as fallback
      const displayName =
        formData.firstName || formData.lastName
          ? `${formData.firstName || ""} ${formData.lastName || ""}`.trim()
          : formData.email;

      const res = await fetch("/api/users", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: formData.email,
          password: formData.password,
          displayName: displayName,
          firstName: formData.firstName || null,
          lastName: formData.lastName || null,
          phone: formData.phone || null,
          role: formData.role,
          patientProfile: {
            pesel: patientProfile.pesel || null,
            peselStatus: patientProfile.peselStatus || null,
            childNumber: patientProfile.childNumber || null,
            dateOfBirth: patientProfile.dateOfBirth || null,
            gender: patientProfile.gender || null,
            nfzBranch: patientProfile.nfzBranch || null,
            insuranceEntitlement: patientProfile.insuranceEntitlement || null,
            insuranceConfirmationStatus: patientProfile.insuranceConfirmationStatus || null,
            additionalEntitlements: patientProfile.additionalEntitlements || null,
            ekuNumber: patientProfile.ekuNumber || null,
            euPatientNumber: patientProfile.euPatientNumber || null,
            maidenName: patientProfile.maidenName || null,
            fatherName: patientProfile.fatherName || null,
            motherName: patientProfile.motherName || null,
            authorizedPerson: patientProfile.authorizedPerson || null,
            documentsInfo: patientProfile.documentsInfo || null,
            consentAccepted: patientProfile.consentAccepted || false,
            // Medical history
            allergies: patientProfile.allergies || null,
            asthma: patientProfile.asthma || false,
            jaundice: patientProfile.jaundice || null,
            hypertension: patientProfile.hypertension || null,
            heartDiseases: patientProfile.heartDiseases || false,
            kidneyDiseases: patientProfile.kidneyDiseases || false,
            diabetes: patientProfile.diabetes || false,
            tuberculosis: patientProfile.tuberculosis || false,
            rheumaticDisease: patientProfile.rheumaticDisease || false,
            bloodClottingDisorders: patientProfile.bloodClottingDisorders || false,
            hormonalDisorders: patientProfile.hormonalDisorders || false,
            porphyria: patientProfile.porphyria || false,
            thyroidDiseases: patientProfile.thyroidDiseases || false,
            otherDiseases: patientProfile.otherDiseases || null,
            currentMedications: patientProfile.currentMedications || null,
            treatmentConsent: patientProfile.treatmentConsent || false,
          },
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Błąd podczas tworzenia użytkownika");
        setLoading(false);
        return;
      }

      router.push("/admin/users");
    } catch (err) {
      setError("Wystąpił błąd. Spróbuj ponownie.");
      setLoading(false);
    }
  };

  return (
    <div>
      <div className="mb-8 flex items-center justify-between">
        <div>
          <Link
            href="/admin/users"
            className="mb-4 inline-flex items-center gap-2 text-ivory-100/60 hover:text-ivory-100"
          >
            <ArrowLeft className="h-4 w-4" />
            Powrót do listy
          </Link>
          <h1 className="font-display text-4xl text-ivory-100">Nowy użytkownik</h1>
          <p className="mt-2 text-ivory-100/70">Dodaj nowego użytkownika do systemu</p>
        </div>
      </div>

      <div className="marble-card p-6">
        {error && (
          <div className="mb-6 rounded-lg bg-red-500/20 border border-red-500/50 p-4 text-red-400">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          {/* 1. Dane podstawowe */}
          <div className="space-y-4 border-b border-white/10 pb-6">
            <div>
              <p className="text-xs uppercase tracking-[0.3em] text-ivory-100/40">1. Dane podstawowe</p>
              <h3 className="text-lg font-semibold text-ivory-100">Dane osobowe</h3>
            </div>
            <div className="grid md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  Email <span className="text-ember-400">*</span>
                </label>
                <input
                  type="email"
                  required
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  className={inputClass}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  Hasło <span className="text-ember-400">*</span>
                </label>
                <div className="relative">
                  <input
                    type="password"
                    required
                    minLength={8}
                    value={formData.password}
                    onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                    className={inputClass}
                  />
                  <button
                    type="button"
                    onClick={handleGeneratePassword}
                    className="absolute right-2 top-1/2 -translate-y-1/2 p-1.5 rounded-lg hover:bg-white/10 text-ivory-100/60 hover:text-ivory-100 transition-colors"
                    title="Wygeneruj nowe hasło"
                  >
                    <RefreshCw className="h-4 w-4" />
                  </button>
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  Rola <span className="text-ember-400">*</span>
                </label>
                <select
                  required
                  value={formData.role}
                  onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                  className={inputClass}
                >
                  <option value="user">Pacjent</option>
                  <option value="doctor">Lekarz</option>
                  <option value="admin">Administrator</option>
                  <option value="owner">Właściciel</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  Imię <span className="text-ember-400">*</span>
                </label>
                <input
                  type="text"
                  required
                  value={formData.firstName}
                  onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                  className={inputClass}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  Nazwisko <span className="text-ember-400">*</span>
                </label>
                <input
                  type="text"
                  required
                  value={formData.lastName}
                  onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                  className={inputClass}
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  PESEL <span className="text-ember-400">*</span>
                </label>
                <input
                  type="text"
                  maxLength={11}
                  value={patientProfile.pesel}
                  onChange={(e) =>
                    setPatientProfile((prev) => ({
                      ...prev,
                      pesel: e.target.value.replace(/\D/g, "").slice(0, 11),
                    }))
                  }
                  required
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  Data urodzenia <span className="text-ember-400">*</span>
                </label>
                <input
                  type="date"
                  value={patientProfile.dateOfBirth}
                  onChange={(e) =>
                    setPatientProfile((prev) => ({ ...prev, dateOfBirth: e.target.value }))
                  }
                  required
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  Płeć <span className="text-ember-400">*</span>
                </label>
                <select
                  value={patientProfile.gender}
                  onChange={(e) =>
                    setPatientProfile((prev) => ({ ...prev, gender: e.target.value }))
                  }
                  required
                  className={inputClass}
                >
                  <option value="">Wybierz</option>
                  <option value="F">Kobieta</option>
                  <option value="M">Mężczyzna</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  Numer telefonu <span className="text-ember-400">*</span>
                </label>
                <input
                  type="tel"
                  required
                  value={formData.phone}
                  onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                  className={inputClass}
                  placeholder="+48 123 456 789"
                />
              </div>
            </div>
          </div>

          {/* 2. Historia medyczna */}
          {formData.role === "user" && (
          <div className="space-y-4 border-b border-white/10 pb-6">
            <div>
              <p className="text-xs uppercase tracking-[0.3em] text-ivory-100/40">
                2. Historia medyczna
              </p>
              <h3 className="text-lg font-semibold text-ivory-100">
                Schorzenia (obecne, przebyte) i leki
              </h3>
            </div>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  Alergie - na co?
                </label>
                <input
                  type="text"
                  value={patientProfile.allergies}
                  onChange={(e) =>
                    setPatientProfile((prev) => ({ ...prev, allergies: e.target.value }))
                  }
                  className={inputClass}
                  placeholder="Np. penicylina, jad owadów"
                />
              </div>

              <div className="grid md:grid-cols-2 gap-4">
                <label className="flex items-center gap-3 text-sm text-ivory-100/80 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={patientProfile.asthma}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, asthma: e.target.checked }))
                    }
                    className="h-4 w-4 rounded border border-white/30 bg-transparent text-ember-400 focus:ring-ember-400"
                  />
                  <span>Astma</span>
                </label>

                <label className="flex items-center gap-3 text-sm text-ivory-100/80 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={patientProfile.heartDiseases}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, heartDiseases: e.target.checked }))
                    }
                    className="h-4 w-4 rounded border border-white/30 bg-transparent text-ember-400 focus:ring-ember-400"
                  />
                  <span>Choroby serca</span>
                </label>

                <label className="flex items-center gap-3 text-sm text-ivory-100/80 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={patientProfile.kidneyDiseases}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, kidneyDiseases: e.target.checked }))
                    }
                    className="h-4 w-4 rounded border border-white/30 bg-transparent text-ember-400 focus:ring-ember-400"
                  />
                  <span>Choroby nerek</span>
                </label>

                <label className="flex items-center gap-3 text-sm text-ivory-100/80 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={patientProfile.diabetes}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, diabetes: e.target.checked }))
                    }
                    className="h-4 w-4 rounded border border-white/30 bg-transparent text-ember-400 focus:ring-ember-400"
                  />
                  <span>Cukrzyca</span>
                </label>

                <label className="flex items-center gap-3 text-sm text-ivory-100/80 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={patientProfile.tuberculosis}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, tuberculosis: e.target.checked }))
                    }
                    className="h-4 w-4 rounded border border-white/30 bg-transparent text-ember-400 focus:ring-ember-400"
                  />
                  <span>Gruźlica</span>
                </label>

                <label className="flex items-center gap-3 text-sm text-ivory-100/80 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={patientProfile.rheumaticDisease}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, rheumaticDisease: e.target.checked }))
                    }
                    className="h-4 w-4 rounded border border-white/30 bg-transparent text-ember-400 focus:ring-ember-400"
                  />
                  <span>Choroba reumatyczna</span>
                </label>

                <label className="flex items-center gap-3 text-sm text-ivory-100/80 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={patientProfile.bloodClottingDisorders}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({
                        ...prev,
                        bloodClottingDisorders: e.target.checked,
                      }))
                    }
                    className="h-4 w-4 rounded border border-white/30 bg-transparent text-ember-400 focus:ring-ember-400"
                  />
                  <span>Zaburzenia krzepnięcia krwi</span>
                </label>

                <label className="flex items-center gap-3 text-sm text-ivory-100/80 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={patientProfile.hormonalDisorders}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({
                        ...prev,
                        hormonalDisorders: e.target.checked,
                      }))
                    }
                    className="h-4 w-4 rounded border border-white/30 bg-transparent text-ember-400 focus:ring-ember-400"
                  />
                  <span>Zaburzenia hormonalne</span>
                </label>

                <label className="flex items-center gap-3 text-sm text-ivory-100/80 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={patientProfile.porphyria}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({ ...prev, porphyria: e.target.checked }))
                    }
                    className="h-4 w-4 rounded border border-white/30 bg-transparent text-ember-400 focus:ring-ember-400"
                  />
                  <span>Porfiria</span>
                </label>

                <label className="flex items-center gap-3 text-sm text-ivory-100/80 cursor-pointer">
                  <input
                    type="checkbox"
                    checked={patientProfile.thyroidDiseases}
                    onChange={(e) =>
                      setPatientProfile((prev) => ({
                        ...prev,
                        thyroidDiseases: e.target.checked,
                      }))
                    }
                    className="h-4 w-4 rounded border border-white/30 bg-transparent text-ember-400 focus:ring-ember-400"
                  />
                  <span>Choroby tarczycy</span>
                </label>
              </div>

              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  Żółtaczka - kiedy?
                </label>
                <input
                  type="text"
                  value={patientProfile.jaundice}
                  onChange={(e) =>
                    setPatientProfile((prev) => ({ ...prev, jaundice: e.target.value }))
                  }
                  className={inputClass}
                  placeholder="Np. 2010, brak"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  Nadciśnienie - jakie leki?
                </label>
                <input
                  type="text"
                  value={patientProfile.hypertension}
                  onChange={(e) =>
                    setPatientProfile((prev) => ({ ...prev, hypertension: e.target.value }))
                  }
                  className={inputClass}
                  placeholder="Np. enalapril, brak"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  Inne schorzenia
                </label>
                <input
                  type="text"
                  value={patientProfile.otherDiseases}
                  onChange={(e) =>
                    setPatientProfile((prev) => ({ ...prev, otherDiseases: e.target.value }))
                  }
                  className={inputClass}
                  placeholder="Np. brak, migreny"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
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
                  className={inputClass}
                  placeholder="Wymień wszystkie przyjmowane leki, dawki i częstotliwość. Np. brak, lub: Metformina 500mg 2x dziennie"
                />
              </div>
            </div>
          </div>
          )}

          {/* 3. Informacje dodatkowe */}
          {formData.role === "user" && (
          <div className="space-y-4 border-b border-white/10 pb-6">
            <div>
              <p className="text-xs uppercase tracking-[0.3em] text-ivory-100/40">
                3. Informacje dodatkowe
              </p>
              <h3 className="text-lg font-semibold text-ivory-100">Rodzina i dokumenty</h3>
            </div>
            <div className="grid md:grid-cols-3 gap-4">
              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">Imię ojca</label>
                <input
                  type="text"
                  value={patientProfile.fatherName}
                  onChange={(e) =>
                    setPatientProfile((prev) => ({ ...prev, fatherName: e.target.value }))
                  }
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">Imię matki</label>
                <input
                  type="text"
                  value={patientProfile.motherName}
                  onChange={(e) =>
                    setPatientProfile((prev) => ({ ...prev, motherName: e.target.value }))
                  }
                  className={inputClass}
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                  Upoważniona osoba do odbierania danych medycznych
                </label>
                <input
                  type="text"
                  value={patientProfile.authorizedPerson}
                  onChange={(e) =>
                    setPatientProfile((prev) => ({ ...prev, authorizedPerson: e.target.value }))
                  }
                  className={inputClass}
                  placeholder="Imię i nazwisko"
                />
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                Dokumenty / uwagi
              </label>
              <textarea
                rows={3}
                value={patientProfile.documentsInfo}
                onChange={(e) =>
                  setPatientProfile((prev) => ({ ...prev, documentsInfo: e.target.value }))
                }
                className={inputClass}
                placeholder="Np. dokumenty potwierdzające uprawnienia"
              />
            </div>
            <label className="flex items-start gap-3 text-sm text-ivory-100/80 cursor-pointer">
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
                className="mt-1 h-4 w-4 rounded border border-white/30 bg-transparent text-ember-400 focus:ring-ember-400"
              />
              <span>
                Wyrażam zgodę na przetwarzanie danych medycznych w celu prowadzenia dokumentacji
                pacjenta i obsługi wizyt. <span className="text-ember-400">*</span>
              </span>
            </label>
          </div>
          )}

          <div className="flex gap-4 pt-4">
            <button
              type="submit"
              disabled={loading}
              className="flex items-center gap-2 rounded-lg bg-ember-500 px-6 py-2 font-semibold text-white transition hover:bg-ember-600 disabled:opacity-50"
            >
              <Save className="h-5 w-5" />
              {loading ? "Zapisywanie..." : "Zapisz użytkownika"}
            </button>
            <Link
              href="/admin/users"
              className="rounded-lg border border-white/10 bg-white/5 px-6 py-2 font-semibold text-ivory-100 transition hover:bg-white/10"
            >
              Anuluj
            </Link>
          </div>
        </form>
      </div>
    </div>
  );
}
