"use client";

import { useState } from "react";
import dynamic from "next/dynamic";
import Icon from "@/app/components/Icon";

const SettingsModal = dynamic(
  () => import("@/app/admin/components/SettingsModal"),
  { ssr: false }
);

export default function SettingsButton() {
  const [isModalOpen, setIsModalOpen] = useState(false);

  return (
    <>
      <button
        onClick={() => setIsModalOpen(true)}
        className="p-1 rounded hover:bg-white/5 text-ivory-100/60 hover:text-ivory-100 transition flex-shrink-0"
        title="Dodaj lokalizację"
      >
        <Icon icon="medical_mask" width="24" height="24" className="text-base" />
      </button>
      <SettingsModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} />
    </>
  );
}

