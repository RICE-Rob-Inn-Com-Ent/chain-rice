import React, { useState } from "react";
import { Icon } from "@iconify/react";

interface GodModel {
  id: string;
  name: string;
  icon: string;
  type: "llm" | "vision" | "image-gen";
  ollamaModel?: string;
  vramUsage: number; // GB
  description: string;
}

const availableGods: GodModel[] = [
  {
    id: "thoth",
    name: "Thoth",
    icon: "📚",
    type: "llm",
    ollamaModel: "mistral:7b-instruct-q4_K_M",
    vramUsage: 4.1,
    description: "Text generation, NLP, translation",
  },
  {
    id: "ra",
    name: "Ra",
    icon: "☀️",
    type: "image-gen",
    vramUsage: 3.5,
    description: "Image generation (Stable Diffusion 2.1)",
  },
  {
    id: "isis",
    name: "Isis",
    icon: "✨",
    type: "llm",
    ollamaModel: "llama2:7b",
    vramUsage: 3.8,
    description: "Audio, medical AI",
  },
  {
    id: "bastet",
    name: "Bastet",
    icon: "🐱",
    type: "vision",
    ollamaModel: "llava:7b",
    vramUsage: 4.7,
    description: "Computer vision, image analysis",
  },
  {
    id: "maat",
    name: "Maat",
    icon: "⚖️",
    type: "llm",
    ollamaModel: "mistral:7b-instruct-q4_K_M",
    vramUsage: 4.1,
    description: "Legal analysis, data analytics",
  },
  {
    id: "khnum",
    name: "Khnum",
    icon: "🏺",
    type: "llm",
    ollamaModel: "codellama:7b",
    vramUsage: 3.8,
    description: "Code generation, 3D modeling",
  },
];

type TrainingMode = "sequential" | "parallel" | "hybrid";

interface TrainingConfig {
  mode: TrainingMode;
  loraRank: number;
  loraAlpha: number;
  loraDropout: number;
  epochs: number;
  batchSize: number;
  learningRate: number;
}

