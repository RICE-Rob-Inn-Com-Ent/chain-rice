"use client";
import React, { useState, useEffect } from "react";
import { GodCard } from "./GodCard";
import { GodAwakeningProgress } from "./GodAwakeningProgress";

export interface God {
  id: string;
  name: string;
  title: string;
  description: string;
  model: string;
  icon: string;
  color: string;
  status: "active" | "inactive" | "loading" | "busy";
  port: number;
  domain: string;
  metrics?: {
    responseTime: number;
    tokensPerSecond: number;
    gpuUtilization: number;
    memoryUsed: number;
  };
}

const EGYPTIAN_GODS: God[] = [
  {
    id: "thoth",
    name: "Thoth",
    title: "📜 Bóg Wiedzy i Pisemnictwa",
    description:
      "𓅝 Asystent AI do analizy tekstu i dokumentów. Odpowiada na pytania, analizuje treść, tłumaczy i wyjaśnia.",
    model: "mistral-7b-q4 (quantized for 6GB VRAM)",
    icon: "📜",
    color: "from-cyan-600 via-blue-700 to-blue-900",
    status: "inactive",
    port: 8001,
    domain: "text-processing",
  },
  {
    id: "ra",
    name: "Ra",
    title: "☀️ Bóg Światła i Kreacji",
    description:
      "𓇳 Bóg światła i wizualnej kreacji. Łączy FLUX, Stable Diffusion, 3D modeling, upscaling i edycję obrazów.",
    model: "flux1 + sd-2.1 + tripo-sr + real-esrgan + rvm",
    icon: "☀️",
    color: "from-amber-500 via-orange-600 to-red-700",
    status: "inactive",
    port: 8002,
    domain: "graphics",
  },
  {
    id: "isis",
    name: "Isis",
    title: "✨ Bogini Uzdrawiania",
    description:
      "𓇋𓇋 Wielka uzdrowicielka i medyk bogów. Specjalizuje się w analizie medycznej poprzez Monai, Mistral i LLaVa.",
    model: "monai + mistral-13b + llava-13b",
    icon: "✨",
    color: "from-purple-600 via-pink-600 to-rose-600",
    status: "inactive",
    port: 8003,
    domain: "medical",
  },
  {
    id: "bastet",
    name: "Bastet",
    title: "🐱 Bogini Wzroku i Ochrony",
    description:
      "𓃠 Bogini-kotka, strażniczka domu. Computer vision, rozpoznawanie twarzy, detekcja obiektów i analiza póz.",
    model: "insightface + mmpose + mmdetection + llava-13b",
    icon: "🐱",
    color: "from-yellow-600 via-amber-700 to-orange-800",
    status: "inactive",
    port: 8004,
    domain: "vision",
  },
  {
    id: "maat",
    name: "Maat",
    title: "⚖️ Bogini Sprawiedliwości",
    description: "𓆄 Bogini prawdy, sprawiedliwości i porządku. Analizuje dokumenty prawne, kontrakty i compliance.",
    model: "mistral-13b + xlm-roberta + donut",
    icon: "⚖️",
    color: "from-blue-600 via-indigo-700 to-purple-800",
    status: "inactive",
    port: 8005,
    domain: "legal",
  },
  {
    id: "khnum",
    name: "Khnum",
    title: "💰 Bóg Bogactwa i Handlu",
    description:
      "𓎛 Bóg-twórca, patron rzemiosła i bogactwa. Analiza finansowa, wizualizacja danych i systemy rekomendacji.",
    model: "mistral-13b + plotgpt-7b + recbole",
    icon: "💰",
    color: "from-green-600 via-emerald-700 to-teal-800",
    status: "inactive",
    port: 8006,
    domain: "finance",
  },
];

