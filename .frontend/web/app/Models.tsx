import React, { useState, useEffect } from "react";
import { Icon } from "@iconify/react";
import { useOllama } from "../lib/hooks/useOllama";
import { checkRaHealth, type RaHealthResponse } from "../lib/services/ra";

export const Models: React.FC = () => {
  const { models, runningModels, isHealthy, loading, error, downloadProgress } = useOllama(2000);
  const [raStatus, setRaStatus] = useState<RaHealthResponse | null>(null);
  const [raAvailable, setRaAvailable] = useState(false);

  // Check Ra health
  useEffect(() => {
    const checkRa = async () => {
      try {
        const health = await checkRaHealth();
        setRaStatus(health);
        setRaAvailable(true);
      } catch (err) {
        console.error("Failed to check Ra health:", err);
        setRaAvailable(false);
        setRaStatus(null);
      }
    };

    checkRa();
    const interval = setInterval(checkRa, 5000);
    return () => clearInterval(interval);
  }, []);

  const formatBytes = (bytes: number): string => {
    if (bytes === 0) return "0 B";
    const k = 1024;
    const sizes = ["B", "KB", "MB", "GB", "TB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + " " + sizes[i];
  };

  const formatDate = (dateStr: string): string => {
    try {
      return new Date(dateStr).toLocaleString();
    } catch {
      return dateStr;
    }
  };

  return (
    <div className="p-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-4xl font-bold text-white mb-2">Model Management</h1>
        <p className="text-gray-300">View and manage Ollama models</p>

        {/* Status Bar */}
        <div className="mt-4 flex items-center gap-6 bg-white/5 backdrop-blur-lg rounded-lg border border-white/10 p-4">
          <div className="flex items-center gap-2">
            <div className={`w-3 h-3 rounded-full ${isHealthy ? "bg-green-500" : "bg-red-500"} animate-pulse`} />
            <span className="text-white font-medium">
              {isHealthy ? "Ollama Connected" : "Ollama Disconnected"}
            </span>
          </div>

          <div className="flex items-center gap-2">
            <Icon icon="mdi:database" width={20} className="text-blue-400" />
            <span className="text-white">
              {models.length} {models.length === 1 ? "Model" : "Models"} Installed
            </span>
          </div>

          <div className="flex items-center gap-2">
            <Icon icon="mdi:play-circle" width={20} className="text-green-400" />
            <span className="text-white">
              {runningModels.length} {runningModels.length === 1 ? "Model" : "Models"} Running
            </span>
          </div>

          {loading && (
            <div className="ml-auto">
              <Icon icon="svg-spinners:90-ring-with-bg" width={24} className="text-white" />
            </div>
          )}
        </div>

        {error && (
          <div className="mt-4 bg-red-900/30 border border-red-500/30 rounded-lg p-4">
            <div className="flex items-center gap-2">
              <Icon icon="mdi:alert-circle" width={24} className="text-red-400" />
              <p className="text-red-400">{error}</p>
            </div>
          </div>
        )}
      </div>

      {/* Ra (Stable Diffusion) Section */}
      <div className="mb-8">
        <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-2">
          <span className="text-3xl">☀️</span>
          Ra - Stable Diffusion (Non-Ollama)
        </h2>
        
        <div className="bg-gradient-to-br from-orange-900 to-amber-900 rounded-xl border border-orange-500/30 p-6">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              {/* Ra Info */}
              <div className="flex items-center gap-3 mb-4">
                <Icon icon="mdi:image-auto-adjust" width={40} className="text-orange-400" />
                <div>
                  <h3 className="text-2xl font-bold text-white">Stable Diffusion 2.1 FP16</h3>
                  <p className="text-orange-300 text-sm">FastAPI Backend • Port 8002 • 6GB VRAM Optimized</p>
                </div>
              </div>

              {/* Status Badge */}
              <div className="mb-4">
                {raAvailable ? (
                  <div className="flex items-center gap-2">
                    <div className={`w-3 h-3 rounded-full ${raStatus?.status === "active" ? "bg-green-500" : "bg-yellow-500"} animate-pulse`} />
                    <span className="text-white font-semibold">
                      Status: {raStatus?.status === "active" ? "Active (GPU)" : "Sleeping (CPU)"}
                    </span>
                  </div>
                ) : (
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-red-500 animate-pulse" />
                    <span className="text-red-400 font-semibold">Disconnected</span>
                  </div>
                )}
              </div>

              {/* Models Grid */}
              {raStatus && (
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                  <div className="bg-black/30 rounded-lg p-4">
                    <div className="text-xs text-orange-300 mb-1">Image Generation</div>
                    <div className="text-white font-semibold">{raStatus.models.image_gen}</div>
                  </div>
                  
                  <div className="bg-black/30 rounded-lg p-4">
                    <div className="text-xs text-orange-300 mb-1">Upscaler</div>
                    <div className="text-white font-semibold">{raStatus.models.upscaler}</div>
                  </div>
                  
                  <div className="bg-black/30 rounded-lg p-4">
                    <div className="text-xs text-orange-300 mb-1">Background Removal</div>
                    <div className="text-white font-semibold">{raStatus.models.bg_removal}</div>
                  </div>
                </div>
              )}

              {/* Optimizations */}
              {raStatus && (
                <div className="mt-4 bg-black/30 rounded-lg p-4">
                  <div className="text-xs text-orange-300 mb-2">Optimizations</div>
                  <div className="flex flex-wrap gap-2">
                    {raStatus.optimizations.map((opt) => (
                      <span key={opt} className="px-3 py-1 bg-orange-500/20 text-orange-300 border border-orange-500/30 rounded-full text-xs font-semibold">
                        {opt}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Actions */}
            <div className="flex flex-col gap-2 ml-4">
              <button 
                onClick={() => window.open('/demo/ra.html', '_blank')}
                className="px-4 py-2 bg-orange-500 hover:bg-orange-600 text-white rounded-lg font-semibold text-sm transition flex items-center gap-2"
              >
                <Icon icon="mdi:play" width={20} />
                Try Demo
              </button>
              
              <button className="px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg font-semibold text-sm transition flex items-center gap-2">
                <Icon icon="mdi:cog" width={20} />
                Settings
              </button>
            </div>
          </div>
        </div>

        {/* Info Note */}
        <div className="mt-4 bg-blue-900/20 border border-blue-500/30 rounded-lg p-4">
          <div className="flex items-start gap-3">
            <Icon icon="mdi:information" width={24} className="text-blue-400 flex-shrink-0 mt-0.5" />
            <div className="text-sm text-blue-200">
              <p className="font-semibold mb-1">ℹ️ Ra uses its own FastAPI backend, not Ollama</p>
              <p>Ra runs on port 8002 with Stable Diffusion 2.1 FP16. It has lazy loading and 6GB VRAM optimizations. Check health: <code className="bg-black/30 px-2 py-0.5 rounded">curl http://localhost:8002/health</code></p>
            </div>
          </div>
        </div>
      </div>

      {/* Ollama Models Section */}
      <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-2">
        <Icon icon="simple-icons:ollama" width={28} className="text-white" />
        Ollama Models
      </h2>

      {/* Models Grid */}
      {models.length === 0 && isHealthy && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-12 text-center">
          <Icon icon="mdi:database-off" width={64} className="text-gray-500 mx-auto mb-4" />
          <h3 className="text-xl font-bold text-white mb-2">No Models Installed</h3>
          <p className="text-gray-400 mb-4">Install Ollama models to get started</p>
          <code className="bg-black/30 px-4 py-2 rounded-lg text-sm text-gray-300">
            ollama pull mistral:7b-instruct
          </code>
        </div>
      )}

      {models.length > 0 && (
        <div className="space-y-4">
          {models.map((model) => {
            const isRunning = runningModels.includes(model.name);
            const progress = downloadProgress.get(model.name);

            return (
              <div
                key={model.name}
                className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6 hover:border-white/20 transition"
              >
                <div className="flex items-start justify-between">
                  <div className="flex-1">
                    {/* Model Name */}
                    <div className="flex items-center gap-3 mb-2">
                      <Icon
                        icon="mdi:robot"
                        width={32}
                        className={isRunning ? "text-green-400" : "text-gray-400"}
                      />
                      <div>
                        <h3 className="text-xl font-bold text-white">{model.name}</h3>
                        {model.details && (
                          <p className="text-sm text-gray-400">
                            {model.details.family} • {model.details.parameter_size} • {model.details.quantization_level}
                          </p>
                        )}
                      </div>
                    </div>

                    {/* Details Grid */}
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mt-4">
                      <div className="bg-black/20 rounded-lg p-3">
                        <div className="text-xs text-gray-400 mb-1">Size</div>
                        <div className="text-white font-semibold">{formatBytes(model.size)}</div>
                      </div>

                      <div className="bg-black/20 rounded-lg p-3">
                        <div className="text-xs text-gray-400 mb-1">Format</div>
                        <div className="text-white font-semibold">{model.details?.format || "N/A"}</div>
                      </div>

                      <div className="bg-black/20 rounded-lg p-3">
                        <div className="text-xs text-gray-400 mb-1">Modified</div>
                        <div className="text-white font-semibold text-xs">{formatDate(model.modified_at)}</div>
                      </div>

                      <div className="bg-black/20 rounded-lg p-3">
                        <div className="text-xs text-gray-400 mb-1">Status</div>
                        <div className="flex items-center gap-2">
                          {isRunning ? (
                            <>
                              <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
                              <span className="text-green-400 font-semibold text-sm">Running</span>
                            </>
                          ) : (
                            <>
                              <span className="w-2 h-2 bg-gray-500 rounded-full" />
                              <span className="text-gray-400 font-semibold text-sm">Idle</span>
                            </>
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Digest */}
                    <div className="mt-4 bg-black/20 rounded-lg p-3">
                      <div className="text-xs text-gray-400 mb-1">Digest</div>
                      <div className="text-xs text-gray-300 font-mono break-all">{model.digest}</div>
                    </div>

                    {/* Progress Bar (if downloading) */}
                    {progress && progress.total > 0 && (
                      <div className="mt-4">
                        <div className="flex justify-between text-sm text-gray-300 mb-2">
                          <span>Downloading...</span>
                          <span>
                            {formatBytes(progress.completed)} / {formatBytes(progress.total)} (
                            {Math.round((progress.completed / progress.total) * 100)}%)
                          </span>
                        </div>
                        <div className="w-full h-2 bg-black/30 rounded-full overflow-hidden">
                          <div
                            className="h-full bg-gradient-to-r from-blue-500 to-purple-500 transition-all duration-300"
                            style={{ width: `${(progress.completed / progress.total) * 100}%` }}
                          />
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Actions */}
                  <div className="flex flex-col gap-2 ml-4">
                    {isRunning ? (
                      <button className="px-4 py-2 bg-green-500/20 text-green-400 border border-green-500/30 rounded-lg font-semibold text-sm hover:bg-green-500/30 transition">
                        <Icon icon="mdi:check-circle" width={20} className="inline mr-1" />
                        Active
                      </button>
                    ) : (
                      <button className="px-4 py-2 bg-blue-500/20 text-blue-400 border border-blue-500/30 rounded-lg font-semibold text-sm hover:bg-blue-500/30 transition">
                        <Icon icon="mdi:play" width={20} className="inline mr-1" />
                        Load
                      </button>
                    )}

                    <button className="px-4 py-2 bg-red-500/20 text-red-400 border border-red-500/30 rounded-lg font-semibold text-sm hover:bg-red-500/30 transition">
                      <Icon icon="mdi:delete" width={20} className="inline mr-1" />
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Quick Actions */}
      {isHealthy && (
        <div className="mt-8 bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Quick Actions</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <button className="px-6 py-4 bg-blue-500/20 text-blue-400 border border-blue-500/30 rounded-lg font-semibold hover:bg-blue-500/30 transition flex items-center gap-3">
              <Icon icon="mdi:download" width={24} />
              <span>Pull New Model</span>
            </button>

            <button className="px-6 py-4 bg-purple-500/20 text-purple-400 border border-purple-500/30 rounded-lg font-semibold hover:bg-purple-500/30 transition flex items-center gap-3">
              <Icon icon="mdi:refresh" width={24} />
              <span>Refresh List</span>
            </button>

            <button className="px-6 py-4 bg-gray-500/20 text-gray-400 border border-gray-500/30 rounded-lg font-semibold hover:bg-gray-500/30 transition flex items-center gap-3">
              <Icon icon="mdi:cog" width={24} />
              <span>Ollama Settings</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

