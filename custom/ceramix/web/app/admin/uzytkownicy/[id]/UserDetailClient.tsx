"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft, Mail, Phone, Edit, Save, X } from "lucide-react";
import { useState } from "react";
import DentalChart from "../../components/DentalChart";

type PatientProfile = {
  pesel: string | null;
  date_of_birth: string | null;
  gender: string | null;
  pesel_status: string | null;
  child_number: string | null;
  nfz_branch: string | null;
  insurance_entitlement: string | null;
  insurance_confirmation_status: string | null;
  insurance_additional_entitlements: string | null;
  eku_number: string | null;
  eu_patient_number: string | null;
  maiden_name: string | null;
  father_name: string | null;
  mother_name: string | null;
  authorized_person: string | null;
  documents_info: string | null;
  consent_accepted: boolean | null;
  allergies: string | null;
  asthma: boolean | null;
  jaundice: string | null;
  hypertension: string | null;
  heart_diseases: boolean | null;
  kidney_diseases: boolean | null;
  diabetes: boolean | null;
  tuberculosis: boolean | null;
  rheumatic_disease: boolean | null;
  blood_clotting_disorders: boolean | null;
  hormonal_disorders: boolean | null;
  porphyria: boolean | null;
  thyroid_diseases: boolean | null;
  other_diseases: string | null;
  current_medications: string | null;
  treatment_consent: boolean | null;
};

type UserDetailClientProps = {
  user: {
    id: string;
    email: string;
    display_name: string;
    first_name: string | null;
    last_name: string | null;
    patient_number: string | null;
    phone: string | null;
    role: string;
    active: boolean;
    email_verified: boolean;
    phone_verified: boolean;
    created_at: Date;
    last_login_at: Date | null;
    patientProfile: PatientProfile | null;
  };
  isSuperadmin: boolean;
};

function VerificationButton({
  userId,
  type,
  verified,
}: {
  userId: string;
  type: "email" | "sms";
  verified: boolean;
}) {
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [codeSent, setCodeSent] = useState(false);
  const [verificationCode, setVerificationCode] = useState("");

  const handleSendCode = async () => {
    setLoading(true);
    setMessage("");
    setCodeSent(false);

    try {
      const res = await fetch(`/api/users/${userId}/verify`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ type }),
      });

      const data = await res.json();

      if (!res.ok) {
        setMessage(data.error || "Błąd podczas wysyłania kodu");
        setLoading(false);
        return;
      }

      setCodeSent(true);
      if (data.code) {
        // In development, show the code
        setVerificationCode(data.code);
      }
      setMessage(data.message || "Kod został wysłany");
      setLoading(false);
    } catch (error: any) {
      setMessage("Wystąpił błąd. Spróbuj ponownie.");
      setLoading(false);
    }
  };

  const handleVerifyCode = async () => {
    if (!verificationCode) {
      setMessage("Wprowadź kod weryfikacyjny");
      return;
    }

    setLoading(true);
    setMessage("");

    try {
      const res = await fetch(`/api/users/${userId}/verify`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ type, code: verificationCode }),
      });

      const data = await res.json();

      if (!res.ok) {
        setMessage(data.error || "Błąd podczas weryfikacji");
        setLoading(false);
        return;
      }

      setMessage(data.message || "Weryfikacja zakończona pomyślnie");
      setCodeSent(false);
      setVerificationCode("");
      setTimeout(() => {
        window.location.reload(); // Refresh to show updated status
      }, 1000);
    } catch (error: any) {
      setMessage("Wystąpił błąd. Spróbuj ponownie.");
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col sm:flex-row items-start sm:items-center gap-2 w-full sm:w-auto">
      <div className="flex items-center gap-2">
        {type === "email" ? (
          <Mail className="h-4 w-4 text-ivory-100/60 flex-shrink-0" />
        ) : (
          <Phone className="h-4 w-4 text-ivory-100/60 flex-shrink-0" />
        )}
        {verified && (
          <span className="text-xs text-green-400 whitespace-nowrap">Zweryfikowany</span>
        )}
      </div>
      <div className="flex flex-col sm:flex-row items-start sm:items-center gap-2 w-full sm:w-auto">
        {!codeSent ? (
          <button
            onClick={handleSendCode}
            disabled={loading}
            className="px-3 py-1 text-xs rounded-lg bg-amber-500 hover:bg-amber-600 text-white disabled:opacity-50 whitespace-nowrap w-full sm:w-auto"
          >
            {loading ? "Wysyłanie..." : verified ? "Wyślij ponownie" : "Wyślij kod"}
          </button>
        ) : (
          <div className="flex flex-col sm:flex-row items-start sm:items-center gap-2 w-full sm:w-auto">
            <input
              type="text"
              value={verificationCode}
              onChange={(e) => setVerificationCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
              placeholder="Kod (6 cyfr)"
              className="px-2 py-1 text-xs rounded-lg border border-white/10 bg-white/5 text-ivory-100 w-full sm:w-24 focus:border-amber-400 focus:outline-none"
              maxLength={6}
            />
            <div className="flex gap-2 w-full sm:w-auto">
              <button
                onClick={handleVerifyCode}
                disabled={loading || !verificationCode}
                className="px-3 py-1 text-xs rounded-lg bg-green-500 hover:bg-green-600 text-white disabled:opacity-50 whitespace-nowrap flex-1 sm:flex-initial"
              >
                {loading ? "Weryfikowanie..." : "Zweryfikuj"}
              </button>
              <button
                onClick={() => {
                  setCodeSent(false);
                  setVerificationCode("");
                  setMessage("");
                }}
                className="px-2 py-1 text-xs rounded-lg border border-white/10 bg-white/5 text-ivory-100 hover:bg-white/10 whitespace-nowrap"
              >
                Anuluj
              </button>
            </div>
          </div>
        )}
      </div>
      {message && (
        <span className="text-xs text-amber-400 w-full sm:w-auto">{message}</span>
      )}
    </div>
  );
}

