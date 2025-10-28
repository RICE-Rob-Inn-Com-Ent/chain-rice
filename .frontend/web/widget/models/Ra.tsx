"use client";
import { useState, useEffect } from "react";
import {
  generateImage,
  checkSDHealth,
  upscaleImage,
  generateVariations,
  getSDModels,
} from "../../lib/services/stableDiffusion";

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
  url: string;
  params: GenerationParams;
  timestamp: number;
  info: string;
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
  const [sdAvailable, setSdAvailable] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [progress, setProgress] = useState(0);
  const [availableModels, setAvailableModels] = useState<any[]>([]);
  const [generationInfo, setGenerationInfo] = useState<string>("");

  const samplers = [
    "Euler a",
    "Euler",
    "LMS",
    "Heun",
    "DPM2",
    "DPM2 a",
    "DPM++ 2S a",
    "DPM++ 2M",
    "DPM++ SDE",
    "DPM++ 2M Karras",
    "DPM++ SDE Karras",
    "DDIM",
    "PLMS",
    "UniPC",
  ];

  useEffect(() => {
    const checkHealth = async () => {
      const healthy = await checkSDHealth();
      setSdAvailable(healthy);
      if (healthy) {
        const models = await getSDModels();
        setAvailableModels(models);
      }
    };
    checkHealth();
  }, []);

  const handleGenerate = async () => {
    if (!params.prompt.trim()) {
      alert("Wprowadź prompt!");
      return;
    }

    setIsGenerating(true);
    setError(null);
    setProgress(0);

    try {
      if (sdAvailable) {
        const result = await generateImage({
          prompt: params.prompt,
          negative_prompt: params.negativePrompt,
          steps: params.steps,
          cfg_scale: params.cfgScale,
          width: params.width,
          height: params.height,
          seed: params.seed,
          sampler_name: params.samplerName,
          batch_size: params.batchSize,
        });

        if (result.images && result.images.length > 0) {
          const newImages: GeneratedImage[] = result.images.map((img: string) => ({
            url: `data:image/png;base64,${img}`,
            params: { ...params },
            timestamp: Date.now(),
            info: result.info || "",
          }));

          setImageHistory([...newImages, ...imageHistory]);
          setSelectedImage(newImages[0]);
          setGenerationInfo(result.info || "");
        }
      } else {
        await new Promise((resolve) => setTimeout(resolve, 2000));
        const placeholderImg: GeneratedImage = {
          url: `https://picsum.photos/${params.width}/${params.height}?random=${Date.now()}`,
          params: { ...params },
          timestamp: Date.now(),
          info: "Placeholder mode - WebUI not connected",
        };
        setImageHistory([placeholderImg, ...imageHistory]);
        setSelectedImage(placeholderImg);
        setError("Stable Diffusion WebUI not running. Using placeholder. Start WebUI on port 7860.");
      }
    } catch (error: any) {
      console.error("[Ra] Generation error:", error);
      setError(`Generation failed: ${error.message}`);
    } finally {
      setIsGenerating(false);
      setProgress(0);
    }
  };

  const handleUpscale = async () => {
    if (!selectedImage || !sdAvailable) return;
    setIsGenerating(true);
    setError(null);

    try {
      const base64 = selectedImage.url.replace(/^data:image\/\w+;base64,/, "");
      const result = await upscaleImage(base64, "RealESRGAN_x4plus", 4);
      const upscaledImg: GeneratedImage = {
        url: `data:image/png;base64,${result.image}`,
        params: selectedImage.params,
        timestamp: Date.now(),
        info: "Upscaled 4x with RealESRGAN",
      };
      setImageHistory([upscaledImg, ...imageHistory]);
      setSelectedImage(upscaledImg);
    } catch (error: any) {
      setError(`Upscale failed: ${error.message}`);
    } finally {
      setIsGenerating(false);
    }
  };

  const handleVariations = async () => {
    if (!selectedImage || !params.prompt || !sdAvailable) return;
    setIsGenerating(true);
    setError(null);

    try {
      const base64 = selectedImage.url.replace(/^data:image\/\w+;base64,/, "");
      const result = await generateVariations(base64, params.prompt, 0.5);
      if (result.images && result.images.length > 0) {
        const varImg: GeneratedImage = {
          url: `data:image/png;base64,${result.images[0]}`,
          params: { ...params },
          timestamp: Date.now(),
          info: result.info || "Variation",
        };
        setImageHistory([varImg, ...imageHistory]);
        setSelectedImage(varImg);
      }
    } catch (error: any) {
      setError(`Variations failed: ${error.message}`);
    } finally {
      setIsGenerating(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-orange-900/20 via-black to-red-900/20 text-white">
      {/* Header - Egyptian Theme */}
      <div className="border-b border-amber-500/30 bg-gradient-to-r from-amber-900/30 to-orange-900/30 backdrop-blur">
        <div className="max-w-[2000px] mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="text-5xl">☀️</div>
              <div>
                <h1 className="text-2xl font-bold bg-gradient-to-r from-amber-400 via-orange-500 to-red-600 bg-clip-text text-transparent">
                  Ra - Image Generation Studio
                </h1>
                <div className="flex items-center gap-3 text-xs text-gray-400 mt-1">
                  <span>Stable Diffusion 2.1 FP16</span>
                  <span>•</span>
                  <div className="flex items-center gap-2">
                    <div
                      className={`w-2 h-2 rounded-full ${sdAvailable ? "bg-green-500 animate-pulse" : "bg-red-500"}`}
                    />
                    <span>{sdAvailable ? "WebUI Connected (7860)" : "WebUI Offline"}</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Model Selector */}
            {sdAvailable && availableModels.length > 0 && (
              <select className="bg-gray-800 border border-amber-500/30 rounded-lg px-3 py-2 text-sm">
                {availableModels.map((model, idx) => (
                  <option key={idx} value={model.title}>
                    {model.model_name}
                  </option>
                ))}
              </select>
            )}
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-[2000px] mx-auto p-4">
        {/* Tabs */}
        <div className="flex gap-2 mb-4">
          <button
            onClick={() => setActiveTab("txt2img")}
            className={`px-6 py-2 rounded-t-lg font-semibold transition ${
              activeTab === "txt2img" ? "bg-amber-600 text-white" : "bg-gray-800/50 text-gray-400 hover:bg-gray-800"
            }`}
          >
            txt2img
          </button>
          <button
            onClick={() => setActiveTab("img2img")}
            className={`px-6 py-2 rounded-t-lg font-semibold transition ${
              activeTab === "img2img" ? "bg-amber-600 text-white" : "bg-gray-800/50 text-gray-400 hover:bg-gray-800"
            }`}
          >
            img2img
          </button>
          <button
            onClick={() => setActiveTab("extras")}
            className={`px-6 py-2 rounded-t-lg font-semibold transition ${
              activeTab === "extras" ? "bg-amber-600 text-white" : "bg-gray-800/50 text-gray-400 hover:bg-gray-800"
            }`}
          >
            Extras
          </button>
        </div>

        <div className="grid grid-cols-12 gap-4">
          {/* Left Panel - Parameters */}
          <div className="col-span-4 space-y-4">
            {/* Prompt Card */}
            <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-amber-500/20 p-4">
              <h3 className="text-sm font-bold text-amber-400 mb-3 flex items-center gap-2">
                <span>📝</span> Prompt
              </h3>
              <textarea
                value={params.prompt}
                onChange={(e) => setParams({ ...params, prompt: e.target.value })}
                placeholder="masterpiece, highly detailed Egyptian pyramid at sunset, golden hour lighting..."
                className="w-full bg-gray-800 text-white rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500 min-h-[100px] resize-y font-mono"
              />

              <h3 className="text-sm font-bold text-amber-400 mb-3 mt-4 flex items-center gap-2">
                <span>🚫</span> Negative Prompt
              </h3>
              <textarea
                value={params.negativePrompt}
                onChange={(e) => setParams({ ...params, negativePrompt: e.target.value })}
                className="w-full bg-gray-800 text-white rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500 min-h-[60px] resize-y font-mono"
              />
            </div>

            {/* Sampling Parameters */}
            <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-amber-500/20 p-4">
              <h3 className="text-sm font-bold text-amber-400 mb-3">⚙️ Sampling</h3>

              <div className="space-y-3">
                {/* Sampler */}
                <div>
                  <label className="block text-xs font-semibold mb-1.5 text-gray-300">Sampling method</label>
                  <select
                    value={params.samplerName}
                    onChange={(e) => setParams({ ...params, samplerName: e.target.value })}
                    className="w-full bg-gray-800 border border-gray-700 text-white rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
                  >
                    {samplers.map((sampler) => (
                      <option key={sampler} value={sampler}>
                        {sampler}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Steps */}
                <div>
                  <label className="block text-xs font-semibold mb-1.5 text-gray-300">
                    Sampling steps: <span className="text-amber-400">{params.steps}</span>
                  </label>
                  <input
                    type="range"
                    min="1"
                    max="150"
                    value={params.steps}
                    onChange={(e) => setParams({ ...params, steps: Number.parseInt(e.target.value) })}
                    className="w-full accent-amber-500"
                  />
                  <div className="flex justify-between text-xs text-gray-500 mt-1">
                    <span>1</span>
                    <span>150</span>
                  </div>
                </div>

                {/* CFG Scale */}
                <div>
                  <label className="block text-xs font-semibold mb-1.5 text-gray-300">
                    CFG Scale: <span className="text-amber-400">{params.cfgScale}</span>
                  </label>
                  <input
                    type="range"
                    min="1"
                    max="30"
                    step="0.5"
                    value={params.cfgScale}
                    onChange={(e) => setParams({ ...params, cfgScale: Number.parseFloat(e.target.value) })}
                    className="w-full accent-amber-500"
                  />
                  <div className="flex justify-between text-xs text-gray-500 mt-1">
                    <span>1</span>
                    <span>30</span>
                  </div>
                </div>

                {/* Dimensions */}
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-semibold mb-1.5 text-gray-300">Width</label>
                    <select
                      value={params.width}
                      onChange={(e) => setParams({ ...params, width: Number.parseInt(e.target.value) })}
                      className="w-full bg-gray-800 border border-gray-700 text-white rounded-lg px-3 py-2 text-sm"
                    >
                      <option value="512">512</option>
                      <option value="640">640</option>
                      <option value="768">768</option>
                      <option value="1024">1024</option>
                    </select>
                  </div>
                  <div>
                    <label className="block text-xs font-semibold mb-1.5 text-gray-300">Height</label>
                    <select
                      value={params.height}
                      onChange={(e) => setParams({ ...params, height: Number.parseInt(e.target.value) })}
                      className="w-full bg-gray-800 border border-gray-700 text-white rounded-lg px-3 py-2 text-sm"
                    >
                      <option value="512">512</option>
                      <option value="640">640</option>
                      <option value="768">768</option>
                      <option value="1024">1024</option>
                    </select>
                  </div>
                </div>

                {/* Batch */}
                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-semibold mb-1.5 text-gray-300">Batch count</label>
                    <input
                      type="number"
                      min="1"
                      max="10"
                      value={params.batchCount}
                      onChange={(e) => setParams({ ...params, batchCount: Number.parseInt(e.target.value) })}
                      className="w-full bg-gray-800 border border-gray-700 text-white rounded-lg px-3 py-2 text-sm"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-semibold mb-1.5 text-gray-300">Batch size</label>
                    <input
                      type="number"
                      min="1"
                      max="8"
                      value={params.batchSize}
                      onChange={(e) => setParams({ ...params, batchSize: Number.parseInt(e.target.value) })}
                      className="w-full bg-gray-800 border border-gray-700 text-white rounded-lg px-3 py-2 text-sm"
                    />
                  </div>
                </div>

                {/* Seed */}
                <div>
                  <label className="block text-xs font-semibold mb-1.5 text-gray-300">Seed</label>
                  <div className="flex gap-2">
                    <input
                      type="number"
                      value={params.seed}
                      onChange={(e) => setParams({ ...params, seed: Number.parseInt(e.target.value) })}
                      className="flex-1 bg-gray-800 border border-gray-700 text-white rounded-lg px-3 py-2 text-sm"
                      placeholder="-1 = random"
                    />
                    <button
                      onClick={() => setParams({ ...params, seed: -1 })}
                      className="px-3 py-2 bg-gray-700 hover:bg-gray-600 rounded-lg text-xs"
                    >
                      🎲
                    </button>
                  </div>
                </div>

                {/* Checkboxes */}
                <div className="space-y-2">
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={params.restoreFaces}
                      onChange={(e) => setParams({ ...params, restoreFaces: e.target.checked })}
                      className="w-4 h-4 accent-amber-500"
                    />
                    <span className="text-sm text-gray-300">Restore faces</span>
                  </label>
                  <label className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={params.tiling}
                      onChange={(e) => setParams({ ...params, tiling: e.target.checked })}
                      className="w-4 h-4 accent-amber-500"
                    />
                    <span className="text-sm text-gray-300">Tiling</span>
                  </label>
                </div>
              </div>
            </div>

            {/* Generate Button */}
            <button
              onClick={handleGenerate}
              disabled={isGenerating}
              className="w-full bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-700 hover:to-orange-700 disabled:from-gray-700 disabled:to-gray-800 text-white py-3 rounded-lg font-bold text-lg transition-all disabled:cursor-not-allowed shadow-lg hover:shadow-amber-500/50 flex items-center justify-center gap-2"
            >
              {isGenerating ? (
                <>
                  <div className="animate-spin text-2xl">☀️</div>
                  <span>Generating...</span>
                </>
              ) : (
                <>
                  <span>✨</span>
                  <span>Generate</span>
                </>
              )}
            </button>

            {/* Progress Bar */}
            {isGenerating && (
              <div className="bg-gray-900/80 rounded-lg p-3">
                <div className="flex justify-between text-xs text-gray-400 mb-2">
                  <span>Progress</span>
                  <span>{progress}%</span>
                </div>
                <div className="w-full h-2 bg-gray-800 rounded-full overflow-hidden">
                  <div
                    className="h-full bg-gradient-to-r from-amber-500 to-orange-500 transition-all duration-300"
                    style={{ width: `${progress}%` }}
                  />
                </div>
              </div>
            )}
          </div>

          {/* Center - Preview */}
          <div className="col-span-5">
            <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-amber-500/20 p-4 h-full">
              <h3 className="text-sm font-bold text-amber-400 mb-3">🖼️ Preview</h3>

              {/* Error */}
              {error && (
                <div className="mb-4 bg-red-900/30 border border-red-500/50 rounded-lg p-3 text-sm text-red-300">
                  ⚠️ {error}
                </div>
              )}

              {/* Image Display */}
              <div
                className="bg-black rounded-lg overflow-hidden border-2 border-amber-500/30 mb-4"
                style={{ minHeight: "512px" }}
              >
                {selectedImage ? (
                  <img src={selectedImage.url} alt="Generated" className="w-full h-full object-contain" />
                ) : (
                  <div className="flex items-center justify-center h-full min-h-[512px]">
                    <div className="text-center">
                      <div className="text-6xl mb-4 opacity-30">☀️</div>
                      <p className="text-gray-500">No image generated yet</p>
                      <p className="text-xs text-gray-600 mt-2">Enter a prompt and click Generate</p>
                    </div>
                  </div>
                )}
              </div>

              {/* Action Buttons */}
              {selectedImage && (
                <div className="grid grid-cols-4 gap-2">
                  <button
                    onClick={() => {
                      const link = document.createElement("a");
                      link.href = selectedImage.url;
                      link.download = `ra-${selectedImage.timestamp}.png`;
                      link.click();
                    }}
                    className="px-3 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg text-sm font-semibold transition"
                  >
                    💾 Save
                  </button>
                  <button
                    onClick={() => setParams({ ...params, prompt: selectedImage.params.prompt })}
                    className="px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm font-semibold transition"
                  >
                    📋 Copy
                  </button>
                  <button
                    onClick={handleVariations}
                    disabled={!sdAvailable || isGenerating}
                    className="px-3 py-2 bg-purple-600 hover:bg-purple-700 disabled:bg-gray-600 text-white rounded-lg text-sm font-semibold transition"
                  >
                    🔄 Vary
                  </button>
                  <button
                    onClick={handleUpscale}
                    disabled={!sdAvailable || isGenerating}
                    className="px-3 py-2 bg-orange-600 hover:bg-orange-700 disabled:bg-gray-600 text-white rounded-lg text-sm font-semibold transition"
                  >
                    ⬆️ 4x
                  </button>
                </div>
              )}

              {/* Generation Info */}
              {generationInfo && (
                <details className="mt-4">
                  <summary className="text-xs text-gray-400 cursor-pointer hover:text-amber-400">
                    Generation parameters
                  </summary>
                  <pre className="mt-2 bg-gray-800 rounded p-2 text-xs text-gray-300 overflow-auto max-h-32">
                    {generationInfo}
                  </pre>
                </details>
              )}
            </div>
          </div>

          {/* Right Panel - Gallery */}
          <div className="col-span-3">
            <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-amber-500/20 p-4">
              <h3 className="text-sm font-bold text-amber-400 mb-3">🎨 Gallery ({imageHistory.length})</h3>

              <div className="grid grid-cols-2 gap-2 max-h-[800px] overflow-y-auto">
                {imageHistory.map((img, idx) => (
                  <div
                    key={idx}
                    onClick={() => setSelectedImage(img)}
                    className={`relative cursor-pointer rounded-lg overflow-hidden border-2 transition ${
                      selectedImage === img
                        ? "border-amber-500 ring-2 ring-amber-500/50"
                        : "border-gray-700 hover:border-amber-500/50"
                    }`}
                  >
                    <img src={img.url} alt={`Generated ${idx}`} className="w-full h-full object-cover" />
                    <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent p-2">
                      <p className="text-xs text-white truncate">{img.params.prompt.substring(0, 30)}...</p>
                      <p className="text-xs text-gray-400">
                        {img.params.width}x{img.params.height}
                      </p>
                    </div>
                  </div>
                ))}
              </div>

              {imageHistory.length === 0 && (
                <div className="text-center py-8 text-gray-500">
                  <p className="text-sm">No images yet</p>
                  <p className="text-xs mt-1">Generated images will appear here</p>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Footer */}
      <div className="border-t border-amber-500/20 bg-gray-900/50 backdrop-blur mt-6 py-3">
        <div className="max-w-[2000px] mx-auto px-6 text-center text-xs text-gray-500">
          𓇳 Ra Image Generation Studio • Powered by Stable Diffusion 2.1 • {sdAvailable ? "🟢 Connected" : "🔴 Offline"}
        </div>
      </div>
    </div>
  );
}