export const GiPT1Training: React.FC = () => {
  const [selectedGods, setSelectedGods] = useState<Set<string>>(new Set(["thoth", "ra"]));
  const [textDataset, setTextDataset] = useState<File | null>(null);
  const [imageDataset, setImageDataset] = useState<File | null>(null);
  const [isTraining, setIsTraining] = useState(false);
  const [trainingProgress, setTrainingProgress] = useState({ llm: 0, sd: 0 });
  const [trainingLoss, setTrainingLoss] = useState({ llm: 0, sd: 0 });
  
  const [config, setConfig] = useState<TrainingConfig>({
    mode: "hybrid",
    loraRank: 16,
    loraAlpha: 32,
    loraDropout: 0.05,
    epochs: 3,
    batchSize: 4,
    learningRate: 0.0002,
  });

  const toggleGod = (godId: string) => {
    const newSelected = new Set(selectedGods);
    if (newSelected.has(godId)) {
      newSelected.delete(godId);
    } else {
      newSelected.add(godId);
    }
    setSelectedGods(newSelected);
  };

  const getTotalVRAM = (): number => {
    return Array.from(selectedGods).reduce((total, godId) => {
      const god = availableGods.find((g) => g.id === godId);
      return total + (god?.vramUsage || 0);
    }, 0);
  };

  const hasLLM = Array.from(selectedGods).some((id) => {
    const god = availableGods.find((g) => g.id === id);
    return god?.type === "llm" || god?.type === "vision";
  });

  const hasImageGen = selectedGods.has("ra");

  const handleStartTraining = async () => {
    setIsTraining(true);
    // TODO: Implement actual training API calls
    console.log("Starting GiPT-1 training with:", {
      selectedGods: Array.from(selectedGods),
      config,
      textDataset: textDataset?.name,
      imageDataset: imageDataset?.name,
    });

    // Simulate training progress
    const interval = setInterval(() => {
      setTrainingProgress((prev) => ({
        llm: Math.min(prev.llm + 2, 100),
        sd: Math.min(prev.sd + 1.5, 100),
      }));
      setTrainingLoss((prev) => ({
        llm: Math.max(0.1, prev.llm - 0.01),
        sd: Math.max(0.2, prev.sd - 0.015),
      }));
    }, 1000);

    setTimeout(() => {
      clearInterval(interval);
      setIsTraining(false);
    }, 60000); // 1 min demo
  };

  return (
    <div className="p-8 max-w-7xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <div className="flex items-center gap-4 mb-2">
          <span className="text-6xl">🧬</span>
          <div>
            <h1 className="text-4xl font-bold text-white">GiPT-1 Multimodal Training</h1>
            <p className="text-gray-300">Combine multiple AI gods into one unified model</p>
          </div>
        </div>

        <div className="mt-4 bg-gradient-to-r from-purple-900/30 to-pink-900/30 border border-purple-500/30 rounded-lg p-4">
          <div className="flex items-start gap-3">
            <Icon icon="mdi:information" width={24} className="text-purple-400 flex-shrink-0" />
            <div className="text-sm text-purple-200">
              <p className="font-semibold mb-1">What is GiPT-1?</p>
              <p>
                GiPT-1 (General intelligence Pantheon Transformer) is a unified model combining all 6 Egyptian AI gods. It can handle text, vision, code, and image generation in a single model using LoRA fusion.
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* LEFT COLUMN: Model Selection */}
        <div className="lg:col-span-1 space-y-6">
          {/* Section A: Model Selection */}
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
            <h2 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <Icon icon="mdi:checkbox-multiple-marked" width={24} />
              Select Models
            </h2>

            <div className="space-y-2">
              {availableGods.map((god) => (
                <button
                  key={god.id}
                  onClick={() => toggleGod(god.id)}
                  className={`w-full flex items-center gap-3 p-3 rounded-lg border transition ${
                    selectedGods.has(god.id)
                      ? "bg-purple-500/20 border-purple-500/50 text-white"
                      : "bg-black/20 border-white/10 text-gray-400 hover:border-white/30"
                  }`}
                >
                  <div className={`w-5 h-5 rounded border-2 flex items-center justify-center ${
                    selectedGods.has(god.id) ? "border-purple-500 bg-purple-500" : "border-gray-500"
                  }`}>
                    {selectedGods.has(god.id) && <Icon icon="mdi:check" width={16} className="text-white" />}
                  </div>
                  <span className="text-2xl">{god.icon}</span>
                  <div className="flex-1 text-left">
                    <div className="font-semibold">{god.name}</div>
                    <div className="text-xs opacity-70">{god.description}</div>
                  </div>
                  <div className="text-xs bg-black/30 px-2 py-1 rounded">{god.vramUsage} GB</div>
                </button>
              ))}
            </div>

            {/* VRAM Summary */}
            <div className="mt-4 bg-black/30 rounded-lg p-3">
              <div className="flex justify-between items-center">
                <span className="text-sm text-gray-400">Total VRAM:</span>
                <span className="text-lg font-bold text-white">{getTotalVRAM().toFixed(1)} GB</span>
              </div>
              {getTotalVRAM() > 6 && (
                <p className="text-xs text-yellow-400 mt-2">
                  ⚠️ Exceeds 6GB - sequential training recommended
                </p>
              )}
            </div>
          </div>

          {/* Training Mode */}
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
            <h2 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <Icon icon="mdi:cog" width={24} />
              Training Mode
            </h2>

            <div className="space-y-2">
              {[
                { value: "sequential", label: "Sequential", desc: "SD first, then LLM" },
                { value: "parallel", label: "Parallel", desc: "Both at once (2 GPUs)" },
                { value: "hybrid", label: "Hybrid", desc: "SD on GPU, LLM on CPU" },
              ].map((mode) => (
                <button
                  key={mode.value}
                  onClick={() => setConfig({ ...config, mode: mode.value as TrainingMode })}
                  className={`w-full text-left p-3 rounded-lg border transition ${
                    config.mode === mode.value
                      ? "bg-blue-500/20 border-blue-500/50 text-white"
                      : "bg-black/20 border-white/10 text-gray-400 hover:border-white/30"
                  }`}
                >
                  <div className="font-semibold">{mode.label}</div>
                  <div className="text-xs opacity-70">{mode.desc}</div>
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* MIDDLE COLUMN: Configuration & Upload */}
        <div className="lg:col-span-1 space-y-6">
          {/* Section B: Dataset Upload */}
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
            <h2 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <Icon icon="mdi:upload" width={24} />
              Datasets
            </h2>

            {/* Text Dataset */}
            {hasLLM && (
              <div className="mb-4">
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Text Dataset (JSON)
                </label>
                <input
                  type="file"
                  accept=".json"
                  onChange={(e) => setTextDataset(e.target.files?.[0] || null)}
                  className="w-full text-sm text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-purple-500 file:text-white hover:file:bg-purple-600"
                />
                {textDataset && (
                  <div className="mt-2 flex items-center gap-2 text-sm text-green-400">
                    <Icon icon="mdi:check-circle" width={16} />
                    {textDataset.name} ({(textDataset.size / 1024).toFixed(1)} KB)
                  </div>
                )}
              </div>
            )}

            {/* Image Dataset */}
            {hasImageGen && (
              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Image Dataset (ZIP)
                </label>
                <input
                  type="file"
                  accept=".zip"
                  onChange={(e) => setImageDataset(e.target.files?.[0] || null)}
                  className="w-full text-sm text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-orange-500 file:text-white hover:file:bg-orange-600"
                />
                {imageDataset && (
                  <div className="mt-2 flex items-center gap-2 text-sm text-green-400">
                    <Icon icon="mdi:check-circle" width={16} />
                    {imageDataset.name} ({(imageDataset.size / 1024 / 1024).toFixed(1)} MB)
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Section C: LoRA Configuration */}
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
            <h2 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <Icon icon="mdi:tune" width={24} />
              LoRA Config
            </h2>

            <div className="space-y-3">
              {/* Rank */}
              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Rank: {config.loraRank}
                </label>
                <input
                  type="range"
                  min="8"
                  max="64"
                  step="8"
                  value={config.loraRank}
                  onChange={(e) => setConfig({ ...config, loraRank: parseInt(e.target.value) })}
                  className="w-full"
                />
              </div>

              {/* Alpha */}
              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Alpha: {config.loraAlpha}
                </label>
                <input
                  type="range"
                  min="8"
                  max="64"
                  step="8"
                  value={config.loraAlpha}
                  onChange={(e) => setConfig({ ...config, loraAlpha: parseInt(e.target.value) })}
                  className="w-full"
                />
              </div>

              {/* Learning Rate */}
              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Learning Rate: {config.learningRate}
                </label>
                <input
                  type="range"
                  min="0.0001"
                  max="0.001"
                  step="0.0001"
                  value={config.learningRate}
                  onChange={(e) => setConfig({ ...config, learningRate: parseFloat(e.target.value) })}
                  className="w-full"
                />
              </div>

              {/* Epochs */}
              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">Epochs: {config.epochs}</label>
                <input
                  type="range"
                  min="1"
                  max="10"
                  value={config.epochs}
                  onChange={(e) => setConfig({ ...config, epochs: parseInt(e.target.value) })}
                  className="w-full"
                />
              </div>

              {/* Batch Size */}
              <div>
                <label className="block text-sm font-semibold text-gray-300 mb-2">
                  Batch Size: {config.batchSize}
                </label>
                <input
                  type="range"
                  min="1"
                  max="16"
                  value={config.batchSize}
                  onChange={(e) => setConfig({ ...config, batchSize: parseInt(e.target.value) })}
                  className="w-full"
                />
              </div>
            </div>
          </div>

          {/* Start Training Button */}
          <button
            onClick={handleStartTraining}
            disabled={isTraining || selectedGods.size === 0}
            className="w-full px-6 py-4 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 disabled:from-gray-600 disabled:to-gray-700 text-white font-bold rounded-lg transition flex items-center justify-center gap-2 text-lg"
          >
            {isTraining ? (
              <>
                <Icon icon="svg-spinners:90-ring-with-bg" width={24} />
                Training in Progress...
              </>
            ) : (
              <>
                <Icon icon="mdi:rocket-launch" width={24} />
                Start GiPT-1 Training
              </>
            )}
          </button>
        </div>

        {/* RIGHT COLUMN: Progress & Status */}
        <div className="lg:col-span-1 space-y-6">
          {/* Section D: Progress Tracking */}
          {isTraining && (
            <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
              <h2 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
                <Icon icon="mdi:chart-line" width={24} />
                Training Progress
              </h2>

              {/* LLM Progress */}
              {hasLLM && (
                <div className="mb-4">
                  <div className="flex justify-between text-sm text-gray-300 mb-2">
                    <span className="flex items-center gap-2">
                      <Icon icon="mdi:brain" width={16} />
                      LLM Training
                    </span>
                    <span>{trainingProgress.llm}%</span>
                  </div>
                  <div className="w-full h-3 bg-black/50 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-purple-500 to-blue-500 transition-all duration-500"
                      style={{ width: `${trainingProgress.llm}%` }}
                    />
                  </div>
                  <div className="mt-1 text-xs text-gray-400">Loss: {trainingLoss.llm.toFixed(3)}</div>
                </div>
              )}

              {/* SD Progress */}
              {hasImageGen && (
                <div>
                  <div className="flex justify-between text-sm text-gray-300 mb-2">
                    <span className="flex items-center gap-2">
                      <Icon icon="mdi:image-auto-adjust" width={16} />
                      Stable Diffusion Training
                    </span>
                    <span>{trainingProgress.sd}%</span>
                  </div>
                  <div className="w-full h-3 bg-black/50 rounded-full overflow-hidden">
                    <div
                      className="h-full bg-gradient-to-r from-orange-500 to-amber-500 transition-all duration-500"
                      style={{ width: `${trainingProgress.sd}%` }}
                    />
                  </div>
                  <div className="mt-1 text-xs text-gray-400">Loss: {trainingLoss.sd.toFixed(3)}</div>
                </div>
              )}

              {/* ETA */}
              <div className="mt-4 bg-black/30 rounded-lg p-3">
                <div className="flex justify-between text-sm">
                  <span className="text-gray-400">ETA:</span>
                  <span className="text-white font-semibold">~{Math.max(0, 60 - Math.max(trainingProgress.llm, trainingProgress.sd) * 0.6).toFixed(0)} min</span>
                </div>
              </div>
            </div>
          )}

          {/* Model Preview */}
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
            <h2 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <Icon icon="mdi:eye" width={24} />
              Model Preview
            </h2>

            <div className="bg-gradient-to-br from-purple-900/50 to-pink-900/50 rounded-lg p-4 mb-4">
              <div className="text-center mb-3">
                <span className="text-5xl">🧬</span>
              </div>
              <h3 className="text-xl font-bold text-white text-center mb-1">GiPT-1</h3>
              <p className="text-sm text-gray-300 text-center">
                {selectedGods.size} {selectedGods.size === 1 ? "model" : "models"} combined
              </p>
            </div>

            {/* Selected Models */}
            <div className="space-y-1 mb-4">
              <div className="text-xs text-gray-400 mb-2">Included capabilities:</div>
              {Array.from(selectedGods).map((godId) => {
                const god = availableGods.find((g) => g.id === godId);
                return (
                  <div key={godId} className="flex items-center gap-2 text-sm text-gray-300">
                    <span>{god?.icon}</span>
                    <span>{god?.name}</span>
                    <span className="text-xs text-gray-500">• {god?.description}</span>
                  </div>
                );
              })}
            </div>

            {/* Deployment Info */}
            {!isTraining && (
              <div className="bg-black/30 rounded-lg p-3">
                <div className="text-xs text-gray-400 mb-1">Will be deployed as:</div>
                <div className="font-mono text-sm text-green-400">ollama:gipt-1:latest</div>
              </div>
            )}
          </div>

          {/* Section E: Deployment */}
          {trainingProgress.llm === 100 && trainingProgress.sd === 100 && (
            <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-green-500/30 p-6">
              <h2 className="text-xl font-bold text-green-400 mb-4 flex items-center gap-2">
                <Icon icon="mdi:check-circle" width={24} />
                Training Complete!
              </h2>

              <div className="space-y-2">
                <button className="w-full px-4 py-3 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-lg transition flex items-center justify-center gap-2">
                  <Icon icon="mdi:rocket" width={20} />
                  Deploy to Ollama
                </button>

                <button className="w-full px-4 py-3 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition flex items-center justify-center gap-2">
                  <Icon icon="mdi:test-tube" width={20} />
                  Test Model
                </button>

                <button className="w-full px-4 py-3 bg-gray-600 hover:bg-gray-700 text-white font-semibold rounded-lg transition flex items-center justify-center gap-2">
                  <Icon icon="mdi:download" width={20} />
                  Export LoRA
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Info Panel */}
      <div className="mt-8 bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-3 flex items-center gap-2">
          <Icon icon="mdi:information" width={24} />
          How GiPT-1 Training Works
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm text-gray-300">
          <div>
            <p className="font-semibold text-purple-400 mb-1">1. Model Fusion</p>
            <p>
              Selected god models are combined using LoRA (Low-Rank Adaptation). Each god contributes its specialized knowledge.
            </p>
          </div>
          <div>
            <p className="font-semibold text-blue-400 mb-1">2. Dual Training</p>
            <p>
              LLM and Stable Diffusion components train simultaneously or sequentially based on your hardware configuration.
            </p>
          </div>
          <div>
            <p className="font-semibold text-green-400 mb-1">3. Deployment</p>
            <p>
              Final model is deployed as <code className="bg-black/30 px-1 rounded">gipt-1:latest</code> ready to use in production.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

