import React, { useState } from "react";
import { Icon } from "@iconify/react";

/**
 * Ra Training - Image & Video Generation Training
 * For: Stable Diffusion, Image Editing, Upscaling, Style Transfer
 */
export const RaTraining: React.FC = () => {
  const [trainingType, setTrainingType] = useState<"generation" | "upscaling" | "style">("generation");

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <span className="text-5xl">☀️</span>
        <div>
          <h2 className="text-3xl font-bold text-white">Ra - Image & Video Training</h2>
          <p className="text-gray-400">Trenuj modele do generacji i edycji obrazów</p>
        </div>
      </div>

      {/* Training Type Selection */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Wybierz Typ Treningu</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button
            onClick={() => setTrainingType("generation")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "generation"
                ? "bg-amber-500/20 border-amber-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:image-plus" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Image Generation</div>
            <div className="text-xs mt-1">Stable Diffusion 2.1 LoRA</div>
          </button>

          <button
            onClick={() => setTrainingType("upscaling")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "upscaling"
                ? "bg-orange-500/20 border-orange-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:arrow-expand-all" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Image Upscaling</div>
            <div className="text-xs mt-1">RealESRGAN fine-tuning</div>
          </button>

          <button
            onClick={() => setTrainingType("style")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "style"
                ? "bg-yellow-500/20 border-yellow-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:palette" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Style Transfer</div>
            <div className="text-xs mt-1">Custom style training</div>
          </button>
        </div>
      </div>

      {/* Image Generation Training */}
      {trainingType === "generation" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Training Images for SD LoRA</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">
                Reference Images (High Quality)
              </label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:image-multiple" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Drop 20-100 images here</div>
                <div className="text-sm text-gray-400 mt-1">
                  JPG/PNG, minimum 512x512, similar style/subject
                </div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Text Prompts (Captions)</label>
              <textarea
                className="w-full px-4 py-3 bg-black/30 border border-white/20 rounded-lg text-white text-sm focus:border-amber-500 focus:outline-none"
                rows={4}
                placeholder="Enter prompts for each image (one per line):
a photo of [subject] in [style]
detailed [subject], high quality
..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">LoRA Trigger Word</label>
              <input
                type="text"
                placeholder="np. 'sks', 'my_style'"
                className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-amber-500 focus:outline-none"
              />
              <p className="text-xs text-gray-400 mt-1">Słowo aktywujące twój custom LoRA w promptach</p>
            </div>
          </div>
        </div>
      )}

      {/* Upscaling Training */}
      {trainingType === "upscaling" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Upscaling Training Pairs</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Low Resolution Images</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:image-size-select-small" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload low-res images</div>
                <div className="text-sm text-gray-400 mt-1">256x256 or 512x512 source images</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">High Resolution Images (Ground Truth)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:image-size-select-large" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload high-res images</div>
                <div className="text-sm text-gray-400 mt-1">2048x2048 or 4096x4096 target images</div>
              </div>
            </div>

            <div className="bg-blue-900/20 border border-blue-500/30 rounded-lg p-4">
              <div className="flex gap-2 text-blue-400 text-sm">
                <Icon icon="mdi:information" width={20} className="flex-shrink-0 mt-0.5" />
                <div>
                  <strong>Wymóg:</strong> Każdy obraz low-res musi mieć odpowiadający mu high-res z taką samą nazwą.
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Style Transfer Training */}
      {trainingType === "style" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Style Training Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Style Reference Images</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:brush" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload 10-50 style examples</div>
                <div className="text-sm text-gray-400 mt-1">Images with the style you want to replicate</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Style Description</label>
              <textarea
                className="w-full px-4 py-3 bg-black/30 border border-white/20 rounded-lg text-white text-sm focus:border-yellow-500 focus:outline-none"
                rows={3}
                placeholder="Describe the style: colors, textures, artistic technique..."
              />
            </div>
          </div>
        </div>
      )}

      {/* Training Configuration */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Konfiguracja</h3>
        <div className="grid grid-cols-4 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Steps</label>
            <input
              type="number"
              defaultValue={1000}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-amber-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Learning Rate</label>
            <input
              type="number"
              step="0.00001"
              defaultValue={0.00001}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-amber-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Batch Size</label>
            <input
              type="number"
              defaultValue={2}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-amber-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">LoRA Rank</label>
            <input
              type="number"
              defaultValue={16}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-amber-500 focus:outline-none"
            />
          </div>
        </div>
      </div>

      {/* Start Button */}
      <button className="w-full px-6 py-4 bg-gradient-to-r from-amber-600 to-orange-600 text-white rounded-lg font-bold text-lg hover:opacity-90 transition flex items-center justify-center gap-2">
        <Icon icon="mdi:play" width={24} />
        Start Ra Training
      </button>
    </div>
  );
};

