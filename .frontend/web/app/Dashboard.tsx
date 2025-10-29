import React, { useState, useEffect } from "react";
import { Icon } from "@iconify/react";
import { useOllama } from "../lib/hooks/useOllama";
import { GodTraining } from "./GodTraining";
import { checkRaHealth, type RaHealthResponse } from "../lib/services/ra";

interface AIGod {
  id: string;
  name: string;
  subtitle: string;
  icon: string;
  gradient: string;
  description: string;
  features: string[];
  tech: string;
  ollamaModels: string[]; // Ollama model names for this god
}

const aiGods: AIGod[] = [
  {
    id: "thoth",
    name: "Thoth",
    subtitle: "Bóg Mądrości i Tekstu",
    icon: "📚",
    gradient: "from-blue-900 to-indigo-900",
    description: "NLP Stack • Przetwarzanie tekstu i dokumentów",
    features: ["Text Generation (Mistral 7B)", "OCR (PaddleOCR)", "Translation (Opus-MT)", "Document Analysis (Donut)"],
    tech: "Mistral 7B Q4 • PaddleOCR • Opus-MT",
    ollamaModels: ["mistral:7b-instruct-q4_K_M"],
  },
  {
    id: "ra",
    name: "Ra",
    subtitle: "Bóg Światła i Kreacji",
    icon: "☀️",
    gradient: "from-amber-900 to-orange-900",
    description: "Image & Video Generation • Kreacja wizualna",
    features: ["Image Generation (SD 2.1)", "Image Editing", "Upscaling (RealESRGAN)", "Style Transfer"],
    tech: "SD 2.1 FP16 • RealESRGAN • RVM",
    ollamaModels: [], // Ra uses Stable Diffusion WebUI, not Ollama
  },
  {
    id: "bes",
    name: "Bes",
    subtitle: "Bóg Muzyki i Głosu",
    icon: "🎵",
    gradient: "from-indigo-900 to-purple-900",
    description: "Audio AI • Synteza głosu, klonowanie i generacja muzyki",
    features: ["TTS (Tortoise TTS)", "Voice Cloning (XTTS)", "Music Generation (MusicGen)", "Audio Enhancement"],
    tech: "Tortoise TTS • XTTS • MusicGen",
    ollamaModels: [], // Uses own container on port 8003
  },
  {
    id: "isis",
    name: "Isis",
    subtitle: "Bogini Uzdrawiania",
    icon: "✨",
    gradient: "from-purple-900 to-pink-900",
    description: "Medical AI • Diagnostyka obrazów medycznych",
    features: ["Medical Imaging (MONAI)", "Disease Detection", "X-Ray Analysis", "MRI Processing"],
    tech: "MONAI • Med-SAM • RadImageNet",
    ollamaModels: ["llama2:7b"],
  },
  {
    id: "bastet",
    name: "Bastet",
    subtitle: "Bogini Wzroku",
    icon: "🐱",
    gradient: "from-yellow-900 to-amber-900",
    description: "Computer Vision • Analiza obrazu w czasie rzeczywistym",
    features: [
      "Face Recognition (InsightFace)",
      "Pose Estimation (MMPose)",
      "Object Detection (MMDetection)",
      "Visual QA (LLaVa 7B)",
    ],
    tech: "InsightFace • MMDetection • LLaVa 7B",
    ollamaModels: ["llava:7b"],
  },
  {
    id: "maat",
    name: "Maat",
    subtitle: "Bogini Sprawiedliwości",
    icon: "⚖️",
    gradient: "from-cyan-900 to-blue-900",
    description: "Legal & Analytics AI • Analiza prawna i danych",
    features: ["Legal Analysis", "Sentiment Analysis", "Text Summarization", "Data Visualization"],
    tech: "Mistral 7B Q4 • XLM-RoBERTa",
    ollamaModels: ["mistral:7b-instruct-q4_K_M"],
  },
  {
    id: "khnum",
    name: "Khnum",
    subtitle: "Bóg Tworzenia 3D",
    icon: "🏺",
    gradient: "from-emerald-900 to-teal-900",
    description: "3D & Game AI • Modelowanie i rekomendacje",
    features: [
      "3D Modeling (Tripo SR)",
      "System Recommendations (RecBole)",
      "Code Generation (StarCoder 7B)",
      "Game AI",
    ],
    tech: "Tripo SR • RecBole • StarCoder 7B",
    ollamaModels: ["codellama:7b"],
  },
];

