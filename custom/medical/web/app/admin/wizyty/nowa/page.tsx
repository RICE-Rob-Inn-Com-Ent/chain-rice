"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, Save, Calendar, Clock, User, Stethoscope } from "lucide-react";

type Patient = {
  id: string;
  patient_number: string;
  first_name: string;
  last_name: string;
};

type Dentist = {
  id: string;
  license_number: string;
  first_name: string;
  last_name: string;
};

type TreatmentType = {
  id: string;
  code: string;
  name: string;
  default_duration_minutes: number;
  default_price: number;
};

export default function NewAppointmentPage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [patients, setPatients] = useState<Patient[]>([]);
  const [dentists, setDentists] = useState<Dentist[]>([]);
  const [treatmentTypes, setTreatmentTypes] = useState<TreatmentType[]>([]);
  const [loadingData, setLoadingData] = useState(true);

  const [formData, setFormData] = useState({
    patient_id: "",
    dentist_id: "",
    appointment_date: "",
    appointment_time: "",
    duration_minutes: 30,
    treatment_type: "",
    treatment_description: "",
    notes: "",
    price: "",
  });

  useEffect(() => {
    fetchInitialData();
  }, []);

  const fetchInitialData = async () => {
    try {
      const [patientsRes, dentistsRes, treatmentTypesRes] = await Promise.all([
        fetch("/api/patients"),
        fetch("/api/dentists"),
        fetch("/api/treatment-types"),
      ]);

      const patientsData = await patientsRes.json();
      const dentistsData = await dentistsRes.json();
      const treatmentTypesData = await treatmentTypesRes.json();

      setPatients(patientsData.patients || []);
      setDentists(dentistsData.dentists || []);
      setTreatmentTypes(treatmentTypesData.treatment_types || []);
    } catch (err) {
      console.error("Error fetching data:", err);
      setError("Błąd podczas ładowania danych");
    } finally {
      setLoadingData(false);
    }
  };

  const handleTreatmentTypeChange = (treatmentTypeName: string) => {
    const treatmentType = treatmentTypes.find((tt) => tt.name === treatmentTypeName);
    if (treatmentType) {
      setFormData({
        ...formData,
        treatment_type: treatmentType.name,
        duration_minutes: treatmentType.default_duration_minutes || 30,
        price: treatmentType.default_price ? treatmentType.default_price.toString() : "",
      });
    } else {
      setFormData({
        ...formData,
        treatment_type: treatmentTypeName,
      });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    if (!formData.patient_id || !formData.dentist_id || !formData.appointment_date || !formData.appointment_time) {
      setError("Pacjent, dentysta, data i godzina są wymagane");
      setLoading(false);
      return;
    }

    try {
      const res = await fetch("/api/appointments", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          patient_id: formData.patient_id,
          dentist_id: formData.dentist_id,
          appointment_date: formData.appointment_date,
          appointment_time: formData.appointment_time,
          duration_minutes: formData.duration_minutes,
          treatment_type: formData.treatment_type || null,
          treatment_description: formData.treatment_description || null,
          notes: formData.notes || null,
          price: formData.price ? parseFloat(formData.price) : null,
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Błąd podczas tworzenia wizyty");
        setLoading(false);
        return;
      }

      router.push("/admin/wizyty");
    } catch (err) {
      setError("Wystąpił błąd. Spróbuj ponownie.");
      setLoading(false);
    }
  };

  if (loadingData) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="text-ivory-100/60">Ładowanie danych...</div>
      </div>
    );
  }

  return (
    <div>
      <div className="mb-8 flex items-center justify-between">
        <div>
          <Link
            href="/admin/wizyty"
            className="mb-4 inline-flex items-center gap-2 text-ivory-100/60 hover:text-ivory-100"
          >
            <ArrowLeft className="h-4 w-4" />
            Powrót do listy
          </Link>
          <h1 className="font-display text-4xl text-ivory-100">Nowa wizyta</h1>
          <p className="mt-2 text-ivory-100/70">Zaplanuj nową wizytę pacjenta</p>
        </div>
      </div>

      <div className="marble-card p-6">
        {error && (
          <div className="mb-6 rounded-lg bg-red-500/20 border border-red-500/50 p-4 text-red-400">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid md:grid-cols-2 gap-6">
            {/* Pacjent */}
            <div>
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                <User className="inline h-4 w-4 mr-2" />
                Pacjent *
              </label>
              <select
                required
                value={formData.patient_id}
                onChange={(e) => setFormData({ ...formData, patient_id: e.target.value })}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
              >
                <option value="">Wybierz pacjenta</option>
                {patients.map((patient) => (
                  <option key={patient.id} value={patient.id}>
                    {patient.patient_number} - {patient.first_name} {patient.last_name}
                  </option>
                ))}
              </select>
            </div>

            {/* Dentysta */}
            <div>
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                <Stethoscope className="inline h-4 w-4 mr-2" />
                Dentysta *
              </label>
              <select
                required
                value={formData.dentist_id}
                onChange={(e) => setFormData({ ...formData, dentist_id: e.target.value })}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
              >
                <option value="">Wybierz dentystę</option>
                {dentists
                  .filter((d) => d.first_name && d.last_name)
                  .map((dentist) => (
                    <option key={dentist.id} value={dentist.id}>
                      {dentist.first_name} {dentist.last_name} ({dentist.license_number})
                    </option>
                  ))}
              </select>
            </div>

            {/* Data */}
            <div>
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                <Calendar className="inline h-4 w-4 mr-2" />
                Data wizyty *
              </label>
              <input
                type="date"
                required
                value={formData.appointment_date}
                onChange={(e) => setFormData({ ...formData, appointment_date: e.target.value })}
                min={new Date().toISOString().split("T")[0]}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
              />
            </div>

            {/* Godzina */}
            <div>
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                <Clock className="inline h-4 w-4 mr-2" />
                Godzina wizyty *
              </label>
              <input
                type="time"
                required
                value={formData.appointment_time}
                onChange={(e) => setFormData({ ...formData, appointment_time: e.target.value })}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
              />
            </div>

            {/* Typ leczenia */}
            <div>
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                Typ leczenia
              </label>
              <select
                value={formData.treatment_type}
                onChange={(e) => {
                  const selectedName = e.target.value;
                  if (selectedName) {
                    handleTreatmentTypeChange(selectedName);
                  } else {
                    setFormData({ ...formData, treatment_type: "", duration_minutes: 30, price: "" });
                  }
                }}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
              >
                <option value="">Wybierz typ leczenia (opcjonalnie)</option>
                {treatmentTypes.map((tt) => (
                  <option key={tt.id} value={tt.name}>
                    {tt.name} ({tt.default_duration_minutes} min{tt.default_price ? `, ${tt.default_price} PLN` : ""})
                  </option>
                ))}
              </select>
              {treatmentTypes.length === 0 && (
                <input
                  type="text"
                  value={formData.treatment_type}
                  onChange={(e) => setFormData({ ...formData, treatment_type: e.target.value })}
                  placeholder="Wprowadź typ leczenia ręcznie"
                  className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20 mt-2"
                />
              )}
            </div>

            {/* Czas trwania */}
            <div>
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                Czas trwania (minuty)
              </label>
              <input
                type="number"
                min={15}
                step={15}
                value={formData.duration_minutes}
                onChange={(e) =>
                  setFormData({ ...formData, duration_minutes: parseInt(e.target.value) || 30 })
                }
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
              />
            </div>

            {/* Cena */}
            <div>
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                Cena (PLN)
              </label>
              <input
                type="number"
                min={0}
                step={0.01}
                value={formData.price}
                onChange={(e) => setFormData({ ...formData, price: e.target.value })}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
              />
            </div>

            {/* Opis leczenia */}
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                Opis leczenia
              </label>
              <textarea
                rows={3}
                value={formData.treatment_description}
                onChange={(e) => setFormData({ ...formData, treatment_description: e.target.value })}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
                placeholder="Szczegółowy opis planowanego leczenia..."
              />
            </div>

            {/* Notatki */}
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                Notatki
              </label>
              <textarea
                rows={3}
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
                placeholder="Dodatkowe notatki dotyczące wizyty..."
              />
            </div>
          </div>

          <div className="flex gap-4">
            <button
              type="submit"
              disabled={loading}
              className="flex items-center gap-2 rounded-lg bg-ember-500 px-6 py-2 font-semibold text-white transition hover:bg-ember-600 disabled:opacity-50"
            >
              <Save className="h-5 w-5" />
              {loading ? "Zapisywanie..." : "Utwórz wizytę"}
            </button>
            <Link
              href="/admin/wizyty"
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

