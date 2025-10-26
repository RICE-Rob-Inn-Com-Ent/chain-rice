"use client";
import { useState, useRef, useEffect } from "react";

export default function BastetDemoPage() {
  const [isCamera, setIsCamera] = useState(false);
  const [uploadedImage, setUploadedImage] = useState<string | null>(null);
  const [detections, setDetections] = useState<any>(null);
  const [isProcessing, setIsProcessing] = useState(false);
  const [activeModel, setActiveModel] = useState<"face" | "pose" | "object">("face");
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  const startCamera = async () => {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: true });
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
        setIsCamera(true);
      }
    } catch (error) {
      console.error("Camera error:", error);
      alert("Nie można uzyskać dostępu do kamery");
    }
  };

  const stopCamera = () => {
    if (videoRef.current && videoRef.current.srcObject) {
      const tracks = (videoRef.current.srcObject as MediaStream).getTracks();
      tracks.forEach((track) => track.stop());
      videoRef.current.srcObject = null;
      setIsCamera(false);
    }
  };

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const reader = new FileReader();
      reader.onload = (event) => {
        setUploadedImage(event.target?.result as string);
        stopCamera();
      };
      reader.readAsDataURL(e.target.files[0]);
    }
  };

  const handleDetect = async () => {
    setIsProcessing(true);
    try {
      await new Promise((resolve) => setTimeout(resolve, 1500));

      // Symulowane detekcje
      const mockDetections = {
        faces:
          activeModel === "face"
            ? [
                {
                  id: 1,
                  confidence: 0.95,
                  age: "25-35",
                  gender: "Female",
                  emotion: "Happy",
                  bbox: [120, 80, 200, 180],
                },
                {
                  id: 2,
                  confidence: 0.88,
                  age: "30-40",
                  gender: "Male",
                  emotion: "Neutral",
                  bbox: [350, 100, 180, 200],
                },
              ]
            : [],
        poses:
          activeModel === "pose"
            ? [
                { id: 1, confidence: 0.92, posture: "Standing", keypoints: 17 },
                { id: 2, confidence: 0.87, posture: "Sitting", keypoints: 17 },
              ]
            : [],
        objects:
          activeModel === "object"
            ? [
                { id: 1, class: "person", confidence: 0.96, bbox: [100, 50, 250, 400] },
                { id: 2, class: "chair", confidence: 0.82, bbox: [320, 280, 150, 180] },
                { id: 3, class: "laptop", confidence: 0.78, bbox: [200, 200, 120, 80] },
              ]
            : [],
        timestamp: new Date().toISOString(),
      };

      setDetections(mockDetections);
    } catch (error) {
      console.error("Error:", error);
    } finally {
      setIsProcessing(false);
    }
  };

  useEffect(() => {
    return () => {
      stopCamera();
    };
  }, []);

  return (
    <div className="min-h-screen bg-gradient-to-b from-yellow-900/20 via-black to-orange-900/20 text-white p-4">
      {/* Header */}
      <div className="max-w-7xl mx-auto mb-6">
        <div className="bg-gradient-to-r from-yellow-900/30 to-amber-900/30 rounded-2xl p-6 border border-yellow-500/30">
          <div className="flex items-center gap-4">
            <div className="text-6xl">🐱</div>
            <div>
              <h1 className="text-3xl font-bold bg-gradient-to-r from-yellow-400 via-amber-500 to-orange-600 bg-clip-text text-transparent">
                Bastet - Bogini Wzroku
              </h1>
              <p className="text-sm text-gray-400 mt-1">InsightFace • MMPose • MMDetection • LLaVa-13B</p>
              <div className="flex gap-4 mt-2 text-xs text-yellow-400">
                <span>✓ Face Recognition</span>
                <span>✓ Pose Estimation</span>
                <span>✓ Object Detection</span>
                <span>✓ Real-time Analysis</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Controls */}
        <div className="lg:col-span-1 space-y-4">
          {/* Model Selection */}
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-4">
            <h3 className="text-lg font-bold mb-3 text-yellow-400">Detection Model</h3>
            <div className="space-y-2">
              {[
                { id: "face", label: "Face Recognition", icon: "👤", desc: "InsightFace" },
                { id: "pose", label: "Pose Estimation", icon: "🤸", desc: "MMPose" },
                { id: "object", label: "Object Detection", icon: "🔍", desc: "MMDetection" },
              ].map((model) => (
                <button
                  key={model.id}
                  onClick={() => setActiveModel(model.id as any)}
                  className={`w-full p-3 rounded-lg text-left transition-all ${
                    activeModel === model.id
                      ? "bg-gradient-to-r from-yellow-600 to-amber-600 text-white"
                      : "bg-gray-800 text-gray-400 hover:bg-gray-700"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <span className="text-2xl">{model.icon}</span>
                    <div>
                      <div className="font-semibold text-sm">{model.label}</div>
                      <div className="text-xs opacity-70">{model.desc}</div>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          </div>

          {/* Input Source */}
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-4">
            <h3 className="text-lg font-bold mb-3 text-yellow-400">Input Source</h3>
            <div className="space-y-2">
              <button
                onClick={isCamera ? stopCamera : startCamera}
                className={`w-full py-3 rounded-lg font-semibold transition-all ${
                  isCamera ? "bg-red-600 hover:bg-red-700" : "bg-green-600 hover:bg-green-700"
                }`}
              >
                {isCamera ? "📷 Stop Camera" : "📹 Start Camera"}
              </button>

              <label className="block cursor-pointer">
                <div className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-semibold text-center transition-all">
                  📤 Upload Image
                </div>
                <input type="file" onChange={handleImageUpload} accept="image/*" className="hidden" />
              </label>

              <button
                onClick={handleDetect}
                disabled={isProcessing || (!isCamera && !uploadedImage)}
                className="w-full bg-gradient-to-r from-yellow-600 to-amber-600 hover:from-yellow-700 hover:to-amber-700 disabled:from-gray-700 disabled:to-gray-800 text-white py-3 rounded-lg font-bold transition-all disabled:cursor-not-allowed"
              >
                {isProcessing ? "⏳ Detecting..." : "🔍 Detect"}
              </button>
            </div>
          </div>

          {/* Stats */}
          {detections && (
            <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-4">
              <h3 className="text-lg font-bold mb-3 text-yellow-400">Statistics</h3>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-400">Faces Detected:</span>
                  <span className="text-yellow-400 font-bold">{detections.faces?.length || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-400">Poses Detected:</span>
                  <span className="text-yellow-400 font-bold">{detections.poses?.length || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-400">Objects Detected:</span>
                  <span className="text-yellow-400 font-bold">{detections.objects?.length || 0}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-400">Timestamp:</span>
                  <span className="text-gray-500 text-xs">{new Date(detections.timestamp).toLocaleTimeString()}</span>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Preview & Results */}
        <div className="lg:col-span-2 space-y-4">
          {/* Video/Image Preview */}
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
            <h3 className="text-lg font-bold mb-4 text-yellow-400">Vision Feed</h3>
            <div
              className="bg-black rounded-lg overflow-hidden border-2 border-yellow-500/30 relative"
              style={{ height: "400px" }}
            >
              {isCamera ? (
                <video ref={videoRef} autoPlay playsInline className="w-full h-full object-cover" />
              ) : uploadedImage ? (
                <img src={uploadedImage} alt="Uploaded" className="w-full h-full object-contain" />
              ) : (
                <div className="w-full h-full flex items-center justify-center">
                  <div className="text-center">
                    <div className="text-6xl mb-4 opacity-50">🐱</div>
                    <p className="text-gray-400">Start camera or upload an image</p>
                  </div>
                </div>
              )}
              <canvas ref={canvasRef} className="absolute top-0 left-0 w-full h-full pointer-events-none" />
            </div>
          </div>

          {/* Detection Results */}
          {detections && (
            <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
              <h3 className="text-lg font-bold mb-4 text-yellow-400">Detection Results</h3>

              <div className="space-y-4">
                {/* Faces */}
                {detections.faces?.length > 0 && (
                  <div>
                    <h4 className="text-sm font-bold mb-2 text-yellow-400">👤 Faces</h4>
                    <div className="space-y-2">
                      {detections.faces.map((face: any) => (
                        <div key={face.id} className="bg-gray-800 rounded-lg p-3 border border-gray-700">
                          <div className="grid grid-cols-2 gap-2 text-xs">
                            <div>
                              <span className="text-gray-400">Confidence:</span>{" "}
                              <span className="text-green-400">{(face.confidence * 100).toFixed(1)}%</span>
                            </div>
                            <div>
                              <span className="text-gray-400">Age:</span>{" "}
                              <span className="text-yellow-400">{face.age}</span>
                            </div>
                            <div>
                              <span className="text-gray-400">Gender:</span>{" "}
                              <span className="text-yellow-400">{face.gender}</span>
                            </div>
                            <div>
                              <span className="text-gray-400">Emotion:</span>{" "}
                              <span className="text-yellow-400">{face.emotion}</span>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Poses */}
                {detections.poses?.length > 0 && (
                  <div>
                    <h4 className="text-sm font-bold mb-2 text-yellow-400">🤸 Poses</h4>
                    <div className="space-y-2">
                      {detections.poses.map((pose: any) => (
                        <div key={pose.id} className="bg-gray-800 rounded-lg p-3 border border-gray-700">
                          <div className="grid grid-cols-2 gap-2 text-xs">
                            <div>
                              <span className="text-gray-400">Confidence:</span>{" "}
                              <span className="text-green-400">{(pose.confidence * 100).toFixed(1)}%</span>
                            </div>
                            <div>
                              <span className="text-gray-400">Posture:</span>{" "}
                              <span className="text-yellow-400">{pose.posture}</span>
                            </div>
                            <div>
                              <span className="text-gray-400">Keypoints:</span>{" "}
                              <span className="text-yellow-400">{pose.keypoints}</span>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Objects */}
                {detections.objects?.length > 0 && (
                  <div>
                    <h4 className="text-sm font-bold mb-2 text-yellow-400">🔍 Objects</h4>
                    <div className="space-y-2">
                      {detections.objects.map((obj: any) => (
                        <div
                          key={obj.id}
                          className="bg-gray-800 rounded-lg p-3 border border-gray-700 flex justify-between items-center"
                        >
                          <div>
                            <div className="font-semibold text-sm capitalize">{obj.class}</div>
                            <div className="text-xs text-gray-400">
                              Confidence: {(obj.confidence * 100).toFixed(1)}%
                            </div>
                          </div>
                          <div className="w-24 bg-gray-700 rounded-full h-2">
                            <div
                              className="bg-gradient-to-r from-yellow-500 to-amber-500 h-2 rounded-full"
                              style={{ width: `${obj.confidence * 100}%` }}
                            />
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Footer */}
      <div className="max-w-7xl mx-auto mt-6 text-center text-xs text-gray-500">
        𓃠 Bastet Demo Interface • Powered by InsightFace & MMDetection • Demo Mode
      </div>
    </div>
  );
}
