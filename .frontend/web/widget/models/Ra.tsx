'use client';
import { useState, useEffect } from 'react';
import { generateImage, checkSDHealth, upscaleImage, generateVariations } from '../../lib/services/stableDiffusion';

interface GenerationParams {
  prompt: string;
  negativePrompt: string;
  steps: number;
  cfgScale: number;
  width: number;
  height: number;
  seed: number;
}

export default function RaUI() {
  const [params, setParams] = useState<GenerationParams>({
    prompt: '',
    negativePrompt: 'blurry, low quality, distorted',
    steps: 30,
    cfgScale: 7.5,
    width: 512,
    height: 512,
    seed: -1,
  });
  const [generatedImage, setGeneratedImage] = useState<string | null>(null);
  const [isGenerating, setIsGenerating] = useState(false);
  const [sdAvailable, setSdAvailable] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Check if Stable Diffusion is available
  useEffect(() => {
    checkSDHealth().then(setSdAvailable);
  }, []);

  const handleGenerate = async () => {
    if (!params.prompt.trim()) {
      alert('Wprowadź prompt!');
      return;
    }

    setIsGenerating(true);
    setError(null);

    try {
      if (sdAvailable) {
        // Use real Stable Diffusion API
        const result = await generateImage({
          prompt: params.prompt,
          negative_prompt: params.negativePrompt,
          steps: params.steps,
          cfg_scale: params.cfgScale,
          width: params.width,
          height: params.height,
          seed: params.seed,
        });

        // Convert base64 to data URL
        if (result.images && result.images.length > 0) {
          setGeneratedImage(`data:image/png;base64,${result.images[0]}`);
        }
      } else {
        // Fallback to placeholder if SD not available
        console.warn('[Ra] Stable Diffusion not available, using placeholder');
        await new Promise((resolve) => setTimeout(resolve, 2000));
        setGeneratedImage(`https://picsum.photos/${params.width}/${params.height}?random=${Date.now()}`);
        setError('Stable Diffusion WebUI not running. Using placeholder. Start WebUI on port 7860.');
      }
    } catch (error: any) {
      console.error('[Ra] Generation error:', error);
      setError(`Generation failed: ${error.message}`);
      // Fallback to placeholder on error
      setGeneratedImage(`https://picsum.photos/${params.width}/${params.height}?random=${Date.now()}`);
    } finally {
      setIsGenerating(false);
    }
  };

  const handleUpscale = async () => {
    if (!generatedImage) return;

    setIsGenerating(true);
    setError(null);

    try {
      // Extract base64 from data URL
      const base64 = generatedImage.replace(/^data:image\/\w+;base64,/, '');
      const result = await upscaleImage(base64, 'RealESRGAN_x4plus', 4);
      setGeneratedImage(`data:image/png;base64,${result.image}`);
    } catch (error: any) {
      console.error('[Ra] Upscale error:', error);
      setError(`Upscale failed: ${error.message}`);
    } finally {
      setIsGenerating(false);
    }
  };

  const handleVariations = async () => {
    if (!generatedImage || !params.prompt) return;

    setIsGenerating(true);
    setError(null);

    try {
      const base64 = generatedImage.replace(/^data:image\/\w+;base64,/, '');
      const result = await generateVariations(base64, params.prompt, 0.5);
      if (result.images && result.images.length > 0) {
        setGeneratedImage(`data:image/png;base64,${result.images[0]}`);
      }
    } catch (error: any) {
      console.error('[Ra] Variations error:', error);
      setError(`Variations failed: ${error.message}`);
    } finally {
      setIsGenerating(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-orange-900/20 via-black to-red-900/20 text-white p-4">
      {/* Header */}
      <div className="max-w-7xl mx-auto mb-6">
        <div className="bg-gradient-to-r from-amber-900/30 to-orange-900/30 rounded-2xl p-6 border border-amber-500/30">
          <div className="flex items-center gap-4">
            <div className="text-6xl">☀️</div>
            <div>
              <h1 className="text-3xl font-bold bg-gradient-to-r from-amber-400 via-orange-500 to-red-600 bg-clip-text text-transparent">
                Ra - Bóg Światła i Kreacji
              </h1>
              <p className="text-sm text-gray-400 mt-1">Stable Diffusion 2.1 FP16 • RealESRGAN • RVM</p>
              <p className="text-xs text-amber-400/70 mt-1">Optimized for 6GB VRAM</p>
              <div className="flex items-center gap-2 mt-2">
                <div className={`w-2 h-2 rounded-full ${sdAvailable ? 'bg-green-500 animate-pulse' : 'bg-red-500'}`} />
                <span className="text-xs text-gray-400">
                  {sdAvailable ? 'WebUI Connected (port 7860)' : 'WebUI Offline - Using placeholders'}
                </span>
              </div>
              <div className="flex gap-4 mt-2 text-xs text-amber-400">
                <span>✓ Image Generation (SD 2.1)</span>
                <span>✓ Upscaling (4x)</span>
                <span>✓ Background Removal</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Control Panel */}
        <div className="lg:col-span-1 space-y-4">
          {/* Model Info */}
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-4">
            <h3 className="text-lg font-bold mb-3 text-amber-400">Active Model</h3>
            <div className="space-y-2">
              <div className="bg-gradient-to-r from-amber-600 to-orange-600 text-white p-3 rounded-lg text-center">
                <div className="text-3xl mb-1">🎨</div>
                <div className="font-bold text-sm">Stable Diffusion 2.1</div>
                <div className="text-xs opacity-70">FP16 • 6GB VRAM</div>
              </div>
              <div className="text-xs text-gray-400 space-y-1">
                <div>• Attention Slicing</div>
                <div>• VAE Slicing</div>
                <div>• Memory Optimized</div>
              </div>
            </div>
          </div>

          {/* Parameters */}
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-4">
            <h3 className="text-lg font-bold mb-3 text-amber-400">Parameters</h3>
            <div className="space-y-4">
              {/* Prompt */}
              <div>
                <label className="block text-sm font-semibold mb-2">Prompt</label>
                <textarea
                  value={params.prompt}
                  onChange={(e) => setParams({ ...params, prompt: e.target.value })}
                  placeholder="A beautiful sunset over Egyptian pyramids..."
                  className="w-full bg-gray-800 text-white rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500 min-h-[80px]"
                />
              </div>

              {/* Negative Prompt */}
              <div>
                <label className="block text-sm font-semibold mb-2">Negative Prompt</label>
                <textarea
                  value={params.negativePrompt}
                  onChange={(e) => setParams({ ...params, negativePrompt: e.target.value })}
                  className="w-full bg-gray-800 text-white rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500 min-h-[60px]"
                />
              </div>

              {/* Steps */}
              <div>
                <label className="block text-sm font-semibold mb-2">
                  Steps: <span className="text-amber-400">{params.steps}</span>
                </label>
                <input
                  type="range"
                  min="10"
                  max="100"
                  value={params.steps}
                  onChange={(e) => setParams({ ...params, steps: parseInt(e.target.value) })}
                  className="w-full"
                />
              </div>

              {/* CFG Scale */}
              <div>
                <label className="block text-sm font-semibold mb-2">
                  CFG Scale: <span className="text-amber-400">{params.cfgScale}</span>
                </label>
                <input
                  type="range"
                  min="1"
                  max="20"
                  step="0.5"
                  value={params.cfgScale}
                  onChange={(e) => setParams({ ...params, cfgScale: parseFloat(e.target.value) })}
                  className="w-full"
                />
              </div>

              {/* Dimensions */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-semibold mb-2">Width</label>
                  <select
                    value={params.width}
                    onChange={(e) => setParams({ ...params, width: parseInt(e.target.value) })}
                    className="w-full bg-gray-800 text-white rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
                  >
                    <option value="512">512</option>
                    <option value="768">768</option>
                    <option value="1024">1024</option>
                  </select>
                </div>
                <div>
                  <label className="block text-sm font-semibold mb-2">Height</label>
                  <select
                    value={params.height}
                    onChange={(e) => setParams({ ...params, height: parseInt(e.target.value) })}
                    className="w-full bg-gray-800 text-white rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-amber-500"
                  >
                    <option value="512">512</option>
                    <option value="768">768</option>
                    <option value="1024">1024</option>
                  </select>
                </div>
              </div>

              {/* Generate Button */}
              <button
                onClick={handleGenerate}
                disabled={isGenerating}
                className="w-full bg-gradient-to-r from-amber-600 to-orange-600 hover:from-amber-700 hover:to-orange-700 disabled:from-gray-700 disabled:to-gray-800 text-white py-3 rounded-lg font-bold text-lg transition-all disabled:cursor-not-allowed shadow-lg hover:shadow-amber-500/50"
              >
                {isGenerating ? '⏳ Generating...' : '✨ Generate'}
              </button>
            </div>
          </div>
        </div>

        {/* Preview Area */}
        <div className="lg:col-span-2">
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6 min-h-[600px] flex flex-col">
            <h3 className="text-lg font-bold mb-4 text-amber-400">Preview</h3>

            {isGenerating ? (
              <div className="flex-1 flex items-center justify-center">
                <div className="text-center">
                  <div className="text-6xl mb-4 animate-spin">☀️</div>
                  <p className="text-xl font-bold text-amber-400">Ra tworzy światło...</p>
                  <p className="text-sm text-gray-400 mt-2">Generowanie obrazu w trakcie</p>
                </div>
              </div>
            ) : generatedImage ? (
              <div className="flex-1 flex flex-col">
                <div className="flex-1 bg-black rounded-lg overflow-hidden border-2 border-amber-500/30 mb-4">
                  <img src={generatedImage} alt="Generated" className="w-full h-full object-contain" />
                </div>
                <div className="flex gap-2">
                  <button className="flex-1 bg-green-600 hover:bg-green-700 text-white py-2 px-4 rounded-lg font-semibold transition-all">
                    💾 Save
                  </button>
                  <button className="flex-1 bg-blue-600 hover:bg-blue-700 text-white py-2 px-4 rounded-lg font-semibold transition-all">
                    🔄 Variations
                  </button>
                  <button className="flex-1 bg-purple-600 hover:bg-purple-700 text-white py-2 px-4 rounded-lg font-semibold transition-all">
                    ⬆️ Upscale
                  </button>
                </div>
              </div>
            ) : (
              <div className="flex-1 flex items-center justify-center text-center">
                <div>
                  <div className="text-6xl mb-4 opacity-50">☀️</div>
                  <p className="text-gray-400">Wprowadź prompt i kliknij Generate</p>
                  <p className="text-sm text-gray-600 mt-2">Ra czeka na twoje polecenie kreacji</p>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Footer */}
      <div className="max-w-7xl mx-auto mt-6 text-center text-xs text-gray-500">
        𓇳 Ra Demo Interface • Stable Diffusion 2.1 FP16 • 6GB VRAM Optimized • Demo Mode
      </div>
    </div>
  );
}
