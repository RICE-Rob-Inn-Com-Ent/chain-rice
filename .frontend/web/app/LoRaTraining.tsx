import React, { useState } from "react";
import { Icon } from "@iconify/react";

interface ModelOption {
  id: string;
  name: string;
  god: string;
  ollamaName: string;
  size: string;
}

const availableModels: ModelOption[] = [
  { id: "mistral-7b", name: "Mistral 7B", god: "Thoth", ollamaName: "mistral:7b-instruct", size: "4.4GB" },
  { id: "llava-7b", name: "LLaVa 7B", god: "Bastet", ollamaName: "llava:7b", size: "4.7GB" },
  { id: "codellama-7b", name: "CodeLlama 7B", god: "Khnum", ollamaName: "codellama:7b", size: "3.8GB" },
  { id: "llama2-7b", name: "Llama 2 7B", god: "Isis", ollamaName: "llama2:7b", size: "3.8GB" },
];

interface TrainingStep {
  step: number;
  loss: number;
  accuracy: number;
  timestamp: string;
}

export const LoRaTraining: React.FC = () => {
  const [selectedModels, setSelectedModels] = useState<string[]>([]);
  const [containerName, setContainerName] = useState("gipt-1");
  const [epochs, setEpochs] = useState(3);
  const [learningRate, setLearningRate] = useState(0.0002);
  const [loraRank, setLoraRank] = useState(8);
  const [trainingMode, setTrainingMode] = useState<"cpu" | "gpu">("cpu");
  const [datasetFile, setDatasetFile] = useState<File | null>(null);
  const [demoConversations, setDemoConversations] = useState([
    { user: "Hello, who are you?", assistant: "I am GiPT-1, a custom AI model trained on Egyptian knowledge." },
  ]);
  const [isTraining, setIsTraining] = useState(false);
  const [trainingProgress, setTrainingProgress] = useState(0);
  const [trainingSteps, setTrainingSteps] = useState<TrainingStep[]>([]);

  const toggleModel = (modelId: string) => {
    if (selectedModels.includes(modelId)) {
      setSelectedModels(selectedModels.filter((id) => id !== modelId));
    } else {
      setSelectedModels([...selectedModels, modelId]);
    }
  };

  const addConversation = () => {
    setDemoConversations([...demoConversations, { user: "", assistant: "" }]);
  };

  const updateConversation = (index: number, field: "user" | "assistant", value: string) => {
    const updated = [...demoConversations];
    updated[index][field] = value;
    setDemoConversations(updated);
  };

  const removeConversation = (index: number) => {
    setDemoConversations(demoConversations.filter((_, i) => i !== index));
  };

  const exportDemoData = () => {
    const data = demoConversations.map((conv) => ({
      messages: [
        { role: "user", content: conv.user },
        { role: "assistant", content: conv.assistant },
      ],
    }));

    const blob = new Blob([JSON.stringify(data, null, 2)], { type: "application/json" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "training-data.json";
    a.click();
    URL.revokeObjectURL(url);
  };

  const handleStartTraining = () => {
    setIsTraining(true);
    setTrainingProgress(0);
    setTrainingSteps([]);

    // Simulate training progress
    let progress = 0;
    const interval = setInterval(() => {
      progress += Math.random() * 5;
      if (progress >= 100) {
        progress = 100;
        clearInterval(interval);
        setIsTraining(false);
      }
      setTrainingProgress(Math.min(progress, 100));

      // Add mock training step
      if (progress < 100) {
        setTrainingSteps((prev) => [
          ...prev,
          {
            step: prev.length + 1,
            loss: 2.5 - progress / 50,
            accuracy: progress / 100,
            timestamp: new Date().toLocaleTimeString(),
          },
        ]);
      }
    }, 1000);
  };

  return (
    <div className="p-8">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-4xl font-bold text-white mb-2">LoRA Training</h1>
        <p className="text-gray-300">Combine multiple models to create your custom GiPT model</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Configuration */}
        <div className="lg:col-span-2 space-y-6">
          {/* Model Selection */}
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
            <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-2">
              <Icon icon="mdi:vector-combine" width={28} />
              Select Base Models
            </h2>
            <p className="text-gray-400 text-sm mb-4">
              Choose which AI models to stack together. Selected models will be merged using LoRA adapters.
            </p>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
              {availableModels.map((model) => (
                <button
                  key={model.id}
                  onClick={() => toggleModel(model.id)}
                  className={`p-4 rounded-lg border-2 transition text-left ${
                    selectedModels.includes(model.id)
                      ? "bg-purple-500/20 border-purple-500 text-white"
                      : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
                  }`}
                >
                  <div className="flex items-start justify-between mb-2">
                    <div>
                      <div className="font-bold text-lg">{model.name}</div>
                      <div className="text-xs opacity-70">from {model.god}</div>
                    </div>
                    {selectedModels.includes(model.id) && (
                      <Icon icon="mdi:check-circle" width={24} className="text-purple-400" />
                    )}
                  </div>
                  <div className="text-xs mt-2 font-mono opacity-70">{model.ollamaName}</div>
                  <div className="text-xs mt-1 opacity-70">{model.size}</div>
                </button>
              ))}
            </div>

            {selectedModels.length > 0 && (
              <div className="mt-4 p-4 bg-purple-500/10 border border-purple-500/30 rounded-lg">
                <div className="text-sm text-purple-300">
                  <strong>{selectedModels.length}</strong> {selectedModels.length === 1 ? "model" : "models"} selected
                  for stacking
                </div>
              </div>
            )}
          </div>

          {/* Training Configuration */}
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
            <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-2">
              <Icon icon="mdi:cog" width={28} />
              Training Configuration
            </h2>

            <div className="space-y-4">
              {/* Container Name */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Container Name</label>
                <input
                  type="text"
                  value={containerName}
                  onChange={(e) => setContainerName(e.target.value)}
                  className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none"
                  placeholder="gipt-1"
                />
              </div>

              {/* Training Mode */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Training Mode</label>
                <div className="flex gap-3">
                  <button
                    onClick={() => setTrainingMode("cpu")}
                    className={`flex-1 px-4 py-3 rounded-lg border-2 transition ${
                      trainingMode === "cpu"
                        ? "bg-blue-500/20 border-blue-500 text-white"
                        : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
                    }`}
                  >
                    <Icon icon="mdi:memory" width={24} className="mx-auto mb-1" />
                    <div className="font-semibold">CPU</div>
                    <div className="text-xs opacity-70">Slower, doesn't block GPU</div>
                  </button>
                  <button
                    onClick={() => setTrainingMode("gpu")}
                    className={`flex-1 px-4 py-3 rounded-lg border-2 transition ${
                      trainingMode === "gpu"
                        ? "bg-green-500/20 border-green-500 text-white"
                        : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
                    }`}
                  >
                    <Icon icon="mdi:chip" width={24} className="mx-auto mb-1" />
                    <div className="font-semibold">GPU</div>
                    <div className="text-xs opacity-70">Faster, requires free VRAM</div>
                  </button>
                </div>
              </div>

              {/* Parameters */}
              <div className="grid grid-cols-3 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">Epochs</label>
                  <input
                    type="number"
                    value={epochs}
                    onChange={(e) => setEpochs(parseInt(e.target.value))}
                    className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none"
                    min="1"
                    max="10"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">Learning Rate</label>
                  <input
                    type="number"
                    value={learningRate}
                    onChange={(e) => setLearningRate(parseFloat(e.target.value))}
                    className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none"
                    step="0.0001"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">LoRA Rank</label>
                  <input
                    type="number"
                    value={loraRank}
                    onChange={(e) => setLoraRank(parseInt(e.target.value))}
                    className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-purple-500 focus:outline-none"
                    min="4"
                    max="64"
                  />
                </div>
              </div>

              {/* Dataset Upload */}
              <div>
                <label className="block text-sm font-medium text-gray-300 mb-2">Training Dataset</label>
                <div className="border-2 border-dashed border-white/20 rounded-lg p-6 text-center hover:border-white/40 transition cursor-pointer">
                  <input
                    type="file"
                    accept=".json,.csv"
                    onChange={(e) => setDatasetFile(e.target.files?.[0] || null)}
                    className="hidden"
                    id="dataset-upload"
                  />
                  <label htmlFor="dataset-upload" className="cursor-pointer">
                    <Icon icon="mdi:cloud-upload" width={48} className="text-gray-400 mx-auto mb-2" />
                    <div className="text-white font-medium">
                      {datasetFile ? datasetFile.name : "Click to upload dataset"}
                    </div>
                    <div className="text-sm text-gray-400 mt-1">JSON or CSV format (min. 1000 examples)</div>
                  </label>
                </div>
              </div>
            </div>
          </div>

          {/* Demo Data Preparation */}
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
            <h2 className="text-2xl font-bold text-white mb-4 flex items-center gap-2">
              <Icon icon="mdi:message-text" width={28} />
              Demo Conversations
            </h2>
            <p className="text-gray-400 text-sm mb-4">
              Create sample conversations to define how your model should respond
            </p>

            <div className="space-y-3 mb-4">
              {demoConversations.map((conv, idx) => (
                <div key={idx} className="bg-black/20 rounded-lg p-4 space-y-2">
                  <div className="flex justify-between items-center mb-2">
                    <span className="text-sm text-gray-400">Conversation {idx + 1}</span>
                    {demoConversations.length > 1 && (
                      <button
                        onClick={() => removeConversation(idx)}
                        className="text-red-400 hover:text-red-300 transition"
                      >
                        <Icon icon="mdi:close" width={20} />
                      </button>
                    )}
                  </div>
                  <input
                    type="text"
                    value={conv.user}
                    onChange={(e) => updateConversation(idx, "user", e.target.value)}
                    placeholder="User message..."
                    className="w-full px-3 py-2 bg-black/30 border border-white/10 rounded text-white text-sm focus:border-blue-500 focus:outline-none"
                  />
                  <textarea
                    value={conv.assistant}
                    onChange={(e) => updateConversation(idx, "assistant", e.target.value)}
                    placeholder="Assistant response..."
                    rows={2}
                    className="w-full px-3 py-2 bg-black/30 border border-white/10 rounded text-white text-sm focus:border-purple-500 focus:outline-none"
                  />
                </div>
              ))}
            </div>

            <div className="flex gap-2">
              <button
                onClick={addConversation}
                className="px-4 py-2 bg-blue-500/20 text-blue-400 border border-blue-500/30 rounded-lg font-semibold hover:bg-blue-500/30 transition flex items-center gap-2"
              >
                <Icon icon="mdi:plus" width={20} />
                Add Conversation
              </button>
              <button
                onClick={exportDemoData}
                className="px-4 py-2 bg-purple-500/20 text-purple-400 border border-purple-500/30 rounded-lg font-semibold hover:bg-purple-500/30 transition flex items-center gap-2"
              >
                <Icon icon="mdi:download" width={20} />
                Export as JSON
              </button>
            </div>
          </div>
        </div>

        {/* Right Column: Training Status */}
        <div className="space-y-6">
          {/* Training Control */}
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6 sticky top-8">
            <h2 className="text-xl font-bold text-white mb-4">Training Control</h2>

            {!isTraining && trainingProgress === 0 && (
              <button
                onClick={handleStartTraining}
                disabled={selectedModels.length === 0}
                className="w-full px-6 py-4 bg-gradient-to-r from-purple-600 to-pink-600 text-white rounded-lg font-bold text-lg hover:opacity-90 transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
              >
                <Icon icon="mdi:rocket-launch" width={24} />
                Start Training
              </button>
            )}

            {isTraining && (
              <div>
                <div className="flex justify-between text-sm text-gray-300 mb-2">
                  <span>Training in progress...</span>
                  <span>{Math.round(trainingProgress)}%</span>
                </div>
                <div className="w-full h-4 bg-black/30 rounded-full overflow-hidden mb-4">
                  <div
                    className="h-full bg-gradient-to-r from-purple-500 to-pink-500 transition-all duration-300"
                    style={{ width: `${trainingProgress}%` }}
                  />
                </div>
                <div className="flex items-center justify-center gap-2 text-yellow-400">
                  <Icon icon="svg-spinners:90-ring-with-bg" width={20} />
                  <span className="text-sm">Training on {trainingMode.toUpperCase()}...</span>
                </div>
              </div>
            )}

            {!isTraining && trainingProgress === 100 && (
              <div>
                <div className="bg-green-500/20 border border-green-500/30 rounded-lg p-4 mb-4 text-center">
                  <Icon icon="mdi:check-circle" width={48} className="text-green-400 mx-auto mb-2" />
                  <div className="text-green-400 font-bold">Training Complete!</div>
                </div>
                <button className="w-full px-6 py-4 bg-gradient-to-r from-blue-600 to-cyan-600 text-white rounded-lg font-bold hover:opacity-90 transition flex items-center justify-center gap-2">
                  <Icon icon="mdi:docker" width={24} />
                  Deploy to GPU
                </button>
              </div>
            )}

            {/* Training Info */}
            <div className="mt-6 space-y-2 text-sm">
              <div className="flex justify-between text-gray-400">
                <span>Selected Models:</span>
                <span className="text-white font-semibold">{selectedModels.length}</span>
              </div>
              <div className="flex justify-between text-gray-400">
                <span>Training Mode:</span>
                <span className="text-white font-semibold uppercase">{trainingMode}</span>
              </div>
              <div className="flex justify-between text-gray-400">
                <span>Epochs:</span>
                <span className="text-white font-semibold">{epochs}</span>
              </div>
              <div className="flex justify-between text-gray-400">
                <span>LoRA Rank:</span>
                <span className="text-white font-semibold">{loraRank}</span>
              </div>
            </div>
          </div>

          {/* Training Metrics */}
          {trainingSteps.length > 0 && (
            <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
              <h2 className="text-xl font-bold text-white mb-4">Training Metrics</h2>
              <div className="space-y-2 max-h-64 overflow-y-auto">
                {trainingSteps.slice(-10).reverse().map((step, idx) => (
                  <div key={idx} className="bg-black/20 rounded p-3 text-xs">
                    <div className="flex justify-between text-gray-400 mb-1">
                      <span>Step {step.step}</span>
                      <span>{step.timestamp}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-red-400">Loss: {step.loss.toFixed(4)}</span>
                      <span className="text-green-400">Acc: {(step.accuracy * 100).toFixed(2)}%</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

