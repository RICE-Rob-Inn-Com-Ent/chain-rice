"use client";

import { useLocation } from "@/app/contexts/LocationContext";
import { useState } from "react";
import dynamic from "next/dynamic";
import Icon from "@/app/components/Icon";

const LocationSettingsContent = dynamic(
  () => import("@/app/admin/components/LocationSettingsContent"),
  { ssr: false }
);

export default function LocationSelector({ username, isOwner }: { username: string; isOwner: boolean }) {
  const { selectedLocationId, setSelectedLocationId, locations, loading, refreshLocations } = useLocation();
  const [showSettingsModal, setShowSettingsModal] = useState(false);

  if (loading) {
    return (
      <div className="mb-4">
        <div className="h-10 bg-white/5 rounded-lg animate-pulse"></div>
      </div>
    );
  }

  if (!isOwner || locations.length === 0) {
    return null;
  }

  return (
    <>
      <div className="mb-4 space-y-2">
        <div className="flex items-center gap-2">
          <Icon icon="edit_location" width="24" height="24" className="text-lg text-ivory-100/60" />
          <select
            value={selectedLocationId || ""}
            onChange={(e) => setSelectedLocationId(e.target.value || null)}
            className="flex-1 rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-sm text-ivory-100 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-400/20"
          >
            <option value="">Wszystkie lokalizacje</option>
            {locations
              .filter((loc: any) => loc.active)
              .map((loc) => (
                <option key={loc.id} value={loc.id}>
                  {loc.name}
                </option>
              ))}
          </select>
        </div>
      </div>

      {showSettingsModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/80 p-4">
          <div className="w-full max-w-2xl rounded-3xl border border-white/10 bg-obsidian-900 p-6 shadow-2xl max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-4">
              <div>
                <p className="text-xs uppercase tracking-[0.3em] text-ivory-100/40">Zarządzanie</p>
                <h3 className="text-xl font-semibold text-ivory-100">Lokalizacje placówek</h3>
              </div>
              <button
                onClick={() => {
                  setShowSettingsModal(false);
                }}
                className="rounded-full border border-white/15 px-3 py-1 text-sm text-ivory-100/70 hover:bg-white/10"
              >
                <Icon icon="close" />
              </button>
            </div>

            <LocationSettingsContent
              onClose={async () => {
                setShowSettingsModal(false);
                // Refresh locations after closing
                await refreshLocations();
              }}
            />
          </div>
        </div>
      )}
    </>
  );
}

