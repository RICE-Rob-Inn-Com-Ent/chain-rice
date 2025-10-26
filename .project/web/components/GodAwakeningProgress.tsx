"use client";
import React, { useEffect, useState } from "react";

interface GodAwakeningProgressProps {
  godName: string;
  progress: number;
  stage: "downloading" | "extracting" | "loading" | "warming" | "ready";
}

export const GodAwakeningProgress: React.FC<GodAwakeningProgressProps> = ({ godName, progress, stage }) => {
  const [moonPhase, setMoonPhase] = useState(0);

  useEffect(() => {
    // Animuj fazę księżyca w zależności od progressu
    setMoonPhase(progress);
  }, [progress]);

  const getMoonIcon = () => {
    if (progress < 20) return "🌑"; // Nów
    if (progress < 40) return "🌒"; // Wąski sierp
    if (progress < 60) return "🌓"; // Pierwsza kwadra
    if (progress < 80) return "🌔"; // Prawie pełnia
    if (progress < 95) return "🌕"; // Pełnia
    return "☀️"; // Słońce!
  };

  const getStageText = () => {
    switch (stage) {
      case "downloading":
        return "🧹 Clearing VRAM...";
      case "extracting":
        return "📦 Loading from cache...";
      case "loading":
        return "⚡ Loading to GPU temple...";
      case "warming":
        return "🔥 Warming up model...";
      case "ready":
        return "✨ God awakened!";
      default:
        return "Preparing...";
    }
  };

  const getStageColor = () => {
    switch (stage) {
      case "downloading":
        return "from-blue-600 to-cyan-600";
      case "extracting":
        return "from-purple-600 to-pink-600";
      case "loading":
        return "from-yellow-600 to-amber-600";
      case "warming":
        return "from-orange-600 to-red-600";
      case "ready":
        return "from-green-600 to-emerald-600";
      default:
        return "from-gray-600 to-gray-700";
    }
  };

  return (
    <div className="fixed inset-0 bg-black/80 backdrop-blur-md z-[100] flex items-center justify-center">
      <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-3xl p-8 max-w-md w-full mx-4 border-2 border-amber-500/30 shadow-2xl shadow-amber-500/20">
        {/* Moon to Sun Transition */}
        <div className="text-center mb-6">
          <div className="text-9xl mb-4 transition-all duration-500 transform hover:scale-110">{getMoonIcon()}</div>
          <h3 className="text-2xl font-bold text-amber-400 mb-2">Budzenie {godName}</h3>
          <p className="text-sm text-gray-400">{getStageText()}</p>
        </div>

        {/* Progress Bar */}
        <div className="mb-6">
          <div className="w-full bg-gray-700 rounded-full h-4 overflow-hidden shadow-inner">
            <div
              className={`h-4 bg-gradient-to-r ${getStageColor()} transition-all duration-300 ease-out shadow-lg relative`}
              style={{ width: `${progress}%` }}
            >
              {/* Animated shine effect */}
              <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent animate-shimmer" />
            </div>
          </div>
          <div className="flex justify-between mt-2 text-xs text-gray-400">
            <span>{progress}%</span>
            <span className="font-mono">{stage.toUpperCase()}</span>
          </div>
        </div>

        {/* Hieroglyphs Animation */}
        <div className="flex justify-center gap-4 text-3xl text-amber-500/30 animate-pulse">
          <span className="animate-bounce">𓂀</span>
          <span className="animate-bounce delay-100">𓁹</span>
          <span className="animate-bounce delay-200">𓆣</span>
          <span className="animate-bounce delay-300">𓃭</span>
        </div>

        {/* Status Text */}
        <div className="mt-6 bg-black/50 rounded-lg p-4 border border-amber-500/20">
          <div className="text-xs font-mono text-green-400 space-y-1">
            <div className="flex items-center gap-2">
              <span className={progress >= 15 ? "text-green-400" : "text-gray-600"}>{progress >= 15 ? "✓" : "○"}</span>
              <span>Sleeping other gods (clear VRAM)...</span>
            </div>
            <div className="flex items-center gap-2">
              <span className={progress >= 35 ? "text-green-400" : "text-gray-600"}>{progress >= 35 ? "✓" : "○"}</span>
              <span>Checking container health...</span>
            </div>
            <div className="flex items-center gap-2">
              <span className={progress >= 60 ? "text-green-400" : "text-gray-600"}>{progress >= 60 ? "✓" : "○"}</span>
              <span>Loading model from cache...</span>
            </div>
            <div className="flex items-center gap-2">
              <span className={progress >= 85 ? "text-green-400" : "text-gray-600"}>{progress >= 85 ? "✓" : "○"}</span>
              <span>Loading to VRAM...</span>
            </div>
            <div className="flex items-center gap-2">
              <span className={progress >= 100 ? "text-green-400" : "text-gray-600"}>
                {progress >= 100 ? "✓" : "○"}
              </span>
              <span>Warming up... Ready!</span>
            </div>
          </div>

          {/* Time estimation */}
          <div className="mt-3 pt-3 border-t border-amber-500/20 text-center">
            <div className="text-xs text-amber-400">
              {progress < 35 && "⏱️ Clearing VRAM... ~5s"}
              {progress >= 35 && progress < 60 && "⏱️ Loading from cache... ~10-20s"}
              {progress >= 60 && progress < 85 && "⏱️ Loading to VRAM... ~15-25s"}
              {progress >= 85 && progress < 100 && "⏱️ Almost ready... ~5s"}
              {progress >= 100 && "✅ Ready!"}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