export default function UserDetailClient({ user, isSuperadmin }: UserDetailClientProps) {
  const router = useRouter();
  const [isEditing, setIsEditing] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [editData, setEditData] = useState({
    email: user.email,
    first_name: user.first_name || "",
    last_name: user.last_name || "",
    phone: user.phone || "",
    active: user.active,
  });
  const [editProfileData, setEditProfileData] = useState({
    allergies: user.patientProfile?.allergies || "",
    asthma: user.patientProfile?.asthma || false,
    jaundice: user.patientProfile?.jaundice || "",
    hypertension: user.patientProfile?.hypertension || "",
    heart_diseases: user.patientProfile?.heart_diseases || false,
    kidney_diseases: user.patientProfile?.kidney_diseases || false,
    diabetes: user.patientProfile?.diabetes || false,
    tuberculosis: user.patientProfile?.tuberculosis || false,
    rheumatic_disease: user.patientProfile?.rheumatic_disease || false,
    blood_clotting_disorders: user.patientProfile?.blood_clotting_disorders || false,
    hormonal_disorders: user.patientProfile?.hormonal_disorders || false,
    porphyria: user.patientProfile?.porphyria || false,
    thyroid_diseases: user.patientProfile?.thyroid_diseases || false,
    other_diseases: user.patientProfile?.other_diseases || "",
    current_medications: user.patientProfile?.current_medications || "",
    father_name: user.patientProfile?.father_name || "",
    mother_name: user.patientProfile?.mother_name || "",
    maiden_name: user.patientProfile?.maiden_name || "",
    authorized_person: user.patientProfile?.authorized_person || "",
    documents_info: user.patientProfile?.documents_info || "",
  });

  const handleSave = async () => {
    setIsSaving(true);
    try {
      const res = await fetch(`/api/users/${user.id}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: editData.email,
          firstName: editData.first_name,
          lastName: editData.last_name,
          phone: editData.phone || null,
          active: editData.active,
          patientProfile: {
            allergies: editProfileData.allergies || null,
            asthma: editProfileData.asthma || false,
            jaundice: editProfileData.jaundice || null,
            hypertension: editProfileData.hypertension || null,
            heartDiseases: editProfileData.heart_diseases || false,
            kidneyDiseases: editProfileData.kidney_diseases || false,
            diabetes: editProfileData.diabetes || false,
            tuberculosis: editProfileData.tuberculosis || false,
            rheumaticDisease: editProfileData.rheumatic_disease || false,
            bloodClottingDisorders: editProfileData.blood_clotting_disorders || false,
            hormonalDisorders: editProfileData.hormonal_disorders || false,
            porphyria: editProfileData.porphyria || false,
            thyroidDiseases: editProfileData.thyroid_diseases || false,
            otherDiseases: editProfileData.other_diseases || null,
            currentMedications: editProfileData.current_medications || null,
            fatherName: editProfileData.father_name || null,
            motherName: editProfileData.mother_name || null,
            maidenName: editProfileData.maiden_name || null,
            authorizedPerson: editProfileData.authorized_person || null,
            documentsInfo: editProfileData.documents_info || null,
          },
        }),
      });

      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error || "Nie udało się zapisać zmian");
      }

      setIsEditing(false);
      router.refresh();
    } catch (error: any) {
      alert(error.message || "Wystąpił błąd podczas zapisywania");
    } finally {
      setIsSaving(false);
    }
  };

  const handleCancel = () => {
    setEditData({
      email: user.email,
      first_name: user.first_name || "",
      last_name: user.last_name || "",
      phone: user.phone || "",
      active: user.active,
    });
    setEditProfileData({
      allergies: user.patientProfile?.allergies || "",
      asthma: user.patientProfile?.asthma || false,
      jaundice: user.patientProfile?.jaundice || "",
      hypertension: user.patientProfile?.hypertension || "",
      heart_diseases: user.patientProfile?.heart_diseases || false,
      kidney_diseases: user.patientProfile?.kidney_diseases || false,
      diabetes: user.patientProfile?.diabetes || false,
      tuberculosis: user.patientProfile?.tuberculosis || false,
      rheumatic_disease: user.patientProfile?.rheumatic_disease || false,
      blood_clotting_disorders: user.patientProfile?.blood_clotting_disorders || false,
      hormonal_disorders: user.patientProfile?.hormonal_disorders || false,
      porphyria: user.patientProfile?.porphyria || false,
      thyroid_diseases: user.patientProfile?.thyroid_diseases || false,
      other_diseases: user.patientProfile?.other_diseases || "",
      current_medications: user.patientProfile?.current_medications || "",
      father_name: user.patientProfile?.father_name || "",
      mother_name: user.patientProfile?.mother_name || "",
      maiden_name: user.patientProfile?.maiden_name || "",
      authorized_person: user.patientProfile?.authorized_person || "",
      documents_info: user.patientProfile?.documents_info || "",
    });
    setIsEditing(false);
  };

  return (
    <div className="space-y-6 w-full animate-fade-in">
      <style jsx>{`
        @keyframes fade-in {
          from {
            opacity: 0;
            transform: translateY(8px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
        .animate-fade-in {
          animation: fade-in 0.3s ease-out;
        }
        @keyframes slide-in {
          from {
            opacity: 0;
            transform: translateX(-8px);
          }
          to {
            opacity: 1;
            transform: translateX(0);
          }
        }
        .animate-slide-in {
          animation: slide-in 0.2s ease-out;
        }
      `}</style>
      
      {/* Back Button */}
      <div className="animate-slide-in">
        <Link
          href="/admin/uzytkownicy"
          className="inline-flex items-center gap-2 text-ivory-100/70 hover:text-ivory-100 transition-colors duration-200 text-sm md:text-base group"
        >
          <ArrowLeft className="h-4 w-4 md:h-5 md:w-5 transition-transform duration-200 group-hover:-translate-x-1" />
          <span className="hidden sm:inline">Powrót do listy użytkowników</span>
          <span className="sm:hidden">Powrót</span>
        </Link>
      </div>

      {/* Patient Card - All in one */}
      <div className="marble-card p-4 sm:p-6 md:p-8 w-full max-w-[95%] mx-auto overflow-hidden shadow-lg transition-all duration-300 hover:shadow-xl">
        {/* Header Section */}
        <div className="mb-6 md:mb-8 flex items-center gap-4 pb-6 border-b border-white/10">
          {isEditing ? (
            <div className="flex flex-col sm:flex-row gap-3 flex-1 animate-fade-in">
              <input
                type="text"
                value={editData.first_name}
                onChange={(e) => setEditData({ ...editData, first_name: e.target.value })}
                placeholder="Imię"
                className="flex-1 px-4 py-3 rounded-xl border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-xl md:text-2xl lg:text-3xl font-bold transition-all duration-200"
                autoFocus
              />
              <input
                type="text"
                value={editData.last_name}
                onChange={(e) => setEditData({ ...editData, last_name: e.target.value })}
                placeholder="Nazwisko"
                className="flex-1 px-4 py-3 rounded-xl border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-xl md:text-2xl lg:text-3xl font-bold transition-all duration-200"
              />
            </div>
          ) : (
            <h1 className="text-2xl md:text-3xl lg:text-4xl font-bold text-ivory-100 break-words flex-1 leading-tight">{user.display_name}</h1>
          )}
          {isSuperadmin && (
            <div className="flex items-center gap-2 flex-shrink-0">
              {!isEditing ? (
                <button
                  onClick={() => setIsEditing(true)}
                  className="p-2.5 rounded-xl bg-amber-500 hover:bg-amber-600 text-white transition-all duration-200 hover:scale-105 active:scale-95 shadow-md hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-amber-400/50"
                  title="Edytuj"
                  aria-label="Edytuj dane użytkownika"
                >
                  <Edit className="h-5 w-5" />
                </button>
              ) : (
                <>
                  <button
                    onClick={handleSave}
                    disabled={isSaving}
                    className="p-2.5 rounded-xl bg-green-500 hover:bg-green-600 text-white transition-all duration-200 hover:scale-105 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100 shadow-md hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-green-400/50"
                    title={isSaving ? "Zapisywanie..." : "Zapisz"}
                    aria-label={isSaving ? "Zapisywanie..." : "Zapisz zmiany"}
                  >
                    <Save className="h-5 w-5" />
                  </button>
                  <button
                    onClick={handleCancel}
                    disabled={isSaving}
                    className="p-2.5 rounded-xl border-2 border-white/20 bg-white/5 hover:bg-white/10 text-ivory-100 transition-all duration-200 hover:scale-105 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100 focus:outline-none focus:ring-2 focus:ring-white/30"
                    title="Anuluj"
                    aria-label="Anuluj edycję"
                  >
                    <X className="h-5 w-5" />
                  </button>
                </>
              )}
            </div>
          )}
        </div>

        {/* Content Section */}
        <div className="space-y-6">
            {/* All information in one grid - side by side */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 md:gap-6">
              {/* Kontakt - Email i Telefon z weryfikacją */}
              <div className="bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Kontakt</h3>
                {isEditing ? (
                  <div className="flex flex-col gap-2">
                    <input
                      type="email"
                      value={editData.email}
                      onChange={(e) => setEditData({ ...editData, email: e.target.value })}
                      className="w-full px-3 py-2.5 rounded-lg border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-sm transition-all duration-200"
                      placeholder="Email"
                    />
                    <input
                      type="tel"
                      value={editData.phone}
                      onChange={(e) => setEditData({ ...editData, phone: e.target.value })}
                      className="w-full px-3 py-2.5 rounded-lg border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-sm transition-all duration-200"
                      placeholder="Numer telefonu"
                    />
                  </div>
                ) : (
                  <div className="space-y-2">
                    <div className="flex items-center gap-2">
                      <span className={`text-sm font-medium ${
                        user.email_verified ? "text-green-400" : "text-red-400"
                      }`}>
                        {user.email_verified ? "✓" : "✗"}
                      </span>
                      <p className="text-ivory-100/70 break-all text-sm flex-1">{user.email}</p>
                      {isSuperadmin && (
                        <div className="flex-shrink-0">
                          <VerificationButton userId={user.id} type="email" verified={user.email_verified} />
                        </div>
                      )}
                    </div>
                    {user.phone && (
                      <div className="flex items-center gap-2">
                        <span className={`text-sm font-medium ${
                          user.phone_verified ? "text-green-400" : "text-red-400"
                        }`}>
                          {user.phone_verified ? "✓" : "✗"}
                        </span>
                        <p className="text-ivory-100/70 text-sm flex-1">{user.phone}</p>
                        {isSuperadmin && (
                          <div className="flex-shrink-0">
                            <VerificationButton userId={user.id} type="sms" verified={user.phone_verified} />
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* Patient Number */}
              {user.patient_number && (
                <div className="bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                  <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Numer pacjenta</h3>
                  <p className="text-ivory-100/90 text-sm font-medium">{user.patient_number}</p>
                </div>
              )}

              {/* Rola */}
              <div className="bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Rola</h3>
                <p className="text-ivory-100/90 text-sm font-medium">{user.role}</p>
              </div>

              {/* Status */}
              <div className="bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Status</h3>
                {isEditing ? (
                  <label className="flex items-center gap-3 cursor-pointer group">
                    <input
                      type="checkbox"
                      checked={editData.active}
                      onChange={(e) => setEditData({ ...editData, active: e.target.checked })}
                      className="w-5 h-5 rounded border-2 border-white/20 bg-white/5 text-amber-500 focus:ring-2 focus:ring-amber-400/50 transition-all duration-200 cursor-pointer"
                    />
                    <span className="text-ivory-100/90 text-sm font-medium group-hover:text-ivory-100 transition-colors">
                      {editData.active ? "Aktywny" : "Nieaktywny"}
                    </span>
                  </label>
                ) : (
                  <div className="flex items-center gap-2">
                    <span className={`w-2 h-2 rounded-full ${user.active ? "bg-green-400" : "bg-red-400"}`}></span>
                    <p className="text-ivory-100/90 text-sm font-medium">{user.active ? "Aktywny" : "Nieaktywny"}</p>
                  </div>
                )}
              </div>

              {/* Alergie */}
              <div className="bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Alergie</h3>
                {isEditing ? (
                  <input
                    type="text"
                    value={editProfileData.allergies}
                    onChange={(e) => setEditProfileData({ ...editProfileData, allergies: e.target.value })}
                    className="w-full px-3 py-2.5 rounded-lg border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-sm transition-all duration-200"
                    placeholder="Np. penicylina"
                  />
                ) : (
                  <p className="text-ivory-100/90 text-sm font-medium">
                    {user.patientProfile?.allergies || "Brak"}
                  </p>
                )}
              </div>

              {/* Imię ojca */}
              <div className="bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Imię ojca</h3>
                {isEditing ? (
                  <input
                    type="text"
                    value={editProfileData.father_name}
                    onChange={(e) => setEditProfileData({ ...editProfileData, father_name: e.target.value })}
                    className="w-full px-3 py-2.5 rounded-lg border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-sm transition-all duration-200"
                  />
                ) : (
                  <p className="text-ivory-100/90 text-sm font-medium">
                    {user.patientProfile?.father_name || "Brak"}
                  </p>
                )}
              </div>

              {/* Imię matki */}
              <div className="bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Imię matki</h3>
                {isEditing ? (
                  <input
                    type="text"
                    value={editProfileData.mother_name}
                    onChange={(e) => setEditProfileData({ ...editProfileData, mother_name: e.target.value })}
                    className="w-full px-3 py-2.5 rounded-lg border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-sm transition-all duration-200"
                  />
                ) : (
                  <p className="text-ivory-100/90 text-sm font-medium">
                    {user.patientProfile?.mother_name || "Brak"}
                  </p>
                )}
              </div>

              {/* Schorzenia - jako jedna kolumna */}
              <div className="md:col-span-2 lg:col-span-3 xl:col-span-4 bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-4 uppercase tracking-wide">Schorzenia</h3>
                <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3">
                  {[
                    { key: "asthma", label: "Astma" },
                    { key: "heart_diseases", label: "Choroby serca" },
                    { key: "kidney_diseases", label: "Choroby nerek" },
                    { key: "diabetes", label: "Cukrzyca" },
                    { key: "tuberculosis", label: "Gruźlica" },
                    { key: "rheumatic_disease", label: "Choroba reumatyczna" },
                    { key: "blood_clotting_disorders", label: "Zaburzenia krzepnięcia" },
                    { key: "hormonal_disorders", label: "Zaburzenia hormonalne" },
                    { key: "porphyria", label: "Porfiria" },
                    { key: "thyroid_diseases", label: "Choroby tarczycy" },
                  ].map(({ key, label }) => {
                    const value = isEditing 
                      ? editProfileData[key as keyof typeof editProfileData] as boolean
                      : user.patientProfile?.[key as keyof typeof user.patientProfile] as boolean;
                    return (
                      <div key={key} className="flex items-center gap-2 p-2 rounded-lg hover:bg-white/5 transition-colors duration-150">
                        {isEditing ? (
                          <label className="flex items-center gap-2 cursor-pointer flex-1 group">
                            <input
                              type="checkbox"
                              checked={value || false}
                              onChange={(e) => setEditProfileData({ ...editProfileData, [key]: e.target.checked })}
                              className="w-4 h-4 rounded border-2 border-white/20 bg-white/5 text-amber-500 focus:ring-2 focus:ring-amber-400/50 transition-all duration-200 cursor-pointer"
                            />
                            <span className="text-ivory-100/80 text-xs group-hover:text-ivory-100 transition-colors">{label}</span>
                          </label>
                        ) : (
                          <>
                            <span className={`text-base font-semibold ${
                              value ? "text-green-400" : "text-red-400"
                            }`}>
                              {value ? "✓" : "✗"}
                            </span>
                            <span className="text-ivory-100/80 text-xs">{label}</span>
                          </>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Żółtaczka */}
              {isEditing || user.patientProfile?.jaundice ? (
                <div className="bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                  <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Żółtaczka</h3>
                  {isEditing ? (
                    <input
                      type="text"
                      value={editProfileData.jaundice}
                      onChange={(e) => setEditProfileData({ ...editProfileData, jaundice: e.target.value })}
                      className="w-full px-3 py-2.5 rounded-lg border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-sm transition-all duration-200"
                      placeholder="Np. 2010"
                    />
                  ) : (
                    user.patientProfile?.jaundice && (
                      <p className="text-ivory-100/90 text-sm font-medium">{user.patientProfile.jaundice}</p>
                    )
                  )}
                </div>
              ) : null}

              {/* Nadciśnienie */}
              {isEditing || user.patientProfile?.hypertension ? (
                <div className="bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                  <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Nadciśnienie</h3>
                  {isEditing ? (
                    <input
                      type="text"
                      value={editProfileData.hypertension}
                      onChange={(e) => setEditProfileData({ ...editProfileData, hypertension: e.target.value })}
                      className="w-full px-3 py-2.5 rounded-lg border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-sm transition-all duration-200"
                      placeholder="Np. enalapril"
                    />
                  ) : (
                    user.patientProfile?.hypertension && (
                      <p className="text-ivory-100/90 text-sm font-medium">{user.patientProfile.hypertension}</p>
                    )
                  )}
                </div>
              ) : null}

              {/* Inne schorzenia */}
              {isEditing || user.patientProfile?.other_diseases ? (
                <div className="bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                  <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Inne schorzenia</h3>
                  {isEditing ? (
                    <input
                      type="text"
                      value={editProfileData.other_diseases}
                      onChange={(e) => setEditProfileData({ ...editProfileData, other_diseases: e.target.value })}
                      className="w-full px-3 py-2.5 rounded-lg border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-sm transition-all duration-200"
                      placeholder="Np. migreny"
                    />
                  ) : (
                    user.patientProfile?.other_diseases && (
                      <p className="text-ivory-100/90 text-sm font-medium">{user.patientProfile.other_diseases}</p>
                    )
                  )}
                </div>
              ) : null}

              {/* Leki */}
              <div className="md:col-span-2 lg:col-span-3 xl:col-span-4 bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Zażywa obecnie leki</h3>
                {isEditing ? (
                  <textarea
                    rows={3}
                    value={editProfileData.current_medications}
                    onChange={(e) => setEditProfileData({ ...editProfileData, current_medications: e.target.value })}
                    className="w-full px-3 py-2.5 rounded-lg border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-sm transition-all duration-200 resize-none"
                    placeholder="Wymień leki, dawki i częstotliwość"
                  />
                ) : (
                  <p className="text-ivory-100/90 text-sm font-medium whitespace-pre-wrap leading-relaxed">
                    {user.patientProfile?.current_medications || "Brak"}
                  </p>
                )}
              </div>

              {/* Nazwisko panieńskie */}
              {isEditing || user.patientProfile?.maiden_name ? (
                <div className="bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                  <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Nazwisko panieńskie</h3>
                  {isEditing ? (
                    <input
                      type="text"
                      value={editProfileData.maiden_name}
                      onChange={(e) => setEditProfileData({ ...editProfileData, maiden_name: e.target.value })}
                      className="w-full px-3 py-2.5 rounded-lg border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-sm transition-all duration-200"
                    />
                  ) : (
                    <p className="text-ivory-100/90 text-sm font-medium">{user.patientProfile?.maiden_name}</p>
                  )}
                </div>
              ) : null}

              {/* Upoważniona osoba */}
              {isEditing || user.patientProfile?.authorized_person ? (
                <div className="bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                  <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Upoważniona osoba</h3>
                  {isEditing ? (
                    <input
                      type="text"
                      value={editProfileData.authorized_person}
                      onChange={(e) => setEditProfileData({ ...editProfileData, authorized_person: e.target.value })}
                      className="w-full px-3 py-2.5 rounded-lg border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-sm transition-all duration-200"
                      placeholder="Imię i nazwisko"
                    />
                  ) : (
                    <p className="text-ivory-100/90 text-sm font-medium">{user.patientProfile?.authorized_person}</p>
                  )}
                </div>
              ) : null}

              {/* Dokumenty / uwagi */}
              {isEditing || user.patientProfile?.documents_info ? (
                <div className="md:col-span-2 lg:col-span-3 xl:col-span-4 bg-white/3 rounded-xl p-4 border border-white/5 hover:border-white/10 transition-all duration-200 hover:bg-white/5">
                  <h3 className="text-xs md:text-sm font-semibold text-ivory-100/70 mb-3 uppercase tracking-wide">Dokumenty / uwagi</h3>
                  {isEditing ? (
                    <textarea
                      rows={3}
                      value={editProfileData.documents_info}
                      onChange={(e) => setEditProfileData({ ...editProfileData, documents_info: e.target.value })}
                      className="w-full px-3 py-2.5 rounded-lg border-2 border-white/10 bg-white/5 text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20 text-sm transition-all duration-200 resize-none"
                      placeholder="Np. dokumenty potwierdzające uprawnienia"
                    />
                  ) : (
                    <p className="text-ivory-100/90 text-sm font-medium whitespace-pre-wrap leading-relaxed">{user.patientProfile?.documents_info}</p>
                  )}
                </div>
              ) : null}
            </div>

            {/* Dental Chart Section */}
            <div className="border-t border-white/10 pt-6">
              <div className="w-full overflow-x-auto -mx-3 sm:-mx-4 md:-mx-6 px-3 sm:px-4 md:px-6">
                <div className="min-w-fit">
                  <DentalChart patientId={user.id} />
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
  );
}

