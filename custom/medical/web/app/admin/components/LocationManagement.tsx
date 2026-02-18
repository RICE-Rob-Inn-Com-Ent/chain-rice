"use client";

import { useState, useEffect } from "react";

type Location = {
  id: string;
  name: string;
  address: string | null;
  city: string | null;
  postal_code: string | null;
  phone: string | null;
  email: string | null;
  active: boolean;
};

export default function LocationManagement() {
  const [locations, setLocations] = useState<Location[]>([]);
  const [loading, setLoading] = useState(true);
  const [showAddModal, setShowAddModal] = useState(false);
  const [editingLocation, setEditingLocation] = useState<Location | null>(null);
  const [formData, setFormData] = useState({
    name: "",
    address: "",
    city: "",
    postal_code: "",
    phone: "",
    email: "",
  });
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    fetchLocations();
  }, []);

  const fetchLocations = async () => {
    try {
      const res = await fetch("/api/locations");
      if (res.ok) {
        const data = await res.json();
        setLocations(data.locations || []);
      }
    } catch (error) {
      console.error("Error fetching locations:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError("");
    setSaving(true);

    try {
      const url = editingLocation
        ? `/api/locations/${editingLocation.id}`
        : "/api/locations";
      const method = editingLocation ? "PUT" : "POST";

      const res = await fetch(url, {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      });

      const data = await res.json();

      if (res.ok) {
        await fetchLocations();
        setShowAddModal(false);
        setEditingLocation(null);
        setFormData({
          name: "",
          address: "",
          city: "",
          postal_code: "",
          phone: "",
          email: "",
        });
      } else {
        setError(data.error || "Wystąpił błąd podczas zapisywania");
      }
    } catch (error) {
      setError("Wystąpił błąd podczas zapisywania");
    } finally {
      setSaving(false);
    }
  };

  const handleEdit = (location: Location) => {
    setEditingLocation(location);
    setFormData({
      name: location.name,
      address: location.address || "",
      city: location.city || "",
      postal_code: location.postal_code || "",
      phone: location.phone || "",
      email: location.email || "",
    });
    setShowAddModal(true);
  };

  const handleDelete = async (id: string) => {
    if (!confirm("Czy na pewno chcesz usunąć tę lokalizację?")) return;

    try {
      const res = await fetch(`/api/locations/${id}`, {
        method: "DELETE",
      });

      if (res.ok) {
        await fetchLocations();
      } else {
        alert("Nie udało się usunąć lokalizacji");
      }
    } catch (error) {
      alert("Wystąpił błąd podczas usuwania");
    }
  };

  const inputClass =
    "w-full rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-sm text-ivory-100 placeholder:text-ivory-100/40 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20";

  if (loading) {
    return <div className="text-ivory-100/60">Ładowanie...</div>;
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-ivory-100">Lokalizacje placówek</h3>
        <button
          type="button"
          onClick={() => {
            setEditingLocation(null);
            setFormData({
              name: "",
              address: "",
              city: "",
              postal_code: "",
              phone: "",
              email: "",
            });
            setShowAddModal(true);
          }}
          className="px-4 py-2 rounded-lg bg-amber-500 text-white hover:bg-amber-600 transition-colors text-sm font-semibold"
        >
          Dodaj lokalizację
        </button>
      </div>

      {locations.length === 0 ? (
        <div className="text-center py-8 text-ivory-100/60">
          <p>Brak lokalizacji. Dodaj pierwszą lokalizację.</p>
        </div>
      ) : (
        <div className="space-y-2">
          {locations.map((location) => (
            <div
              key={location.id}
              className="flex items-center justify-between p-4 rounded-lg border border-white/10 bg-white/5"
            >
              <div className="flex-1">
                <h4 className="font-semibold text-ivory-100">{location.name}</h4>
                {location.city && (
                  <p className="text-sm text-ivory-100/60 mt-1">{location.city}</p>
                )}
                {location.address && (
                  <p className="text-sm text-ivory-100/60">{location.address}</p>
                )}
              </div>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => handleEdit(location)}
                  className="p-2 rounded-lg border border-white/10 hover:bg-white/10 text-ivory-100/70 hover:text-ivory-100 transition"
                  title="Edytuj"
                >
                  <span
                    className="material-symbols-outlined text-sm"
                    style={{ fontVariationSettings: '"FILL" 0, "wght" 300, "GRAD" 0, "opsz" 24' }}
                  >
                    edit
                  </span>
                </button>
                <button
                  type="button"
                  onClick={() => handleDelete(location.id)}
                  className="p-2 rounded-lg border border-red-500/50 hover:bg-red-500/20 text-red-400 transition"
                  title="Usuń"
                >
                  <span
                    className="material-symbols-outlined text-sm"
                    style={{ fontVariationSettings: '"FILL" 0, "wght" 300, "GRAD" 0, "opsz" 24' }}
                  >
                    delete
                  </span>
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {showAddModal && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-slate-900/70 p-4">
          <div className="w-full max-w-md rounded-3xl border border-white/10 bg-obsidian-900 p-6 shadow-2xl">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-xl font-semibold text-ivory-100">
                {editingLocation ? "Edytuj lokalizację" : "Dodaj lokalizację"}
              </h3>
              <button
                onClick={() => {
                  setShowAddModal(false);
                  setEditingLocation(null);
                  setError("");
                }}
                className="rounded-full border border-white/15 px-3 py-1 text-sm text-ivory-100/70 hover:bg-white/10"
              >
                <span
                  className="material-symbols-outlined"
                  style={{ fontVariationSettings: '"FILL" 0, "wght" 300, "GRAD" 0, "opsz" 24' }}
                >
                  close
                </span>
              </button>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-xs text-ivory-100/60 mb-1">
                  Nazwa lokalizacji *
                </label>
                <input
                  type="text"
                  required
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  className={inputClass}
                  placeholder="np. Ceramix Warszawa"
                />
              </div>

              <div>
                <label className="block text-xs text-ivory-100/60 mb-1">Adres</label>
                <input
                  type="text"
                  value={formData.address}
                  onChange={(e) => setFormData({ ...formData, address: e.target.value })}
                  className={inputClass}
                  placeholder="ul. Przykładowa 123"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-xs text-ivory-100/60 mb-1">Miasto</label>
                  <input
                    type="text"
                    value={formData.city}
                    onChange={(e) => setFormData({ ...formData, city: e.target.value })}
                    className={inputClass}
                    placeholder="Warszawa"
                  />
                </div>
                <div>
                  <label className="block text-xs text-ivory-100/60 mb-1">Kod pocztowy</label>
                  <input
                    type="text"
                    value={formData.postal_code}
                    onChange={(e) => setFormData({ ...formData, postal_code: e.target.value })}
                    className={inputClass}
                    placeholder="00-000"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-xs text-ivory-100/60 mb-1">Telefon</label>
                  <input
                    type="tel"
                    value={formData.phone}
                    onChange={(e) => setFormData({ ...formData, phone: e.target.value })}
                    className={inputClass}
                    placeholder="+48 123 456 789"
                  />
                </div>
                <div>
                  <label className="block text-xs text-ivory-100/60 mb-1">Email</label>
                  <input
                    type="email"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className={inputClass}
                    placeholder="kontakt@ceramix.pl"
                  />
                </div>
              </div>

              {error && (
                <div className="text-sm text-red-400 bg-red-500/10 border border-red-500/50 rounded-lg p-3">
                  {error}
                </div>
              )}

              <div className="flex gap-2 pt-2">
                <button
                  type="submit"
                  disabled={saving}
                  className="flex-1 rounded-lg bg-amber-500 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {saving ? "Zapisywanie..." : editingLocation ? "Zapisz" : "Dodaj"}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setShowAddModal(false);
                    setEditingLocation(null);
                    setError("");
                  }}
                  className="flex-1 rounded-lg border border-white/10 px-4 py-2 text-sm text-ivory-100 hover:bg-white/5 transition-colors"
                >
                  Anuluj
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}