export const GodsPanel: React.FC = () => {
  const [gods, setGods] = useState<God[]>(EGYPTIAN_GODS);
  const [selectedGod, setSelectedGod] = useState<string | null>(null);
  const [awakeningGod, setAwakeningGod] = useState<string | null>(null);
  const [awakeningProgress, setAwakeningProgress] = useState(0);
  const [awakeningStage, setAwakeningStage] = useState<"downloading" | "extracting" | "loading" | "warming" | "ready">(
    "downloading"
  );

  useEffect(() => {
    // Sprawdź status każdego boga
    const checkStatus = async () => {
      const updatedGods = await Promise.all(
        gods.map(async (god) => {
          try {
            const response = await fetch(`/api/gods/${god.id}/health`, {
              signal: AbortSignal.timeout(3000),
            });
            if (response.ok) {
              // Pobierz metryki
              const metrics = await fetchGodMetrics(god.id);
              return { ...god, status: "active" as const, metrics };
            }
            return { ...god, status: "inactive" as const };
          } catch {
            return { ...god, status: "inactive" as const };
          }
        })
      );
      setGods(updatedGods);
    };

    checkStatus();
    const interval = setInterval(checkStatus, 10000); // Co 10s
    return () => clearInterval(interval);
  }, []);

  const fetchGodMetrics = async (godId: string) => {
    try {
      const response = await fetch(`/api/gods/${godId}/metrics`);
      if (response.ok) {
        return await response.json();
      }
    } catch (error) {
      console.error(`Failed to fetch metrics for ${godId}:`, error);
    }
    return undefined;
  };

  const handleGodSelect = (godId: string) => {
    setSelectedGod(godId === selectedGod ? null : godId);
  };

  const handleStartGod = async (godId: string) => {
    // Sprawdź czy inny bóg jest aktywny - tylko jeden naraz!
    const activeGod = gods.find((g) => g.status === "active");
    if (activeGod && activeGod.id !== godId) {
      await handleStopGod(activeGod.id);
      await new Promise((resolve) => setTimeout(resolve, 1000));
    }

    setAwakeningGod(godId);
    setAwakeningProgress(0);
    setAwakeningStage("downloading");
    setGods((prev) => prev.map((g) => (g.id === godId ? { ...g, status: "loading" } : g)));

    try {
      // Progress animation
      const progressInterval = setInterval(() => {
        setAwakeningProgress((prev) => {
          if (prev < 95) {
            const newProgress = prev + Math.random() * 10;
            if (newProgress >= 80) setAwakeningStage("warming");
            else if (newProgress >= 60) setAwakeningStage("loading");
            else if (newProgress >= 30) setAwakeningStage("extracting");
            return Math.min(newProgress, 95);
          }
          return prev;
        });
      }, 500);

      const response = await fetch(`/api/gods/${godId}/wake`, {
        method: "POST",
      });

      clearInterval(progressInterval);

      if (response.ok) {
        setAwakeningProgress(100);
        setAwakeningStage("ready");
        await new Promise((resolve) => setTimeout(resolve, 1000));

        setGods((prev) => prev.map((g) => (g.id === godId ? { ...g, status: "active" } : g)));
        setAwakeningGod(null);
      } else {
        throw new Error("Failed to wake god");
      }
    } catch (error) {
      console.error(`Failed to wake ${godId}:`, error);
      setGods((prev) => prev.map((g) => (g.id === godId ? { ...g, status: "inactive" } : g)));
      setAwakeningGod(null);
    }
  };

  const handleStopGod = async (godId: string) => {
    try {
      await fetch(`/api/gods/${godId}/sleep`, { method: "POST" });
      setGods((prev) => prev.map((g) => (g.id === godId ? { ...g, status: "inactive" } : g)));
    } catch (error) {
      console.error(`Failed to sleep ${godId}:`, error);
    }
  };

  const handleDemo = (godId: string) => {
    // Otwórz dedykowany interface w nowym oknie
    const demoUrls: Record<string, string> = {
      thoth: `/demo/thoth`,
      ra: `/demo/ra`,
      isis: `/demo/isis`,
      bastet: `/demo/bastet`,
      maat: `/demo/maat`,
      khnum: `/demo/khnum`,
    };
    window.open(demoUrls[godId] || `/demo/${godId}`, "_blank", "width=1200,height=800");
  };

  const handleBenchmark = (godId: string) => {
    // Otwórz benchmark interface w nowym oknie
    window.open(`/benchmark/${godId}`, "_blank", "width=1000,height=700");
  };

  const selectedGodData = gods.find((g) => g.id === selectedGod);

  return (
    <>
      {/* Awakening Progress Modal */}
      {awakeningGod && (
        <GodAwakeningProgress
          godName={gods.find((g) => g.id === awakeningGod)?.name || ""}
          progress={awakeningProgress}
          stage={awakeningStage}
        />
      )}

      <div className="w-full bg-gradient-to-b from-black via-gray-900 to-black py-16 px-4 relative overflow-hidden">
        {/* Hieroglyph Background */}
        <div className="absolute inset-0 opacity-5 text-amber-500 text-9xl select-none pointer-events-none">
          <div className="absolute top-10 left-10">𓂀</div>
          <div className="absolute top-20 right-20">𓁹</div>
          <div className="absolute bottom-20 left-1/4">𓆣</div>
          <div className="absolute bottom-10 right-1/3">𓃭</div>
        </div>

        <div className="max-w-7xl mx-auto relative z-10">
          {/* Header */}
          <div className="text-center mb-12">
            <div className="inline-block mb-6">
              <div className="text-7xl mb-2">⚱️</div>
              <div className="h-1 w-32 bg-gradient-to-r from-amber-400 via-yellow-500 to-amber-600 mx-auto rounded-full"></div>
            </div>
            <h2 className="text-5xl md:text-6xl font-bold mb-4 bg-gradient-to-r from-amber-400 via-yellow-500 to-amber-600 bg-clip-text text-transparent">
              Panteon Egipskich Bogów AI
            </h2>
            <p className="text-xl text-gray-400 mb-2">Wybierz boga, który pomoże Ci w Twojej podróży</p>
            <p className="text-sm text-amber-500/70">
              𓋹 Każdy bóg reprezentuje unikalny model AI z własną domeną wiedzy 𓋹
            </p>
          </div>

          {/* Gods Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-12">
            {gods.map((god) => (
              <GodCard
                key={god.id}
                god={god}
                isSelected={selectedGod === god.id}
                onSelect={() => handleGodSelect(god.id)}
                onStart={() => handleStartGod(god.id)}
                onStop={() => handleStopGod(god.id)}
                onDemo={() => handleDemo(god.id)}
                onBenchmark={() => handleBenchmark(god.id)}
              />
            ))}
          </div>

          {/* Selected God Details */}
          {selectedGodData && (
            <div className="bg-gradient-to-br from-gray-800 via-gray-900 to-black rounded-2xl p-8 border-2 border-amber-500/30 shadow-2xl shadow-amber-500/20">
              <div className="flex items-center justify-between mb-6">
                <div className="flex items-center gap-4">
                  <span className="text-6xl">{selectedGodData.icon}</span>
                  <div>
                    <h3 className="text-3xl font-bold text-amber-400">{selectedGodData.name}</h3>
                    <p className="text-gray-400">{selectedGodData.title}</p>
                  </div>
                </div>
                <div
                  className={`px-4 py-2 rounded-full text-sm font-semibold ${
                    selectedGodData.status === "active"
                      ? "bg-green-500/20 text-green-400"
                      : selectedGodData.status === "loading"
                      ? "bg-yellow-500/20 text-yellow-400"
                      : "bg-gray-500/20 text-gray-400"
                  }`}
                >
                  {selectedGodData.status.toUpperCase()}
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {/* Info */}
                <div className="bg-black/50 rounded-lg p-6 border border-amber-500/20">
                  <h4 className="text-lg font-semibold text-amber-400 mb-4">📋 Informacje</h4>
                  <div className="space-y-2 text-sm font-mono">
                    <div className="flex justify-between">
                      <span className="text-gray-400">Model:</span>
                      <span className="text-green-400">{selectedGodData.model}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-400">Port:</span>
                      <span className="text-green-400">{selectedGodData.port}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-gray-400">Domena:</span>
                      <span className="text-green-400">{selectedGodData.domain}</span>
                    </div>
                  </div>
                </div>

                {/* Metrics */}
                {selectedGodData.metrics && (
                  <div className="bg-black/50 rounded-lg p-6 border border-amber-500/20">
                    <h4 className="text-lg font-semibold text-amber-400 mb-4">📊 Metryki</h4>
                    <div className="space-y-2 text-sm font-mono">
                      <div className="flex justify-between">
                        <span className="text-gray-400">Czas odpowiedzi:</span>
                        <span className="text-cyan-400">{selectedGodData.metrics.responseTime}ms</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-400">Tokens/s:</span>
                        <span className="text-cyan-400">{selectedGodData.metrics.tokensPerSecond}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-400">GPU:</span>
                        <span className="text-cyan-400">{selectedGodData.metrics.gpuUtilization}%</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-gray-400">RAM:</span>
                        <span className="text-cyan-400">{selectedGodData.metrics.memoryUsed}MB</span>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </>
  );
};
