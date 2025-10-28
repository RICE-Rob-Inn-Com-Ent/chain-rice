import React, { useState } from "react";
import { Icon } from "@iconify/react";

/**
 * Bastet Training - Computer Vision Training
 * For: Face Recognition, Pose Estimation, Object Detection, Visual QA
 */
export const BastetTraining: React.FC = () => {
  const [trainingType, setTrainingType] = useState<"faces" | "objects" | "pose">("faces");

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <span className="text-5xl">🐱</span>
        <div>
          <h2 className="text-3xl font-bold text-white">Bastet - Computer Vision Training</h2>
          <p className="text-gray-400">Trenuj modele wykrywania obiektów i analiz

y obrazów</p>
        </div>
      </div>

      {/* Training Type Selection */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Wybierz Typ Treningu</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button
            onClick={() => setTrainingType("faces")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "faces"
                ? "bg-yellow-500/20 border-yellow-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:face-recognition" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Face Recognition</div>
            <div className="text-xs mt-1">InsightFace training</div>
          </button>

          <button
            onClick={() => setTrainingType("objects")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "objects"
                ? "bg-amber-500/20 border-amber-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:cube-scan" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Object Detection</div>
            <div className="text-xs mt-1">MMDetection fine-tuning</div>
          </button>

          <button
            onClick={() => setTrainingType("pose")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "pose"
                ? "bg-orange-500/20 border-orange-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:human" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Pose Estimation</div>
            <div className="text-xs mt-1">MMPose training</div>
          </button>
        </div>
      </div>

      {/* Face Recognition Training */}
      {trainingType === "faces" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Face Recognition Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Face Images by Person</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:account-multiple" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload faces organized by folders</div>
                <div className="text-sm text-gray-400 mt-1">
                  Each folder = one person, 10-50 photos per person
                </div>
              </div>
            </div>

            <div className="bg-black/20 rounded-lg p-4 font-mono text-sm text-gray-300">
              <div>Struktura folderów:</div>
              <div className="mt-2 ml-4">
                faces/<br />
                ├── person_1/<br />
                │   ├── photo1.jpg<br />
                │   ├── photo2.jpg<br />
                │   └── ...<br />
                ├── person_2/<br />
                │   ├── photo1.jpg<br />
                │   └── ...<br />
              </div>
            </div>

            <div className="bg-yellow-900/20 border border-yellow-500/30 rounded-lg p-4">
              <div className="flex gap-2 text-yellow-400 text-sm">
                <Icon icon="mdi:information" width={20} className="flex-shrink-0 mt-0.5" />
                <div>
                  <strong>Wymogi:</strong> Zdjęcia twarzy w różnych ujęciach, oświetleniu, wyrazach. Minimum 640x640px.
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Object Detection Training */}
      {trainingType === "objects" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Object Detection Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Training Images</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:image-multiple" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload images with objects</div>
                <div className="text-sm text-gray-400 mt-1">JPG/PNG, minimum 100 images</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Annotations (COCO/YOLO Format)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:vector-rectangle" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload bounding box annotations</div>
                <div className="text-sm text-gray-400 mt-1">COCO JSON or YOLO TXT format</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Object Classes</label>
              <input
                type="text"
                placeholder="car, person, dog, bicycle (comma separated)"
                className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-amber-500 focus:outline-none"
              />
            </div>

            <div className="bg-blue-900/20 border border-blue-500/30 rounded-lg p-4">
              <div className="flex gap-2 text-blue-400 text-sm">
                <Icon icon="mdi:information" width={20} className="flex-shrink-0 mt-0.5" />
                <div>
                  <strong>Tip:</strong> Użyj narzędzi jak LabelImg, CVAT lub RoboFlow do tworzenia annotacji.
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Pose Estimation Training */}
      {trainingType === "pose" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Pose Estimation Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Human Pose Images</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:human-handsup" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload images with people</div>
                <div className="text-sm text-gray-400 mt-1">Different poses, angles, activities</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Keypoint Annotations (JSON)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:dots-hexagon" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload skeleton keypoints</div>
                <div className="text-sm text-gray-400 mt-1">COCO keypoint format (17 points)</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Keypoint Schema</label>
              <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-orange-500 focus:outline-none">
                <option>COCO (17 keypoints)</option>
                <option>MPII (16 keypoints)</option>
                <option>OpenPose (25 keypoints)</option>
                <option>Custom</option>
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
              defaultValue={50}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-yellow-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Batch Size</label>
            <input
              type="number"
              defaultValue={16}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-yellow-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Learning Rate</label>
            <input
              type="number"
              step="0.0001"
              defaultValue={0.001}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-yellow-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Image Size</label>
            <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-yellow-500 focus:outline-none">
              <option>640x640</option>
              <option>1024x1024</option>
              <option>1280x1280</option>
            </select>
          </div>
        </div>
      </div>

      {/* Start Button */}
      <button className="w-full px-6 py-4 bg-gradient-to-r from-yellow-600 to-amber-600 text-white rounded-lg font-bold text-lg hover:opacity-90 transition flex items-center justify-center gap-2">
        <Icon icon="mdi:play" width={24} />
        Start Bastet Training
      </button>
    </div>
  );
};

