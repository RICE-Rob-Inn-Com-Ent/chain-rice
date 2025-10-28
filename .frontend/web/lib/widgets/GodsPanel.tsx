"use client";

import { useState, useEffect } from "react";
import { Card } from "../base/Card";
import { Button } from "../base/Button";
import GradientText from "../base/GradientText";
import Reveal from "../base/Reveal";

interface GodStatus {
  god_id: string;
  name: string;
  icon: string;
  status: "offline" | "cpu" | "loading" | "gpu";
  gpu_allocated: boolean;
  progress?: number;
  estimated_time?: number;
}

// God Manager API URL - zmień jeśli używasz innego portu
const GOD_MANAGER_API = process.env.NEXT_PUBLIC_GOD_MANAGER_API || "http://localhost:8100";

export default function GodsPanel() {
  const [gods, setGods] = useState<GodStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fetch gods status
  const fetchGods = async () => {
    try {
      const response = await fetch(`${GOD_MANAGER_API}/gods`);
      if (!response.ok) throw new Error("Failed to fetch gods");
      const data = await response.json();
      setGods(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
      console.error("Error fetching gods:", err);
    } finally {
      setLoading(false);
    }
  };

  // Wake god (load to GPU)
  const wakeGod = async (godId: string) => {
    try {
      const response = await fetch(`${GOD_MANAGER_API}/wake/${godId}`, {
        method: "POST",
      });
      if (!response.ok) throw new Error("Failed to wake god");

      // Start polling for progress
      const pollInterval = setInterval(() => {
        fetchGods();
      }, 2000);

      // Stop polling after 2 minutes
      setTimeout(() => clearInterval(pollInterval), 120000);
    } catch (err) {
      alert("Error: " + (err instanceof Error ? err.message : "Unknown error"));
    }
  };

  // Sleep god (free GPU)
  const sleepGod = async (godId: string) => {
    try {
      const response = await fetch(`${GOD_MANAGER_API}/sleep/${godId}`, {
        method: "POST",
      });
      if (!response.ok) throw new Error("Failed to sleep god");
      fetchGods();
    } catch (err) {
      alert("Error: " + (err instanceof Error ? err.message : "Unknown error"));
    }
  };

  // Open demo
  const openDemo = (godId: string) => {
    const demoUrls: Record<string, string> = {
      thoth: "http://localhost:8001",
      ra: "http://localhost:8002",
      isis: "http://localhost:8003",
      bastet: "http://localhost:8004",
      maat: "http://localhost:8005",
      khnum: "http://localhost:8006",
    };

    if (demoUrls[godId]) {
      window.open(demoUrls[godId], "_blank");
    }
  };

  // Get status color and label
  const getStatusInfo = (status: string) => {
    switch (status) {
      case "gpu":
        return { color: "text-green-500", bg: "bg-green-500/20", label: "🎮 GPU LOADED" };
      case "cpu":
        return { color: "text-yellow-500", bg: "bg-yellow-500/20", label: "💾 ONLINE (CPU)" };
      case "loading":
        return { color: "text-blue-500", bg: "bg-blue-500/20", label: "⏳ LOADING..." };
      case "offline":
      default:
        return { color: "text-red-500", bg: "bg-red-500/20", label: "● OFFLINE" };
    }
  };

  // Auto-refresh every 5 seconds
  useEffect(() => {
    fetchGods();
    const interval = setInterval(fetchGods, 5000);
    return () => clearInterval(interval);
  }, []);

  if (loading) {
    return (
      <section className="py-20 px-4">
        <div className="max-w-7xl mx-auto text-center">
          <p className="text-gray-400">Sprawdzam status modeli...</p>
        </div>
      </section>
    );
  }

  if (error) {
    return (
      <section className="py-20 px-4">
        <div className="max-w-7xl mx-auto text-center">
          <p className="text-red-400">Błąd połączenia z God Manager: {error}</p>
          <p className="text-gray-500 text-sm mt-2">Upewnij się że God Manager działa na porcie 8100</p>
        </div>
      </section>
    );
  }

  return (
    <section id="gods" className="py-20 px-4">
      <div className="max-w-7xl mx-auto">
        <Reveal>
          <h2 className="text-4xl font-bold text-center mb-4">
            <GradientText>Nasze Modele AI</GradientText>
          </h2>
          <p className="text-center text-gray-400 mb-12">
            Każdy model jest zoptymalizowany pod kątem wydajności i działa na GPU z 6-8GB VRAM
          </p>
        </Reveal>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {gods.map((god, index) => {
            const statusInfo = getStatusInfo(god.status);

            return (
              <Reveal key={god.god_id} delay={index * 0.1}>
                <Card className="bg-gradient-to-br from-gray-900 to-black border border-amber-900/30 p-6">
                  {/* Header */}
                  <div className="flex items-start justify-between mb-4">
                    <div className="flex items-center gap-3">
                      <span className="text-5xl">{god.icon}</span>
                      <div>
                        <h3 className="text-xl font-bold text-white">{god.name}</h3>
                        <div
                          className={`inline-flex items-center gap-2 px-2 py-1 rounded-full ${statusInfo.bg} ${statusInfo.color} text-sm font-semibold mt-1`}
                        >
                          {statusInfo.label}
                        </div>
                      </div>
                    </div>
                  </div>

                  {/* Progress bar if loading */}
                  {god.status === "loading" && (
                    <div className="mb-4">
                      <div className="w-full bg-gray-700 rounded-full h-4 overflow-hidden">
                        <div
                          className="bg-gradient-to-r from-blue-500 to-cyan-500 h-full transition-all duration-500 flex items-center justify-center text-xs font-bold"
                          style={{ width: `${god.progress || 0}%` }}
                        >
                          {god.progress || 0}%
                        </div>
                      </div>
                      <p className="text-gray-400 text-sm mt-2 text-center">
                        {god.estimated_time ? `Est. ${god.estimated_time}s remaining` : "Loading model..."}
                      </p>
                    </div>
                  )}

                  {/* Actions */}
                  <div className="flex flex-col gap-2">
                    <Button
                      onClick={() => wakeGod(god.god_id)}
                      disabled={god.status === "loading" || god.status === "gpu"}
                      className="w-full bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 disabled:opacity-50"
                    >
                      ⚡ Wake & Load to GPU
                    </Button>

                    <div className="grid grid-cols-2 gap-2">
                      <Button
                        onClick={() => sleepGod(god.god_id)}
                        disabled={god.status !== "gpu"}
                        className="bg-gray-700 hover:bg-gray-600 disabled:opacity-50 text-sm"
                      >
                        💤 Sleep
                      </Button>

                      <Button
                        onClick={() => openDemo(god.god_id)}
                        disabled={god.status !== "gpu"}
                        className="bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-700 hover:to-orange-700 disabled:opacity-50 text-sm"
                      >
                        🚀 Demo
                      </Button>
                    </div>
                  </div>
                </Card>
              </Reveal>
            );
          })}
        </div>
      </div>
    </section>
  );
}
