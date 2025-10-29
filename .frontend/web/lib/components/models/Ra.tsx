import React, { useState, useEffect } from "react";
import { Icon } from "@iconify/react";
import {
  checkRaHealth,
  wakeRa,
  generateImageWithRa,
  type RaImageGenRequest,
  type RaHealthResponse,
} from "../../services/ra";

interface GenerationParams {
  prompt: string;
  negativePrompt: string;
  steps: number;
  cfgScale: number;
  width: number;
  height: number;
  seed: number;
  samplerName: string;
  batchSize: number;
  batchCount: number;
  restoreFaces: boolean;
  tiling: boolean;
}

interface GeneratedImage {
  id: string;
  url: string;
  prompt: string;
  params: Partial<GenerationParams>;
  timestamp: number;
}

export default function RaUI() {
  const [activeTab, setActiveTab] = useState<"txt2img" | "img2img" | "extras">("txt2img");
  const [params, setParams] = useState<GenerationParams>({
    prompt: "",
    negativePrompt: "blurry, low quality, distorted, ugly, bad anatomy",
    steps: 30,
    cfgScale: 7.5,
    width: 512,
    height: 512,
    seed: -1,
    samplerName: "DPM++ 2M Karras",
    batchSize: 1,
    batchCount: 1,
    restoreFaces: false,
    tiling: false,
  });

  const [imageHistory, setImageHistory] = useState<GeneratedImage[]>([]);
  const [selectedImage, setSelectedImage] = useState<GeneratedImage | null>(null);
  const [isGenerating, setIsGenerating] = useState(false);
  const [raStatus, setRaStatus] = useState<RaHealthResponse | null>(null);
  const [raAvailable, setRaAvailable] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [progress, setProgress] = useState(0);
  const [generationInfo, setGenerationInfo] = useState<string>("");

  // Check Ra health on mount
  useEffect(() => {
    const checkHealth = async () => {
      try {
        const health = await checkRaHealth();
        setRaStatus(health);
        setRaAvailable(true);
        console.log("Ra status:", health);
      } catch (err) {
        console.error("Ra health check failed:", err);
        setRaAvailable(false);
        setError("Ra kontener nie działa. Uruchom: docker-compose up rice-ra");
      }
    };

    checkHealth();
    const interval = setInterval(checkHealth, 5000);
    return () => clearInterval(interval);
  }, []);

  const handleGenerate = async () => {
    if (!raAvailable) {
      setError("Ra is not available. Check if the container is running.");
      return;
    }

    setIsGenerating(true);
    setError(null);
    setProgress(0);

    try {
      // Wake Ra if sleeping
      if (raStatus?.status === "sleeping") {
        console.log("Waking Ra...");
        await wakeRa();
        setProgress(10);
      }

      // Simulate progress (SD takes time)
      const progressInterval = setInterval(() => {
        setProgress((prev) => Math.min(prev + 5, 90));
      }, 500);

      // Generate image
      const result = await generateImageWithRa({
        prompt: params.prompt,
        negative_prompt: params.negativePrompt,
        steps: params.steps,
        cfg_scale: params.cfgScale,
        width: params.width,
        height: params.height,
      });

      clearInterval(progressInterval);
      setProgress(100);

      // Use base64 image from Ra
      const newImage: GeneratedImage = {
        id: Date.now().toString(),
        url: result.image, // base64 data URL
        prompt: params.prompt,
        params: {
          steps: params.steps,
          cfgScale: params.cfgScale,
          width: params.width,
          height: params.height,
        },
        timestamp: Date.now(),
      };

      setImageHistory((prev) => [newImage, ...prev]);
      setSelectedImage(newImage);
      setGenerationInfo(`✅ Generated successfully!\nPrompt: ${params.prompt}\nSteps: ${params.steps} | CFG: ${params.cfgScale}\nSize: ${params.width}x${params.height}`);

      console.log("Image generated:", result.image_path);
    } catch (err: any) {
      console.error("Generation failed:", err);
      setError(err.message || "Failed to generate image");
    } finally {
      setIsGenerating(false);
      setProgress(0);
    }
  };

  const handleRandomize = () => {
    const randomPrompts = [
      "a majestic Egyptian pyramid at sunset, golden hour, dramatic lighting",
      "ancient Egyptian pharaoh wearing golden crown, photorealistic",
      "cyberpunk Cairo cityscape, neon lights, futuristic pyramids",
      "Ra god of sun, glowing aura, divine presence, epic scale",
      "Egyptian hieroglyphs glowing with magical energy",
    ];
    setParams((prev) => ({
      ...prev,
      prompt: randomPrompts[Math.floor(Math.random() * randomPrompts.length)],
      seed: Math.floor(Math.random() * 1000000),
    }));
  };

  const handleClear = () => {
    setParams({
      prompt: "",
      negativePrompt: "blurry, low quality, distorted, ugly, bad anatomy",
      steps: 30,
      cfgScale: 7.5,
      width: 512,
      height: 512,
      seed: -1,
      samplerName: "DPM++ 2M Karras",
      batchSize: 1,
      batchCount: 1,
      restoreFaces: false,
      tiling: false,
    });
    setSelectedImage(null);
    setError(null);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-900 via-amber-900 to-yellow-900 text-white">
      {/* Header */}
      <div className="bg-black/30 backdrop-blur-lg border-b border-orange-500/30 p-4">
        <div className="max-w-[2000px] mx-auto flex items-center justify-between">
          <div className="flex items-center gap-4">
            <div className="text-5xl">☀️</div>
            <div>
              <h1 className="text-3xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-yellow-300 to-orange-400">
                Ra - God of Light & Creation
              </h1>
              <p className="text-orange-300 text-sm">Stable Diffusion 2.1 FP16 • 6GB VRAM Optimized</p>
            </div>
          </div>

          {/* Ra Status */}
          <div className="flex items-center gap-3">
            {raAvailable ? (
              <>
                <div
                  className={`w-3 h-3 rounded-full ${
                    raStatus?.status === "active" ? "bg-green-500" : "bg-yellow-500"
                  } animate-pulse`}
                />
                <span className="text-white font-medium">
                  Ra: {raStatus?.status === "active" ? "Active (GPU)" : "Sleeping (CPU)"}
                </span>
              </>
            ) : (
              <>
                <div className="w-3 h-3 rounded-full bg-red-500 animate-pulse" />
                <span className="text-red-400 font-medium">Ra: Disconnected</span>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-[2000px] mx-auto p-6">
        {/* Error Display */}
        {error && (
          <div className="mb-4 bg-red-900/30 border border-red-500/50 rounded-lg p-4 flex items-start gap-3">
            <Icon icon="mdi:alert-circle" width={24} className="text-red-400 flex-shrink-0 mt-0.5" />
            <div className="flex-1">
              <p className="text-red-300 font-semibold">Error</p>
              <p className="text-red-200 text-sm">{error}</p>
            </div>
            <button onClick={() => setError(null)} className="text-red-400 hover:text-red-300">
              <Icon icon="mdi:close" width={20} />
            </button>
          </div>
        )}

        {/* Tab Navigation */}
        <div className="mb-6 flex gap-2">
          {(["txt2img", "img2img", "extras"] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-6 py-3 rounded-lg font-semibold transition ${
                activeTab === tab
                  ? "bg-gradient-to-r from-orange-500 to-amber-500 text-white"
                  : "bg-white/10 text-gray-300 hover:bg-white/20"
              }`}
            >
              {tab === "txt2img" ? "Text to Image" : tab === "img2img" ? "Image to Image" : "Extras"}
            </button>
          ))}
        </div>

        {/* 3 Column Layout */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* LEFT: Parameters */}
          <div className="bg-black/30 backdrop-blur-lg rounded-xl border border-orange-500/30 p-6 space-y-4 h-fit">
            <h2 className="text-xl font-bold text-orange-300 mb-4">Parameters</h2>

            {/* Prompt */}
            <div>
              <label className="block text-sm font-semibold text-orange-300 mb-2">Prompt</label>
              <textarea
                value={params.prompt}
                onChange={(e) => setParams((prev) => ({ ...prev, prompt: e.target.value }))}
                placeholder="Egyptian pyramid at sunset..."
                className="w-full h-24 bg-black/40 border border-orange-500/30 rounded-lg p-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-orange-500"
              />
            </div>

            {/* Negative Prompt */}
            <div>
              <label className="block text-sm font-semibold text-orange-300 mb-2">Negative Prompt</label>
              <textarea
                value={params.negativePrompt}
                onChange={(e) => setParams((prev) => ({ ...prev, negativePrompt: e.target.value }))}
                placeholder="blurry, low quality..."
                className="w-full h-16 bg-black/40 border border-orange-500/30 rounded-lg p-3 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-orange-500"
              />
            </div>

            {/* Steps */}
            <div>
              <label className="block text-sm font-semibold text-orange-300 mb-2">Sampling Steps: {params.steps}</label>
              <input
                type="range"
                min="10"
                max="50"
                value={params.steps}
                onChange={(e) => setParams((prev) => ({ ...prev, steps: parseInt(e.target.value) }))}
                className="w-full"
              />
            </div>

            {/* CFG Scale */}
            <div>
              <label className="block text-sm font-semibold text-orange-300 mb-2">CFG Scale: {params.cfgScale}</label>
              <input
                type="range"
                min="1"
                max="20"
                step="0.5"
                value={params.cfgScale}
                onChange={(e) => setParams((prev) => ({ ...prev, cfgScale: parseFloat(e.target.value) }))}
                className="w-full"
              />
            </div>

            {/* Dimensions */}
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-sm font-semibold text-orange-300 mb-2">Width</label>
                <select
                  value={params.width}
                  onChange={(e) => setParams((prev) => ({ ...prev, width: parseInt(e.target.value) }))}
                  className="w-full bg-black/40 border border-orange-500/30 rounded-lg p-2 text-white"
                >
                  {[256, 384, 512, 640, 768, 896, 1024].map((w) => (
                    <option key={w} value={w}>
                      {w}
                    </option>
                  ))}
                </select>
              </div>
              <div>
                <label className="block text-sm font-semibold text-orange-300 mb-2">Height</label>
                <select
                  value={params.height}
                  onChange={(e) => setParams((prev) => ({ ...prev, height: parseInt(e.target.value) }))}
                  className="w-full bg-black/40 border border-orange-500/30 rounded-lg p-2 text-white"
                >
                  {[256, 384, 512, 640, 768, 896, 1024].map((h) => (
                    <option key={h} value={h}>
                      {h}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            {/* Seed */}
            <div>
              <label className="block text-sm font-semibold text-orange-300 mb-2">Seed (-1 = random)</label>
              <input
                type="number"
                value={params.seed}
                onChange={(e) => setParams((prev) => ({ ...prev, seed: parseInt(e.target.value) }))}
                className="w-full bg-black/40 border border-orange-500/30 rounded-lg p-2 text-white"
              />
            </div>

            {/* Action Buttons */}
            <div className="space-y-2 pt-4">
              <button
                onClick={handleGenerate}
                disabled={isGenerating || !params.prompt || !raAvailable}
                className="w-full px-6 py-3 bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600 disabled:from-gray-600 disabled:to-gray-700 text-white font-bold rounded-lg transition flex items-center justify-center gap-2"
              >
                {isGenerating ? (
                  <>
                    <Icon icon="svg-spinners:90-ring-with-bg" width={20} />
                    Generating...
                  </>
                ) : (
                  <>
                    <Icon icon="mdi:creation" width={20} />
                    Generate
                  </>
                )}
              </button>

              <div className="grid grid-cols-2 gap-2">
                <button
                  onClick={handleRandomize}
                  className="px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg transition"
                >
                  🎲 Randomize
                </button>
                <button
                  onClick={handleClear}
                  className="px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg transition"
                >
                  🗑️ Clear
                </button>
              </div>
            </div>

            {/* Progress Bar */}
            {isGenerating && (
              <div className="pt-2">
                <div className="flex justify-between text-xs text-orange-300 mb-1">
                  <span>Generating...</span>
                  <span>{progress}%</span>
                </div>
                <div className="w-full h-2 bg-black/50 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-orange-500 to-amber-500 transition-all duration-300"
                    style={{ width: `${progress}%` }}
                  />
                </div>
              </div>
            )}
          </div>

          {/* MIDDLE: Preview */}
          <div className="bg-black/30 backdrop-blur-lg rounded-xl border border-orange-500/30 p-6">
            <h2 className="text-xl font-bold text-orange-300 mb-4">Preview</h2>

            {selectedImage ? (
              <div className="space-y-4">
                <div className="relative aspect-square bg-black/50 rounded-lg overflow-hidden border-2 border-orange-500/50">
                  <img src={selectedImage.url} alt="Generated" className="w-full h-full object-contain" />
                </div>

                <div className="bg-black/40 rounded-lg p-3 space-y-2">
                  <p className="text-xs text-gray-400">Prompt:</p>
                  <p className="text-sm text-white">{selectedImage.prompt}</p>

                  {generationInfo && (
                    <>
                      <p className="text-xs text-gray-400 mt-3">Info:</p>
                      <p className="text-xs text-gray-300 whitespace-pre-wrap font-mono">{generationInfo}</p>
                    </>
                  )}
                </div>

                <div className="grid grid-cols-2 gap-2">
                  <button className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition flex items-center justify-center gap-2">
                    <Icon icon="mdi:download" width={16} />
                    Download
                  </button>
                  <button className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white rounded-lg transition flex items-center justify-center gap-2">
                    <Icon icon="mdi:image-multiple" width={16} />
                    Variations
                  </button>
                </div>
              </div>
            ) : (
              <div className="aspect-square bg-black/50 rounded-lg flex items-center justify-center border-2 border-dashed border-orange-500/30">
                <div className="text-center text-gray-400">
                  <Icon icon="mdi:image-off" width={64} className="mx-auto mb-2 opacity-50" />
                  <p>No image generated yet</p>
                  <p className="text-sm mt-1">Enter a prompt and click Generate</p>
                </div>
              </div>
            )}
          </div>

          {/* RIGHT: Gallery */}
          <div className="bg-black/30 backdrop-blur-lg rounded-xl border border-orange-500/30 p-6">
            <h2 className="text-xl font-bold text-orange-300 mb-4">Gallery ({imageHistory.length})</h2>

            {imageHistory.length > 0 ? (
              <div className="grid grid-cols-2 gap-3 max-h-[600px] overflow-y-auto">
                {imageHistory.map((img) => (
                  <button
                    key={img.id}
                    onClick={() => setSelectedImage(img)}
                    className={`relative aspect-square bg-black/50 rounded-lg overflow-hidden border-2 transition ${
                      selectedImage?.id === img.id
                        ? "border-orange-500"
                        : "border-orange-500/20 hover:border-orange-500/50"
                    }`}
                  >
                    <img src={img.url} alt={img.prompt} className="w-full h-full object-cover" />
                  </button>
                ))}
              </div>
            ) : (
              <div className="flex items-center justify-center h-[400px] text-gray-400 text-sm">
                <div className="text-center">
                  <Icon icon="mdi:image-multiple-outline" width={48} className="mx-auto mb-2 opacity-50" />
                  <p>No images yet</p>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Info Section */}
        <div className="mt-6 bg-black/30 backdrop-blur-lg rounded-xl border border-orange-500/30 p-6">
          <h3 className="text-xl font-bold text-orange-300 mb-3">ℹ️ About Ra</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm text-gray-300">
            <div>
              <p className="font-semibold text-orange-400 mb-1">Model</p>
              <p>Stable Diffusion 2.1 FP16</p>
            </div>
            <div>
              <p className="font-semibold text-orange-400 mb-1">Optimizations</p>
              <p>Attention Slicing • VAE Slicing</p>
            </div>
            <div>
              <p className="font-semibold text-orange-400 mb-1">VRAM</p>
              <p>6GB optimized (lazy loading)</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
