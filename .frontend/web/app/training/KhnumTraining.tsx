import React, { useState } from "react";
import { Icon } from "@iconify/react";

/**
 * Khnum Training - 3D & Game AI Training
 * For: 3D Modeling, System Recommendations, Code Generation, Game AI
 */
export const KhnumTraining: React.FC = () => {
  const [trainingType, setTrainingType] = useState<"3d" | "code" | "game">("code");

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <span className="text-5xl">🏺</span>
        <div>
          <h2 className="text-3xl font-bold text-white">Khnum - 3D & Game AI Training</h2>
          <p className="text-gray-400">Trenuj modele 3D, generacji kodu i AI dla gier</p>
        </div>
      </div>

      {/* Training Type Selection */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Wybierz Typ Treningu</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button
            onClick={() => setTrainingType("3d")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "3d"
                ? "bg-emerald-500/20 border-emerald-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:cube-outline" width={32} className="mx-auto mb-2" />
            <div className="font-bold">3D Modeling</div>
            <div className="text-xs mt-1">Tripo SR training</div>
          </button>

          <button
            onClick={() => setTrainingType("code")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "code"
                ? "bg-teal-500/20 border-teal-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:code-braces" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Code Generation</div>
            <div className="text-xs mt-1">StarCoder 7B fine-tuning</div>
          </button>

          <button
            onClick={() => setTrainingType("game")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "game"
                ? "bg-cyan-500/20 border-cyan-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:gamepad-variant" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Game AI & Recommendations</div>
            <div className="text-xs mt-1">RecBole training</div>
          </button>
        </div>
      </div>

      {/* 3D Modeling Training */}
      {trainingType === "3d" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">3D Model Training Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">3D Models (OBJ/FBX/GLB)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:cube-scan" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload 3D model files</div>
                <div className="text-sm text-gray-400 mt-1">OBJ, FBX, GLB, GLTF formats</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Reference Images (Multi-view)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:image-multiple" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload reference images</div>
                <div className="text-sm text-gray-400 mt-1">Front, side, top views for each model</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Model Category</label>
              <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-emerald-500 focus:outline-none">
                <option>Characters</option>
                <option>Props</option>
                <option>Architecture</option>
                <option>Vehicles</option>
                <option>Nature</option>
                <option>Furniture</option>
              </select>
            </div>

            <div className="bg-emerald-900/20 border border-emerald-500/30 rounded-lg p-4">
              <div className="flex gap-2 text-emerald-400 text-sm">
                <Icon icon="mdi:information" width={20} className="flex-shrink-0 mt-0.5" />
                <div>
                  <strong>Tip:</strong> Modele powinny być clean topology, proper UVs, consistent scale. Minimum 50 modeli
                  dla dobrego wyniku.
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Code Generation Training */}
      {trainingType === "code" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Code Training Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Programming Languages</label>
              <div className="flex flex-wrap gap-2">
                {["Python", "JavaScript", "TypeScript", "Go", "Rust", "C++", "Java"].map((lang) => (
                  <button
                    key={lang}
                    className="px-4 py-2 bg-white/5 border border-white/10 rounded-lg text-gray-300 hover:bg-white/10 transition text-sm"
                  >
                    {lang}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Code Files (ZIP/Git Repo)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:file-code" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload codebase</div>
                <div className="text-sm text-gray-400 mt-1">ZIP archive or Git repository URL</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Code-Comment Pairs (Optional)</label>
              <textarea
                className="w-full px-4 py-3 bg-black/30 border border-white/20 rounded-lg text-white text-sm focus:border-teal-500 focus:outline-none font-mono"
                rows={8}
                placeholder={`# Comment: Function to calculate factorial
def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n-1)

# Comment: React component for user profile
const UserProfile = ({ user }) => {
    return <div>{user.name}</div>;
};`}
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Training Focus</label>
              <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-teal-500 focus:outline-none">
                <option>General Code Completion</option>
                <option>Bug Fixing</option>
                <option>Code Refactoring</option>
                <option>Documentation Generation</option>
                <option>Test Case Generation</option>
              </select>
            </div>
          </div>
        </div>
      )}

      {/* Game AI & Recommendations Training */}
      {trainingType === "game" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Game AI Training Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Training Type</label>
              <div className="grid grid-cols-2 gap-4">
                <button className="p-4 bg-white/5 border border-white/10 rounded-lg text-white hover:bg-white/10 transition">
                  <Icon icon="mdi:robot" width={32} className="mx-auto mb-2" />
                  <div className="font-bold text-sm">Game NPC AI</div>
                  <div className="text-xs text-gray-400 mt-1">Behavior patterns</div>
                </button>
                <button className="p-4 bg-cyan-500/20 border border-cyan-500 rounded-lg text-white">
                  <Icon icon="mdi:star-outline" width={32} className="mx-auto mb-2" />
                  <div className="font-bold text-sm">Recommendation System</div>
                  <div className="text-xs text-gray-400 mt-1">User preferences</div>
                </button>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">User-Item Interactions (CSV)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:table" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload interaction data</div>
                <div className="text-sm text-gray-400 mt-1">
                  CSV: user_id, item_id, rating, timestamp
                </div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Sample Format</label>
              <div className="bg-black/20 rounded-lg p-4 font-mono text-xs text-gray-300 overflow-x-auto">
                user_id,item_id,rating,timestamp<br />
                user_001,game_123,5,2024-01-15<br />
                user_001,game_456,4,2024-01-16<br />
                user_002,game_123,3,2024-01-17
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Recommendation Algorithm</label>
              <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-cyan-500 focus:outline-none">
                <option>Collaborative Filtering</option>
                <option>Content-Based</option>
                <option>Hybrid (CF + Content)</option>
                <option>Matrix Factorization</option>
                <option>Neural Collaborative Filtering</option>
              </select>
            </div>
          </div>
        </div>
      )}

      {/* Training Configuration */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Konfiguracja</h3>
        <div className="grid grid-cols-4 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Epochs</label>
            <input
              type="number"
              defaultValue={10}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-emerald-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Batch Size</label>
            <input
              type="number"
              defaultValue={16}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-emerald-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Learning Rate</label>
            <input
              type="number"
              step="0.0001"
              defaultValue={0.0001}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-emerald-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">GPU Memory</label>
            <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-emerald-500 focus:outline-none">
              <option>6GB</option>
              <option>8GB</option>
              <option>12GB</option>
              <option>16GB</option>
            </select>
          </div>
        </div>
      </div>

      {/* Start Button */}
      <button className="w-full px-6 py-4 bg-gradient-to-r from-emerald-600 to-teal-600 text-white rounded-lg font-bold text-lg hover:opacity-90 transition flex items-center justify-center gap-2">
        <Icon icon="mdi:play" width={24} />
        Start Khnum Training
      </button>
    </div>
  );
};

