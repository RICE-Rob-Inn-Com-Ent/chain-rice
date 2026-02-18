"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, Save } from "lucide-react";

type Patient = {
  id: string;
  patient_number: string;
  first_name: string;
  last_name: string;
};

export default function NewInvoicePage() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [loadingPatients, setLoadingPatients] = useState(true);
  const [error, setError] = useState("");
  const [patients, setPatients] = useState<Patient[]>([]);
  const [formData, setFormData] = useState({
    patient_id: "",
    issue_date: new Date().toISOString().split("T")[0],
    due_date: "",
    total_amount: "",
    tax_amount: "",
    status: "draft",
    notes: "",
  });

  useEffect(() => {
    // Load patients
    const loadPatients = async () => {
      try {
        const res = await fetch("/api/patients?limit=1000");
        const data = await res.json();
        if (res.ok) {
          setPatients(data.patients || []);
        }
      } catch (err) {
        console.error("Failed to load patients:", err);
      } finally {
        setLoadingPatients(false);
      }
    };

    loadPatients();
  }, []);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      const res = await fetch("/api/invoices", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          patient_id: formData.patient_id,
          issue_date: formData.issue_date,
          due_date: formData.due_date,
          total_amount: parseFloat(formData.total_amount) || 0,
          tax_amount: parseFloat(formData.tax_amount) || 0,
          status: formData.status,
          notes: formData.notes || null,
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Błąd podczas tworzenia faktury");
        setLoading(false);
        return;
      }

      router.push(`/${data.invoice?.patient_id || ""}/ksiegowosc`);
    } catch (err) {
      setError("Wystąpił błąd. Spróbuj ponownie.");
      setLoading(false);
    }
  };

  // Calculate due date (default: 14 days from issue date)
  useEffect(() => {
    if (formData.issue_date && !formData.due_date) {
      const issueDate = new Date(formData.issue_date);
      issueDate.setDate(issueDate.getDate() + 14);
      setFormData((prev) => ({
        ...prev,
        due_date: issueDate.toISOString().split("T")[0],
      }));
    }
  }, [formData.issue_date]);

  return (
    <div>
      <div className="mb-8 flex items-center justify-between">
        <div>
          <Link
            href="/admin/ksiegowosc"
            className="mb-4 inline-flex items-center gap-2 text-ivory-100/60 hover:text-ivory-100"
          >
            <ArrowLeft className="h-4 w-4" />
            Powrót do listy
          </Link>
          <h1 className="font-display text-4xl text-ivory-100">Nowa faktura</h1>
          <p className="mt-2 text-ivory-100/70">Utwórz nową fakturę</p>
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
            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                Pacjent *
              </label>
              {loadingPatients ? (
                <div className="px-4 py-2 text-ivory-100/60">Ładowanie pacjentów...</div>
              ) : (
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
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                Data wystawienia *
              </label>
              <input
                type="date"
                required
                value={formData.issue_date}
                onChange={(e) => setFormData({ ...formData, issue_date: e.target.value })}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                Termin płatności *
              </label>
              <input
                type="date"
                required
                value={formData.due_date}
                onChange={(e) => setFormData({ ...formData, due_date: e.target.value })}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                Kwota całkowita (PLN) *
              </label>
              <input
                type="number"
                step="0.01"
                min="0"
                required
                value={formData.total_amount}
                onChange={(e) => setFormData({ ...formData, total_amount: e.target.value })}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                Kwota VAT (PLN)
              </label>
              <input
                type="number"
                step="0.01"
                min="0"
                value={formData.tax_amount}
                onChange={(e) => setFormData({ ...formData, tax_amount: e.target.value })}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                Status *
              </label>
              <select
                required
                value={formData.status}
                onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
              >
                <option value="draft">Szkic</option>
                <option value="sent">Wysłana</option>
                <option value="paid">Opłacona</option>
                <option value="overdue">Przeterminowana</option>
                <option value="cancelled">Anulowana</option>
              </select>
            </div>

            <div className="md:col-span-2">
              <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                Notatki
              </label>
              <textarea
                rows={4}
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20"
              />
            </div>
          </div>

          <div className="flex gap-4">
            <button
              type="submit"
              disabled={loading || loadingPatients}
              className="flex items-center gap-2 rounded-lg bg-ember-500 px-6 py-2 font-semibold text-white transition hover:bg-ember-600 disabled:opacity-50"
            >
              <Save className="h-5 w-5" />
              {loading ? "Zapisywanie..." : "Zapisz fakturę"}
            </button>
            <Link
              href="/admin/ksiegowosc"
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

