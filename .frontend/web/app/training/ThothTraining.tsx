import React, { useState } from "react";
import { Icon } from "@iconify/react";

/**
 * Thoth Training - NLP Stack Training Interface
 * For: Text Generation, OCR, Translation, Document Analysis
 */
export const ThothTraining: React.FC = () => {
  const [datasetType, setDatasetType] = useState<"text" | "documents" | "translation">("text");
  const [trainingProgress, setTrainingProgress] = useState(0);
  const [isTraining, setIsTraining] = useState(false);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <span className="text-5xl">📚</span>
        <div>
          <h2 className="text-3xl font-bold text-white">Thoth - NLP Training</h2>
          <p className="text-gray-400">Trenuj modele do przetwarzania tekstu i dokumentów</p>
        </div>
      </div>

      {/* Training Type Selection */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Wybierz Typ Treningu</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button
            onClick={() => setDatasetType("text")}
            className={`p-4 rounded-lg border-2 transition ${
              datasetType === "text"
                ? "bg-blue-500/20 border-blue-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:text" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Text Generation</div>
            <div className="text-xs mt-1">Mistral 7B fine-tuning</div>
          </button>

          <button
            onClick={() => setDatasetType("documents")}
            className={`p-4 rounded-lg border-2 transition ${
              datasetType === "documents"
                ? "bg-purple-500/20 border-purple-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:file-document-outline" width={32} className="mx-auto mb-2" />
            <div className="font-bold">OCR & Document Analysis</div>
            <div className="text-xs mt-1">PaddleOCR + Donut training</div>
          </button>

          <button
            onClick={() => setDatasetType("translation")}
            className={`p-4 rounded-lg border-2 transition ${
              datasetType === "translation"
                ? "bg-green-500/20 border-green-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:translate" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Translation</div>
            <div className="text-xs mt-1">Opus-MT fine-tuning</div>
          </button>
        </div>
      </div>

      {/* Data Upload Section */}
      {datasetType === "text" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Upload Text Training Data</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Training Texts (JSON/TXT)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:upload" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Drop text files here or click to browse</div>
                <div className="text-sm text-gray-400 mt-1">
                  Supported: .txt, .json, .csv (Conversations, Q&A pairs)
                </div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Sample Conversations</label>
              <textarea
                className="w-full px-4 py-3 bg-black/30 border border-white/20 rounded-lg text-white text-sm focus:border-blue-500 focus:outline-none"
                rows={6}
                placeholder={`Example format:
User: Jak działa sztuczna inteligencja?
Assistant: Sztuczna inteligencja to...

User: Co to jest deep learning?
Assistant: Deep learning to...`}
              />
            </div>
          </div>
        </div>
      )}

      {datasetType === "documents" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Upload Document Scans</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Scanned Documents (Images)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:file-image" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Drop document images here</div>
                <div className="text-sm text-gray-400 mt-1">
                  Supported: .jpg, .png, .pdf (Faktury, dokumenty, paragony)
                </div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Ground Truth Labels (JSON)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:file-code" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload OCR labels</div>
                <div className="text-sm text-gray-400 mt-1">JSON with text annotations for each image</div>
              </div>
            </div>

            <div className="bg-yellow-900/20 border border-yellow-500/30 rounded-lg p-4">
              <div className="flex gap-2 text-yellow-400 text-sm">
                <Icon icon="mdi:information" width={20} className="flex-shrink-0 mt-0.5" />
                <div>
                  <strong>Format przykładowy:</strong> Każdy skan powinien mieć odpowiadający mu plik .txt z
                  wyekstraktowanym tekstem dla treningu OCR.
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {datasetType === "translation" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Upload Translation Pairs</h3>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Source Language</label>
                <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-green-500 focus:outline-none">
                  <option>Polski</option>
                  <option>English</option>
                  <option>Deutsch</option>
                  <option>Français</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Target Language</label>
                <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-green-500 focus:outline-none">
                  <option>English</option>
                  <option>Polski</option>
                  <option>Deutsch</option>
                  <option>Français</option>
                </select>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Translation Pairs Dataset</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:translate" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload parallel corpus</div>
                <div className="text-sm text-gray-400 mt-1">CSV with source and target text columns</div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Training Configuration */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Konfiguracja Treningu</h3>
        <div className="grid grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Epochs</label>
            <input
              type="number"
              defaultValue={3}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-blue-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Learning Rate</label>
            <input
              type="number"
              step="0.0001"
              defaultValue={0.0002}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-blue-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">LoRA Rank</label>
            <input
              type="number"
              defaultValue={8}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-blue-500 focus:outline-none"
            />
          </div>
        </div>
      </div>

      {/* Training Controls */}
      <div className="flex gap-4">
        <button
          onClick={() => setIsTraining(true)}
          disabled={isTraining}
          className="flex-1 px-6 py-4 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-lg font-bold text-lg hover:opacity-90 transition disabled:opacity-50 flex items-center justify-center gap-2"
        >
          <Icon icon="mdi:play" width={24} />
          Start Training
        </button>
        {isTraining && (
          <button className="px-6 py-4 bg-red-600 text-white rounded-lg font-bold hover:bg-red-700 transition">
            Stop Training
          </button>
        )}
      </div>

      {/* Training Progress */}
      {isTraining && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Training Progress</h3>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between text-sm text-gray-300 mb-2">
                <span>Epoch 1/3</span>
                <span>45%</span>
              </div>
              <div className="w-full h-3 bg-black/30 rounded-full overflow-hidden">
                <div className="h-full bg-gradient-to-r from-blue-500 to-purple-500" style={{ width: "45%" }} />
              </div>
            </div>
            <div className="grid grid-cols-3 gap-4 text-sm">
              <div className="bg-black/20 rounded-lg p-3">
                <div className="text-gray-400">Loss</div>
                <div className="text-white font-bold text-lg">2.456</div>
              </div>
              <div className="bg-black/20 rounded-lg p-3">
                <div className="text-gray-400">Accuracy</div>
                <div className="text-white font-bold text-lg">67.8%</div>
              </div>
              <div className="bg-black/20 rounded-lg p-3">
                <div className="text-gray-400">Time Remaining</div>
                <div className="text-white font-bold text-lg">12 min</div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

