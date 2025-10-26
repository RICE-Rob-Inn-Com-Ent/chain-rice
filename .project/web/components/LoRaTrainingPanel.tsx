"use client";
import React, { useState } from "react";

interface LoRaAdapter {
  id: string;
  name: string;
  baseGodId: string;
  baseGodName: string;
  status: "pending" | "training" | "completed" | "failed";
  progress: number;
  currentEpoch: number;
  totalEpochs: number;
  loss: number;
  accuracy: number;
}

export const LoRaTrainingPanel: React.FC = () => {
  const [adapters, setAdapters] = useState<LoRaAdapter[]>([]);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [newAdapter, setNewAdapter] = useState({
    name: "",
    baseGodId: "thoth",
    rank: 8,
    alpha: 16,
    learningRate: 0.0001,
    batchSize: 4,
    epochs: 3,
    targetModules: ["q_proj", "v_proj"],
    dataset: null as File | null,
    description: "",
  });

  const handleCreateAdapter = async () => {
    try {
      const response = await fetch("/api/lora/create", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(newAdapter),
      });

      if (response.ok) {
        const adapter = await response.json();
        setAdapters([...adapters, adapter]);
        setShowCreateForm(false);
        // Reset form
        setNewAdapter({
          name: "",
          baseGodId: "thoth",
          rank: 8,
          alpha: 16,
          learningRate: 0.0001,
          batchSize: 4,
          epochs: 3,
          targetModules: ["q_proj", "v_proj"],
        });
      }
    } catch (error) {
      console.error("Failed to create LoRa adapter:", error);
    }
  };

  const handleStartTraining = async (adapterId: string) => {
    try {
      await fetch(`/api/lora/${adapterId}/train`, { method: "POST" });
      setAdapters((prev) => prev.map((a) => (a.id === adapterId ? { ...a, status: "training" } : a)));
    } catch (error) {
      console.error("Failed to start training:", error);
    }
  };

  const handleStopTraining = async (adapterId: string) => {
    try {
      await fetch(`/api/lora/${adapterId}/stop`, { method: "POST" });
      setAdapters((prev) => prev.map((a) => (a.id === adapterId ? { ...a, status: "pending" } : a)));
    } catch (error) {
      console.error("Failed to stop training:", error);
    }
  };

  return (
    <div className="w-full bg-gradient-to-b from-black via-purple-950/20 to-black py-16 px-4">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="text-6xl mb-4">🔮</div>
          <h2 className="text-5xl font-bold mb-4 bg-gradient-to-r from-purple-400 via-pink-500 to-purple-600 bg-clip-text text-transparent">
            LoRa Training Temple
          </h2>
          <p className="text-xl text-gray-400 mb-2">Trenuj swoich bogów z własną wiedzą</p>
          <p className="text-sm text-purple-400/70">
            ⚗️ LoRa (Low-Rank Adaptation) - Fine-tuning bez pełnego przekształcenia modelu
          </p>
        </div>

        {/* What is LoRa? */}
        <div className="bg-gradient-to-br from-purple-900/30 to-gray-900 rounded-2xl p-8 mb-8 border border-purple-500/30">
          <h3 className="text-2xl font-bold text-purple-400 mb-4">📚 Co to jest LoRa?</h3>
          <div className="grid md:grid-cols-2 gap-6 text-gray-300">
            <div>
              <h4 className="text-lg font-semibold text-purple-300 mb-2">✨ Koncepcja</h4>
              <p className="text-sm leading-relaxed">
                LoRa (Low-Rank Adaptation) to technika fine-tuningu, która dodaje małe, treningowalne adaptery do
                zamrożonego modelu bazowego. Zamiast trenować miliardy parametrów, LoRa uczy tylko kilka milionów,
                oszczędzając pamięć i czas.
              </p>
            </div>
            <div>
              <h4 className="text-lg font-semibold text-purple-300 mb-2">⚙️ Jak działa?</h4>
              <p className="text-sm leading-relaxed">
                LoRa dekompozycja macierzy wag na dwie mniejsze macierze (rank decomposition). Trenujemy tylko te małe
                macierze, podczas gdy oryginalny model pozostaje niezmieniony. Wynik: specjalizacja bez utraty ogólnej
                wiedzy.
              </p>
            </div>
            <div>
              <h4 className="text-lg font-semibold text-purple-300 mb-2">🎯 Parametry</h4>
              <ul className="text-sm space-y-1">
                <li>
                  <span className="text-cyan-400">Rank (r):</span> Wymiar adaptacji (4-64)
                </li>
                <li>
                  <span className="text-cyan-400">Alpha (α):</span> Scaling factor (2r típicamente)
                </li>
                <li>
                  <span className="text-cyan-400">Target Modules:</span> Które warstwy trenować
                </li>
              </ul>
            </div>
            <div>
              <h4 className="text-lg font-semibold text-purple-300 mb-2">💎 Korzyści</h4>
              <ul className="text-sm space-y-1">
                <li>⚡ Szybkie trenowanie (kilka minut vs godziny)</li>
                <li>💾 Mała wielkość (kilka MB vs GB)</li>
                <li>🔄 Można przełączać adaptery</li>
                <li>🎨 Wiele specjalizacji na 1 modelu</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Create Button */}
        <div className="mb-8">
          <button
            onClick={() => setShowCreateForm(!showCreateForm)}
            className="bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white px-6 py-3 rounded-lg font-semibold shadow-lg hover:shadow-purple-500/50 transition-all duration-200"
          >
            {showCreateForm ? "❌ Anuluj" : "➕ Stwórz Nowy Adapter"}
          </button>
        </div>

        {/* Create Form */}
        {showCreateForm && (
          <div className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-2xl p-8 mb-8 border border-purple-500/30">
            <h3 className="text-2xl font-bold text-purple-400 mb-6">Konfiguracja LoRa Adaptera</h3>
            <div className="grid md:grid-cols-2 gap-6">
              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">Nazwa Adaptera</label>
                <input
                  type="text"
                  value={newAdapter.name}
                  onChange={(e) => setNewAdapter({ ...newAdapter, name: e.target.value })}
                  className="w-full bg-black/50 border border-purple-500/30 rounded-lg px-4 py-2 text-white focus:border-purple-500 focus:outline-none"
                  placeholder="np. medical-expert"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">Bazowy Bóg</label>
                <select
                  value={newAdapter.baseGodId}
                  onChange={(e) => setNewAdapter({ ...newAdapter, baseGodId: e.target.value })}
                  className="w-full bg-black/50 border border-purple-500/30 rounded-lg px-4 py-2 text-white focus:border-purple-500 focus:outline-none"
                >
                  <option value="thoth">📜 Thoth - Text/Documents</option>
                  <option value="ra">☀️ Ra - Graphics/Vision</option>
                  <option value="isis">✨ Isis - Medical</option>
                  <option value="bastet">🐱 Bastet - Computer Vision</option>
                  <option value="maat">⚖️ Maat - Legal</option>
                  <option value="khnum">💰 Khnum - Finance</option>
                </select>
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-semibold text-gray-300 mb-2">Opis Specjalizacji</label>
                <textarea
                  value={newAdapter.description}
                  onChange={(e) => setNewAdapter({ ...newAdapter, description: e.target.value })}
                  className="w-full bg-black/50 border border-purple-500/30 rounded-lg px-4 py-2 text-white focus:border-purple-500 focus:outline-none min-h-[80px]"
                  placeholder="Opisz czego ten adapter ma nauczyć boga... np. 'Specjalizacja w diagnostyce obrazów medycznych płuc'"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Rank (r) <span className="text-xs text-gray-500">- wyższa = więcej parametrów</span>
                </label>
                <input
                  type="number"
                  value={newAdapter.rank}
                  onChange={(e) => setNewAdapter({ ...newAdapter, rank: parseInt(e.target.value) })}
                  className="w-full bg-black/50 border border-purple-500/30 rounded-lg px-4 py-2 text-white focus:border-purple-500 focus:outline-none"
                  min="4"
                  max="64"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Alpha (α) <span className="text-xs text-gray-500">- zazwyczaj 2 × rank</span>
                </label>
                <input
                  type="number"
                  value={newAdapter.alpha}
                  onChange={(e) => setNewAdapter({ ...newAdapter, alpha: parseInt(e.target.value) })}
                  className="w-full bg-black/50 border border-purple-500/30 rounded-lg px-4 py-2 text-white focus:border-purple-500 focus:outline-none"
                  min="8"
                  max="128"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">Learning Rate</label>
                <input
                  type="number"
                  value={newAdapter.learningRate}
                  onChange={(e) => setNewAdapter({ ...newAdapter, learningRate: parseFloat(e.target.value) })}
                  className="w-full bg-black/50 border border-purple-500/30 rounded-lg px-4 py-2 text-white focus:border-purple-500 focus:outline-none"
                  step="0.0001"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">Epochs</label>
                <input
                  type="number"
                  value={newAdapter.epochs}
                  onChange={(e) => setNewAdapter({ ...newAdapter, epochs: parseInt(e.target.value) })}
                  className="w-full bg-black/50 border border-purple-500/30 rounded-lg px-4 py-2 text-white focus:border-purple-500 focus:outline-none"
                  min="1"
                  max="10"
                />
              </div>

              <div className="md:col-span-2">
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Training Dataset <span className="text-xs text-gray-500">(JSON, JSONL, CSV, TXT)</span>
                </label>
                <label className="block cursor-pointer">
                  <div
                    className={`border-2 border-dashed rounded-lg p-6 text-center transition-colors ${
                      newAdapter.dataset
                        ? "border-purple-500 bg-purple-900/20"
                        : "border-purple-500/30 hover:border-purple-500/60"
                    }`}
                  >
                    {newAdapter.dataset ? (
                      <div>
                        <div className="text-4xl mb-2">✅</div>
                        <p className="text-sm text-purple-400 font-semibold">{newAdapter.dataset.name}</p>
                        <p className="text-xs text-gray-500 mt-1">{(newAdapter.dataset.size / 1024).toFixed(2)} KB</p>
                      </div>
                    ) : (
                      <div>
                        <div className="text-4xl mb-2 opacity-50">📁</div>
                        <p className="text-gray-400 text-sm">Kliknij aby wgrać dataset</p>
                        <p className="text-xs text-gray-600 mt-1">
                          Format: {"{"}"prompt": "...", "response": "..."{"}"}
                        </p>
                      </div>
                    )}
                  </div>
                  <input
                    type="file"
                    onChange={(e) => {
                      if (e.target.files && e.target.files[0]) {
                        setNewAdapter({ ...newAdapter, dataset: e.target.files[0] });
                      }
                    }}
                    accept=".json,.jsonl,.csv,.txt"
                    className="hidden"
                  />
                </label>
                {newAdapter.dataset && (
                  <button
                    onClick={() => setNewAdapter({ ...newAdapter, dataset: null })}
                    className="mt-2 text-sm text-red-400 hover:text-red-300 transition-colors"
                  >
                    ✕ Usuń dataset
                  </button>
                )}
              </div>
            </div>

            {/* Advanced Options */}
            <details className="mt-6 bg-black/30 rounded-lg p-4 border border-purple-500/20">
              <summary className="cursor-pointer font-semibold text-purple-400 mb-4">⚙️ Zaawansowane Opcje</summary>
              <div className="grid md:grid-cols-3 gap-4 mt-4">
                <div>
                  <label className="block text-xs font-semibold text-gray-400 mb-1">Batch Size</label>
                  <input
                    type="number"
                    value={newAdapter.batchSize}
                    onChange={(e) => setNewAdapter({ ...newAdapter, batchSize: parseInt(e.target.value) })}
                    className="w-full bg-black/50 border border-purple-500/30 rounded px-3 py-1.5 text-sm text-white"
                    min="1"
                    max="32"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-400 mb-1">Warmup Steps</label>
                  <input
                    type="number"
                    defaultValue={100}
                    className="w-full bg-black/50 border border-purple-500/30 rounded px-3 py-1.5 text-sm text-white"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-gray-400 mb-1">Weight Decay</label>
                  <input
                    type="number"
                    defaultValue={0.01}
                    step="0.01"
                    className="w-full bg-black/50 border border-purple-500/30 rounded px-3 py-1.5 text-sm text-white"
                  />
                </div>
              </div>
            </details>

            <div className="mt-6 flex gap-4">
              <button
                onClick={handleCreateAdapter}
                disabled={!newAdapter.name || !newAdapter.dataset}
                className="flex-1 bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 disabled:from-gray-600 disabled:to-gray-700 text-white px-8 py-3 rounded-lg font-semibold shadow-lg transition-all duration-200 disabled:cursor-not-allowed"
              >
                🚀 Stwórz i Zacznij Trenowanie
              </button>
              <button
                onClick={() => setShowCreateForm(false)}
                className="px-6 py-3 bg-gray-700 hover:bg-gray-600 text-white rounded-lg font-semibold transition-all"
              >
                Anuluj
              </button>
            </div>
          </div>
        )}

        {/* Adapters List */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {adapters.map((adapter) => (
            <div
              key={adapter.id}
              className="bg-gradient-to-br from-gray-800 to-gray-900 rounded-xl p-6 border border-purple-500/30"
            >
              <div className="flex items-center justify-between mb-4">
                <h4 className="text-lg font-bold text-purple-400">{adapter.name}</h4>
                <div
                  className={`px-3 py-1 rounded-full text-xs font-semibold ${
                    adapter.status === "training"
                      ? "bg-blue-500/20 text-blue-400"
                      : adapter.status === "completed"
                      ? "bg-green-500/20 text-green-400"
                      : adapter.status === "failed"
                      ? "bg-red-500/20 text-red-400"
                      : "bg-gray-500/20 text-gray-400"
                  }`}
                >
                  {adapter.status}
                </div>
              </div>

              <div className="text-sm text-gray-400 mb-4">
                <div className="flex justify-between mb-2">
                  <span>Base God:</span>
                  <span className="text-purple-300">{adapter.baseGodName}</span>
                </div>
                <div className="flex justify-between mb-2">
                  <span>Epoch:</span>
                  <span className="text-purple-300">
                    {adapter.currentEpoch} / {adapter.totalEpochs}
                  </span>
                </div>
                {adapter.status === "training" && (
                  <>
                    <div className="flex justify-between mb-2">
                      <span>Loss:</span>
                      <span className="text-cyan-400">{adapter.loss.toFixed(4)}</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Accuracy:</span>
                      <span className="text-cyan-400">{(adapter.accuracy * 100).toFixed(2)}%</span>
                    </div>
                  </>
                )}
              </div>

              {/* Progress Bar */}
              {adapter.status === "training" && (
                <div className="mb-4">
                  <div className="w-full bg-gray-700 rounded-full h-2">
                    <div
                      className="bg-gradient-to-r from-purple-600 to-pink-600 h-2 rounded-full transition-all duration-300"
                      style={{ width: `${adapter.progress}%` }}
                    />
                  </div>
                  <p className="text-xs text-gray-400 text-center mt-1">{adapter.progress}%</p>
                </div>
              )}

              {/* Controls */}
              <div className="flex gap-2">
                {adapter.status === "training" ? (
                  <button
                    onClick={() => handleStopTraining(adapter.id)}
                    className="flex-1 bg-red-600 hover:bg-red-700 text-white text-sm py-2 rounded-lg transition-colors"
                  >
                    ⏹️ Stop
                  </button>
                ) : adapter.status === "completed" ? (
                  <button className="flex-1 bg-green-600 hover:bg-green-700 text-white text-sm py-2 rounded-lg transition-colors">
                    ✅ Zastosuj
                  </button>
                ) : (
                  <button
                    onClick={() => handleStartTraining(adapter.id)}
                    className="flex-1 bg-purple-600 hover:bg-purple-700 text-white text-sm py-2 rounded-lg transition-colors"
                  >
                    ▶️ Start
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>

        {adapters.length === 0 && !showCreateForm && (
          <div className="text-center py-12">
            <div className="text-6xl mb-4">🌟</div>
            <p className="text-gray-400 text-lg mb-2">Brak adapterów LoRa</p>
            <p className="text-gray-600 text-sm">
              Stwórz pierwszy adapter, aby dostosować swoich bogów do specyficznych zadań!
            </p>

            {/* Quick Start Guide */}
            <div className="mt-8 max-w-2xl mx-auto bg-gradient-to-br from-purple-900/20 to-gray-900/50 rounded-xl p-6 border border-purple-500/20">
              <h4 className="text-lg font-bold text-purple-400 mb-4">🚀 Quick Start</h4>
              <div className="text-left space-y-3 text-sm text-gray-300">
                <div className="flex gap-3">
                  <span className="text-purple-400 font-bold">1.</span>
                  <span>Przygotuj dataset w formacie JSON: {`[{"prompt": "...", "response": "..."}]`}</span>
                </div>
                <div className="flex gap-3">
                  <span className="text-purple-400 font-bold">2.</span>
                  <span>Kliknij "Stwórz Nowy Adapter" i wybierz bazowego boga</span>
                </div>
                <div className="flex gap-3">
                  <span className="text-purple-400 font-bold">3.</span>
                  <span>Wgraj swój dataset i skonfiguruj parametry trenowania</span>
                </div>
                <div className="flex gap-3">
                  <span className="text-purple-400 font-bold">4.</span>
                  <span>Rozpocznij trenowanie i obserwuj postępy w czasie rzeczywistym</span>
                </div>
                <div className="flex gap-3">
                  <span className="text-purple-400 font-bold">5.</span>
                  <span>Po zakończeniu, zastosuj adapter do swojego boga</span>
                </div>
              </div>
            </div>

            {/* Example Datasets */}
            <div className="mt-6 max-w-2xl mx-auto">
              <h4 className="text-sm font-bold text-gray-400 mb-3">💡 Przykładowe Use Cases:</h4>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs">
                {[
                  { god: "Thoth", use: "Legal documents translation", icon: "📜" },
                  { god: "Isis", use: "Medical diagnosis support", icon: "✨" },
                  { god: "Maat", use: "Contract clause extraction", icon: "⚖️" },
                  { god: "Khnum", use: "Financial report analysis", icon: "💰" },
                  { god: "Bastet", use: "Custom object detection", icon: "🐱" },
                  { god: "Ra", use: "Style-specific image gen", icon: "☀️" },
                ].map((example, idx) => (
                  <div
                    key={idx}
                    className="bg-gray-800/50 rounded-lg p-3 border border-gray-700 hover:border-purple-500/30 transition-colors"
                  >
                    <div className="text-lg mb-1">{example.icon}</div>
                    <div className="font-semibold text-gray-300">{example.god}</div>
                    <div className="text-gray-500">{example.use}</div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
