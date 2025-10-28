import React from "react";
import { ThothTraining, RaTraining, IsisTraining, BastetTraining, MaatTraining, KhnumTraining } from "./training";

interface GodTrainingProps {
  godId: "thoth" | "ra" | "isis" | "bastet" | "maat" | "khnum";
  onBack: () => void;
}

/**
 * God-specific training interface router
 */
export const GodTraining: React.FC<GodTrainingProps> = ({ godId, onBack }) => {
  return (
    <div className="p-8">
      {/* Back Button */}
      <button
        onClick={onBack}
        className="mb-6 px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg transition flex items-center gap-2"
      >
        ← Back to Dashboard
      </button>

      {/* Render appropriate training interface */}
      {godId === "thoth" && <ThothTraining />}
      {godId === "ra" && <RaTraining />}
      {godId === "isis" && <IsisTraining />}
      {godId === "bastet" && <BastetTraining />}
      {godId === "maat" && <MaatTraining />}
      {godId === "khnum" && <KhnumTraining />}
    </div>
  );
};

