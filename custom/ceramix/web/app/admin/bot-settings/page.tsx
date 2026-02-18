"use client";

import { useState, useEffect } from "react";
import { Save, RefreshCw, TestTube, Settings2 } from "lucide-react";

type BotConfig = {
  bot_type: "accounting" | "client_management";
  name: string;
  description: string;
  enabled: boolean;
  model: string;
  temperature: number;
  max_tokens: number;
  use_lora: boolean;
  lora_adapter: string;
  context_window: number;
};

export default function BotSettingsPage() {
  const [configs, setConfigs] = useState<BotConfig[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    loadConfigs();
  }, []);

  const loadConfigs = async () => {
    try {
      setLoading(true);
      const response = await fetch("/api/cerai/bot-config");
      if (!response.ok) {
        throw new Error("Failed to load configs");
      }
      const data = await response.json();
      setConfigs(data.configs || []);
    } catch (error) {
      console.error("Error loading configs:", error);
      // Fallback to empty array on error
      setConfigs([]);
    } finally {
      setLoading(false);
    }
  };

  const saveConfig = async (config: BotConfig) => {
    try {
      setSaving(true);
      const response = await fetch(`/api/cerai/bot-config/${config.bot_type}`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name: config.name,
          description: config.description,
          enabled: config.enabled,
          model: config.model,
          temperature: config.temperature,
          max_tokens: config.max_tokens,
          use_lora: config.use_lora,
          lora_adapter: config.lora_adapter,
          context_window: config.context_window,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || "Failed to save config");
      }

      // Reload configs to get updated data
      await loadConfigs();
      alert("Konfiguracja zapisana!");
    } catch (error) {
      console.error("Error saving config:", error);
      alert(`Błąd podczas zapisywania: ${(error as Error).message}`);
    } finally {
      setSaving(false);
    }
  };

  const testBot = async (botType: string) => {
    try {
      const response = await fetch(`/api/cerai/bot-config/${botType}/test`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || "Test failed");
      }

      const data = await response.json();
      if (data.status === "success") {
        alert(`Bot działa poprawnie! Model: ${data.model}`);
      } else {
        alert(`Bot zwrócił status: ${data.status} - ${data.message}`);
      }
    } catch (error) {
      alert("Błąd: " + (error as Error).message);
    }
  };

  const updateConfig = (index: number, updates: Partial<BotConfig>) => {
    const newConfigs = [...configs];
    newConfigs[index] = { ...newConfigs[index], ...updates };
    setConfigs(newConfigs);
  };

  return (
    <div className="p-6">
      <div className="mb-8">
        <h1 className="font-display text-4xl text-ivory-100">Ustawienia Botów</h1>
        <p className="mt-2 text-ivory-100/70">
          Konfiguruj parametry i zachowanie botów AI
        </p>
      </div>

      {loading ? (
        <div className="text-center py-12 text-ivory-100/60">Ładowanie...</div>
      ) : (
        <div className="space-y-6">
          {configs.map((config, index) => (
            <div key={config.bot_type} className="marble-card p-6">
              <div className="flex items-center justify-between mb-6">
                <div>
                  <h2 className="text-xl font-semibold text-ivory-100">{config.name}</h2>
                  <p className="text-sm text-ivory-100/60 mt-1">{config.description}</p>
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={() => testBot(config.bot_type)}
                    className="px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg transition-colors flex items-center gap-2"
                  >
                    <TestTube className="h-4 w-4" />
                    Test
                  </button>
                  <button
                    onClick={() => saveConfig(config)}
                    disabled={saving}
                    className="px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg transition-colors flex items-center gap-2 disabled:opacity-50"
                  >
                    <Save className="h-4 w-4" />
                    Zapisz
                  </button>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-sm font-medium text-ivory-100 mb-2">
                    Status
                  </label>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={config.enabled}
                      onChange={(e) =>
                        updateConfig(index, { enabled: e.target.checked })
                      }
                      className="w-4 h-4 rounded border-white/20 bg-white/5 text-ember-500 focus:ring-ember-500"
                    />
                    <span className="text-ivory-100/70">
                      {config.enabled ? "Włączony" : "Wyłączony"}
                    </span>
                  </label>
                </div>

                <div>
                  <label className="block text-sm font-medium text-ivory-100 mb-2">
                    Model
                  </label>
                  <input
                    type="text"
                    value={config.model}
                    onChange={(e) => updateConfig(index, { model: e.target.value })}
                    className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 placeholder:text-ivory-100/40 focus:outline-none focus:ring-2 focus:ring-ember-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-ivory-100 mb-2">
                    Temperature: {config.temperature}
                  </label>
                  <input
                    type="range"
                    min="0"
                    max="2"
                    step="0.1"
                    value={config.temperature}
                    onChange={(e) =>
                      updateConfig(index, { temperature: parseFloat(e.target.value) })
                    }
                    className="w-full"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-ivory-100 mb-2">
                    Max Tokens
                  </label>
                  <input
                    type="number"
                    value={config.max_tokens}
                    onChange={(e) =>
                      updateConfig(index, { max_tokens: parseInt(e.target.value) })
                    }
                    className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 placeholder:text-ivory-100/40 focus:outline-none focus:ring-2 focus:ring-ember-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-ivory-100 mb-2">
                    Context Window
                  </label>
                  <input
                    type="number"
                    value={config.context_window}
                    onChange={(e) =>
                      updateConfig(index, { context_window: parseInt(e.target.value) })
                    }
                    className="w-full px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 placeholder:text-ivory-100/40 focus:outline-none focus:ring-2 focus:ring-ember-500"
                  />
                </div>

                <div>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={config.use_lora}
                      onChange={(e) =>
                        updateConfig(index, { use_lora: e.target.checked })
                      }
                      className="w-4 h-4 rounded border-white/20 bg-white/5 text-ember-500 focus:ring-ember-500"
                    />
                    <span className="text-sm font-medium text-ivory-100">
                      Użyj LoRA Adapter
                    </span>
                  </label>
                  {config.use_lora && (
                    <input
                      type="text"
                      value={config.lora_adapter}
                      onChange={(e) =>
                        updateConfig(index, { lora_adapter: e.target.value })
                      }
                      placeholder="Nazwa adaptera LoRA"
                      className="w-full mt-2 px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 placeholder:text-ivory-100/40 focus:outline-none focus:ring-2 focus:ring-ember-500"
                    />
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* System Settings */}
      <div className="mt-8 marble-card p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-semibold text-ivory-100">Ustawienia Systemu</h2>
          <button
            onClick={loadConfigs}
            className="px-4 py-2 bg-gray-500 hover:bg-gray-600 text-white rounded-lg transition-colors flex items-center gap-2"
          >
            <RefreshCw className="h-4 w-4" />
            Odśwież
          </button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="p-4 bg-white/5 rounded-lg">
            <div className="text-sm text-ivory-100/60 mb-1">CerAI Bot URL</div>
            <div className="text-ivory-100 font-mono text-sm">
              {process.env.NEXT_PUBLIC_CERAI_API_URL || "http://ceramix-bot:8000"}
            </div>
          </div>
          <div className="p-4 bg-white/5 rounded-lg">
            <div className="text-sm text-ivory-100/60 mb-1">LoRA Service URL</div>
            <div className="text-ivory-100 font-mono text-sm">
              {process.env.NEXT_PUBLIC_CERAI_LORA_URL || "http://cerai-lora:8007"}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

