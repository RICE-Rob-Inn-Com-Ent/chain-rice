"use client";
import React from "react";

interface GodCardProps {
  god: {
    id: string;
    name: string;
    title: string;
    description: string;
    icon: string;
    color: string;
    status: "active" | "inactive" | "loading" | "busy";
    model: string;
  };
  isSelected: boolean;
  onSelect: () => void;
  onStart: () => void;
  onStop: () => void;
  onDemo?: () => void;
  onBenchmark?: () => void;
}

export const GodCard: React.FC<GodCardProps> = ({
  god,
  isSelected,
  onSelect,
  onStart,
  onStop,
  onDemo,
  onBenchmark,
}) => {
  const handleDemo = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (god.status !== "active") {
      alert("Najpierw przebudź boga!");
      return;
    }
    if (onDemo) onDemo();
  };

  const handleBenchmark = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (god.status !== "active") {
      alert("Najpierw przebudź boga!");
      return;
    }
    if (onBenchmark) onBenchmark();
  };

  return (
    <div
      className={`relative group cursor-pointer transition-all duration-300 ${
        isSelected ? "scale-105 z-10" : "hover:scale-102"
      }`}
      onClick={onSelect}
    >
      <div
        className={`bg-gradient-to-br ${god.color} p-[2px] rounded-2xl transition-all duration-300 ${
          isSelected ? "shadow-2xl shadow-amber-500/50 animate-pulse-slow" : "shadow-lg"
        }`}
      >
        <div className="bg-gray-900 rounded-2xl p-6 h-full backdrop-blur-sm">
          {/* Icon */}

          <div className="text-6xl mb-3 text-center transform group-hover:scale-110 transition-transform duration-300">
            {god.icon}
          </div>

          {/* Name */}
          <h3 className="text-xl font-bold text-center mb-1 bg-gradient-to-r from-amber-400 via-yellow-500 to-amber-600 bg-clip-text text-transparent">
            {god.name}
          </h3>

          {/* Title */}
          <p className="text-xs text-amber-500/80 text-center mb-3 font-semibold">{god.title}</p>

          {/* Description */}
          <p className="text-xs text-gray-400 text-center mb-3 leading-relaxed min-h-[3.5rem]">{god.description}</p>

          {/* Model Info */}
          <div className="text-[0.65rem] text-center mb-4 text-gray-500 font-mono bg-black/30 rounded p-2">
            {god.model}
          </div>

          {/* Controls */}
          <div className="space-y-2" onClick={(e) => e.stopPropagation()}>
            {/* Primary Action */}
            {god.status === "active" || god.status === "busy" ? (
              <button
                onClick={onStop}
                className="w-full bg-gradient-to-r from-red-600 to-red-700 hover:from-red-700 hover:to-red-800 text-white text-xs py-2 px-3 rounded-lg transition-all duration-200 font-semibold shadow-lg hover:shadow-red-500/50"
              >
                🌙 Uśpij
              </button>
            ) : (
              <button
                onClick={onStart}
                disabled={god.status === "loading"}
                className="w-full bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 disabled:from-gray-600 disabled:to-gray-700 text-white text-xs py-2 px-3 rounded-lg transition-all duration-200 font-semibold shadow-lg hover:shadow-green-500/50 disabled:cursor-not-allowed"
              >
                {god.status === "loading" ? "⏳ Budzenie..." : "⚡ Przebudź"}
              </button>
            )}

            {/* Demo & Benchmark Buttons */}
            <div className="flex gap-2">
              <button
                onClick={handleDemo}
                disabled={god.status !== "active"}
                className="flex-1 bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 disabled:from-gray-700 disabled:to-gray-800 text-white text-xs py-2 px-2 rounded-lg transition-all duration-200 font-semibold disabled:cursor-not-allowed disabled:opacity-50"
                title="Otwórz dedykowany interface"
              >
                🎮 Demo
              </button>
              <button
                onClick={handleBenchmark}
                disabled={god.status !== "active"}
                className="flex-1 bg-gradient-to-r from-purple-600 to-purple-700 hover:from-purple-700 hover:to-purple-800 disabled:from-gray-700 disabled:to-gray-800 text-white text-xs py-2 px-2 rounded-lg transition-all duration-200 font-semibold disabled:cursor-not-allowed disabled:opacity-50"
                title="Sprawdź wydajność"
              >
                📊 Benchmark
              </button>
            </div>
          </div>

          {/* Decorative Elements */}
          {isSelected && (
            <div className="absolute inset-0 pointer-events-none">
              <div className="absolute -top-1 -left-1 text-2xl opacity-70 animate-bounce">𓂀</div>
              <div className="absolute -top-1 -right-1 text-2xl opacity-70 animate-bounce delay-150">𓁹</div>
              <div className="absolute -bottom-1 -left-1 text-2xl opacity-70 animate-bounce delay-300">𓆣</div>
              <div className="absolute -bottom-1 -right-1 text-2xl opacity-70 animate-bounce delay-450">𓃭</div>
            </div>
          )}
        </div>
      </div>

      {/* Hieroglyphs decoration */}
      <div className="absolute -top-2 -left-2 text-3xl opacity-20 group-hover:opacity-40 transition-opacity">𓂀</div>
      <div className="absolute -bottom-2 -right-2 text-3xl opacity-20 group-hover:opacity-40 transition-opacity">𓁹</div>
    </div>
  );
};