export const Dashboard: React.FC = () => {
  const { models, runningModels, isHealthy, loading, error, downloadProgress } = useOllama(3000);
  const [loadingGod, setLoadingGod] = useState<string | null>(null);
  const [trainingGod, setTrainingGod] = useState<string | null>(null);
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

  const getGodStatus = (god: AIGod): "active" | "idle" | "loading" | "downloading" | "error" => {
    if (loadingGod === god.id) return "loading";

    // Special case for Ra - uses external Stable Diffusion WebUI, always idle
    if (god.id === "ra") return "idle";
    
    // Special case for Bes - uses external Tortoise TTS container, always idle
    if (god.id === "bes") return "idle";

    // Check if any of this god's models are downloading
    for (const modelName of god.ollamaModels) {
      if (downloadProgress.has(modelName)) {
        return "downloading";
      }
    }

    // Check if any of this god's models are running
    const isRunning = god.ollamaModels.some((modelName) => runningModels.includes(modelName));
    if (isRunning) return "active";

    // Check if models are installed
    const hasModels = god.ollamaModels.some((modelName) =>
      models.some((m) => m.name.startsWith(modelName.split(":")[0]))
    );

    if (!hasModels && isHealthy && god.ollamaModels.length > 0) return "error"; // Models not downloaded
    return "idle";
  };

  const handleWakeGod = async (god: AIGod) => {
    setLoadingGod(god.id);
    console.log(`Waking ${god.name}...`);

    // Simulate wake process - in real implementation, this would:
    // 1. Check if another god is active
    // 2. Unload that god's models
    // 3. Load this god's models via Ollama
    setTimeout(() => {
      setLoadingGod(null);
      console.log(`${god.name} is now active`);
    }, 3000);
  };

  const handleTryDemo = (god: AIGod) => {
    // Open demo page in new tab
    const demoUrl = `/demo/${god.id}.html`;
    window.open(demoUrl, "_blank");
  };

  const getProgressForGod = (god: AIGod): number | null => {
    for (const modelName of god.ollamaModels) {
      const progress = downloadProgress.get(modelName);
      if (progress && progress.total > 0) {
        return Math.round((progress.completed / progress.total) * 100);
      }
    }
    return null;
  };

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

  // If training interface is open, show it instead of dashboard
  if (trainingGod) {
    return (
      <GodTraining
        godId={trainingGod as "thoth" | "ra" | "isis" | "bastet" | "maat" | "khnum"}
        onBack={() => setTrainingGod(null)}
      />
    );
  }

  return (
    <div className="p-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-4xl font-bold text-white mb-2">Egyptian AI Dashboard</h1>
        <p className="text-gray-300">Monitor and manage your AI god stacks</p>

        {/* Ollama Status */}
        <div className="mt-4 flex items-center gap-3">
          <div className={`w-3 h-3 rounded-full ${isHealthy ? "bg-green-500" : "bg-red-500"} animate-pulse`} />
          <span className="text-white font-medium">Ollama: {isHealthy ? "Connected" : "Disconnected"}</span>
          {loading && <Icon icon="svg-spinners:90-ring-with-bg" width={20} className="text-white" />}
        </div>

        {error && (
          <div className="mt-4 bg-red-900/30 border border-red-500/30 rounded-lg p-3">
            <p className="text-red-400 text-sm">{error}</p>
          </div>
        )}
      </div>

      {/* Gods Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {aiGods.map((god) => {
          const status = getGodStatus(god);
          const progress = getProgressForGod(god);

          return (
            <div
              key={god.id}
              className={`bg-gradient-to-br ${god.gradient} rounded-xl border border-white/20 p-6 relative overflow-hidden`}
            >
              {/* Status Badge */}
              <div className="absolute top-4 right-4">
                {status === "active" && (
                  <span className="px-3 py-1 bg-green-500/20 text-green-400 border border-green-500/30 rounded-full text-xs font-semibold flex items-center gap-1">
                    <span className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
                    ACTIVE
                  </span>
                )}
                {status === "idle" && (
                  <span className="px-3 py-1 bg-gray-500/20 text-gray-400 border border-gray-500/30 rounded-full text-xs font-semibold">
                    IDLE
                  </span>
                )}
                {status === "loading" && (
                  <span className="px-3 py-1 bg-yellow-500/20 text-yellow-400 border border-yellow-500/30 rounded-full text-xs font-semibold flex items-center gap-1">
                    <Icon icon="svg-spinners:90-ring-with-bg" width={16} />
                    LOADING
                  </span>
                )}
                {status === "downloading" && (
                  <span className="px-3 py-1 bg-blue-500/20 text-blue-400 border border-blue-500/30 rounded-full text-xs font-semibold flex items-center gap-1">
                    <Icon icon="svg-spinners:90-ring-with-bg" width={16} />
                    DOWNLOADING
                  </span>
                )}
                {status === "error" && (
                  <span className="px-3 py-1 bg-red-500/20 text-red-400 border border-red-500/30 rounded-full text-xs font-semibold">
                    NOT INSTALLED
                  </span>
                )}
              </div>

              {/* God Icon */}
              <div className="text-6xl mb-3">{god.icon}</div>

              {/* God Info */}
              <h2 className="text-2xl font-bold text-white mb-1">{god.name}</h2>
              <p className="text-gray-300 text-sm mb-3">{god.subtitle}</p>
              <p className="text-gray-400 text-sm mb-4">{god.description}</p>

              {/* Features */}
              <div className="space-y-1 mb-4">
                {god.features.map((feature, idx) => (
                  <div key={idx} className="flex items-start gap-2 text-xs text-gray-300">
                    <span className="text-green-400 mt-0.5">✓</span>
                    <span>{feature}</span>
                  </div>
                ))}
              </div>

              {/* Tech Stack */}
              <div className="bg-black/20 rounded-lg p-2 mb-4">
                <p className="text-xs text-gray-400">{god.tech}</p>
              </div>

              {/* Progress Bar */}
              {progress !== null && (
                <div className="mb-4">
                  <div className="flex justify-between text-xs text-gray-300 mb-1">
                    <span>Downloading...</span>
                    <span>{progress}%</span>
                  </div>
                  <div className="w-full h-2 bg-black/30 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-blue-500 to-purple-500 transition-all duration-300"
                      style={{ width: `${progress}%` }}
                    />
                  </div>
                </div>
              )}

              {/* Actions */}
              <div className="space-y-2">
                {/* Primary Action */}
                <div className="flex gap-2">
                  {status === "idle" && (
                    <>
                      <button
                        onClick={() => handleWakeGod(god)}
                        className="flex-1 px-4 py-2 bg-white/20 hover:bg-white/30 text-white rounded-lg font-semibold transition"
                      >
                        Wake Model
                      </button>
                      <button 
                        onClick={() => handleTryDemo(god)}
                        className="flex-1 px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg font-semibold transition"
                      >
                        Try Demo →
                      </button>
                    </>
                  )}
                  {status === "active" && (
                    <button 
                      onClick={() => handleTryDemo(god)}
                      className="flex-1 px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg font-semibold transition"
                    >
                      Try Demo →
                    </button>
                  )}
                  {status === "loading" && (
                    <button
                      disabled
                      className="flex-1 px-4 py-2 bg-white/10 text-gray-400 rounded-lg font-semibold cursor-not-allowed"
                    >
                      Loading...
                    </button>
                  )}
                  {status === "downloading" && (
                    <button
                      disabled
                      className="flex-1 px-4 py-2 bg-white/10 text-gray-400 rounded-lg font-semibold cursor-not-allowed"
                    >
                      Downloading...
                    </button>
                  )}
                  {status === "error" && (
                    <button className="flex-1 px-4 py-2 bg-red-500/30 hover:bg-red-500/50 text-red-300 rounded-lg font-semibold transition">
                      Install Models
                    </button>
                  )}
                </div>

                {/* Train LoRA Button - Always visible */}
                <button
                  onClick={() => setTrainingGod(god.id)}
                  className="w-full px-4 py-2 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white rounded-lg font-semibold transition flex items-center justify-center gap-2"
                >
                  <Icon icon="mdi:brain" width={20} />
                  Train LoRA
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Info Section */}
      <div className="mt-8 bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-3">ℹ️ About GPU Management</h3>
        <ul className="space-y-2 text-gray-300 text-sm">
          <li>• Only ONE god can be ACTIVE at a time due to 6-8GB VRAM limit</li>
          <li>• ACTIVE = Model loaded on GPU and ready for inference</li>
          <li>• IDLE = Model not loaded, available to wake</li>
          <li>• Waking a new god will automatically sleep the active one</li>
          <li>• Models are managed through Ollama (localhost:11434)</li>
        </ul>
      </div>

      {/* Divider */}
      <div className="my-12 border-t border-white/10" />

      {/* Models Management Section */}
      <div className="mb-8">
        <h1 className="text-4xl font-bold text-white mb-2 flex items-center gap-3">
          <Icon icon="mdi:robot" width={40} />
          Model Management
        </h1>
        <p className="text-gray-300">Monitor and control Ollama models and Ra (Stable Diffusion)</p>
      </div>

      {/* Ra Section */}
      <div className="mb-8">
        <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-2">
          <Icon icon="mdi:weather-sunny" width={28} className="text-orange-400" />
          Ra - Stable Diffusion
        </h2>

        <div className="bg-gradient-to-br from-orange-900/30 to-amber-900/30 rounded-xl border border-orange-500/30 p-6">
          <div className="flex items-start gap-6">
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
                    <div
                      className={`w-3 h-3 rounded-full ${raStatus?.status === "active" ? "bg-green-500" : "bg-yellow-500"} animate-pulse`}
                    />
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
                      <span
                        key={opt}
                        className="px-3 py-1 bg-orange-500/20 text-orange-300 border border-orange-500/30 rounded-full text-xs font-semibold"
                      >
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
                onClick={() => window.open("/demo/ra.html", "_blank")}
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
              <p>
                Ra runs on port 8002 with Stable Diffusion 2.1 FP16. It has lazy loading and 6GB VRAM optimizations.
                Check health: <code className="bg-black/30 px-2 py-0.5 rounded">curl http://localhost:8002/health</code>
              </p>
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
                      <Icon icon="mdi:robot" width={32} className={isRunning ? "text-green-400" : "text-gray-400"} />
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
                  <div className="ml-6 flex flex-col gap-2">
                    <button className="px-4 py-2 bg-green-500 hover:bg-green-600 text-white rounded-lg font-semibold text-sm transition flex items-center gap-2">
                      <Icon icon="mdi:play" width={20} />
                      Run
                    </button>
                    <button className="px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg font-semibold text-sm transition flex items-center gap-2">
                      <Icon icon="mdi:cog" width={20} />
                      Config
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
