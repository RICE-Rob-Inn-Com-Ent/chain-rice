"use client";

import { useState } from "react";
import Icon from "@/app/components/Icon";
import dynamic from "next/dynamic";

const LocationSettingsContent = dynamic(
  () => import("@/app/admin/components/LocationSettingsContent"),
  { ssr: false }
);

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function SettingsModal({ isOpen, onClose }: SettingsModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/80 p-4">
      <div className="w-full max-w-2xl rounded-3xl border border-white/10 bg-obsidian-900 p-6 shadow-2xl max-h-[90vh] overflow-y-auto">
        <div className="flex items-center justify-between mb-4">
          <div>
            <p className="text-xs uppercase tracking-[0.3em] text-ivory-100/40">Zarządzanie</p>
            <h3 className="text-xl font-semibold text-ivory-100">Ustawienia</h3>
          </div>
          <button
            onClick={onClose}
            className="rounded-full border border-white/15 px-3 py-1 text-sm text-ivory-100/70 hover:bg-white/10"
          >
            <Icon icon="close" />
          </button>
        </div>

        <LocationSettingsContent onClose={onClose} />
      </div>
    </div>
  );
}

