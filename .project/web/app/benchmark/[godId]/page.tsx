"use client";
import { useState, useEffect } from "react";
import { useParams } from "next/navigation";

const GOD_CONFIGS: Record<string, any> = {
  thoth: {
    name: "Thoth",
    icon: "📜",
    color: "from-cyan-600 to-blue-700",
    models: ["Mistral-13B", "PaddleOCR", "Opus-MT", "XLM-RoBERTa", "Donut"],
  },
  ra: {
    name: "Ra",
    icon: "☀️",
    color: "from-amber-500 to-red-700",
    models: ["FLUX.1", "SD 2.1", "Tripo SR", "RealESRGAN", "RVM"],
  },
  isis: {
    name: "Isis",
    icon: "✨",
    color: "from-purple-600 to-rose-600",
    models: ["Monai", "Mistral-13B", "LLaVa-13B"],
  },
  bastet: {
    name: "Bastet",
    icon: "🐱",
    color: "from-yellow-600 to-orange-800",
    models: ["InsightFace", "MMPose", "MMDetection", "LLaVa-13B"],
  },
  maat: {
    name: "Maat",
    icon: "⚖️",
    color: "from-blue-600 to-purple-800",
    models: ["Mistral-13B", "XLM-RoBERTa", "Donut"],
  },
  khnum: {
    name: "Khnum",
    icon: "💰",
    color: "from-green-600 to-teal-800",
    models: ["Mistral-13B", "PlotGPT-7B", "RecBole"],
  },
};

export default function BenchmarkPage() {
  const params = useParams();
  const godId = params?.godId as string;
  const god = GOD_CONFIGS[godId];

  const [isBenchmarking, setIsBenchmarking] = useState(false);
  const [results, setResults] = useState<any>(null);
  const [progress, setProgress] = useState(0);

  const runBenchmark = async () => {
    setIsBenchmarking(true);
    setProgress(0);

    // Symulacja benchmarku
    const interval = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) {
          clearInterval(interval);
          return 100;
        }
        return prev + 10;
      });
    }, 300);

    await new Promise((resolve) => setTimeout(resolve, 3500));
    clearInterval(interval);

    // Symulowane wyniki
    setResults({
      overall: {
        score: 87.5 + Math.random() * 10,
        grade: "A",
        status: "Excellent",
      },
      performance: {
        inferenceSpeed: (45 + Math.random() * 20).toFixed(1),
        tokensPerSecond: (120 + Math.random() * 50).toFixed(0),
        latency: (85 + Math.random() * 30).toFixed(0),
        throughput: (250 + Math.random() * 100).toFixed(0),
      },
      resources: {
        cpuUsage: (35 + Math.random() * 20).toFixed(1),
        gpuUsage: (78 + Math.random() * 15).toFixed(1),
        ramUsage: (6.5 + Math.random() * 2).toFixed(1),
        vramUsage: (5.2 + Math.random() * 1.5).toFixed(1),
      },
      models: god.models.map((model: string) => ({
        name: model,
        status: Math.random() > 0.1 ? "operational" : "degraded",
        score: (75 + Math.random() * 20).toFixed(1),
        loadTime: (1.2 + Math.random() * 2).toFixed(2),
      })),
      tests: [
        { name: "Cold Start", result: (2.3 + Math.random()).toFixed(2) + "s", status: "pass" },
        { name: "Warm Inference", result: (0.8 + Math.random() * 0.5).toFixed(2) + "s", status: "pass" },
        { name: "Batch Processing", result: (5.2 + Math.random() * 2).toFixed(2) + "s", status: "pass" },
        { name: "Memory Stability", result: "98.5%", status: "pass" },
        { name: "LoRa Adapter Load", result: (0.3 + Math.random() * 0.2).toFixed(2) + "s", status: "pass" },
      ],
      timestamp: new Date().toISOString(),
    });

    setIsBenchmarking(false);
  };

  if (!god) {
    return (
      <div className="min-h-screen bg-black text-white flex items-center justify-center">
        <div className="text-center">
          <div className="text-6xl mb-4">❌</div>
          <p className="text-xl text-gray-400">God not found</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-900 via-black to-gray-900 text-white p-4">
      {/* Header */}
      <div className="max-w-6xl mx-auto mb-6">
        <div className={`bg-gradient-to-r ${god.color} bg-opacity-20 rounded-2xl p-6 border border-gray-700`}>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div className="text-6xl">{god.icon}</div>
              <div>
                <h1 className={`text-3xl font-bold bg-gradient-to-r ${god.color} bg-clip-text text-transparent`}>
                  {god.name} Benchmark
                </h1>
                <p className="text-sm text-gray-400 mt-1">Performance Testing & Analysis</p>
              </div>
            </div>
            <button
              onClick={runBenchmark}
              disabled={isBenchmarking}
              className={`bg-gradient-to-r ${god.color} hover:opacity-80 disabled:opacity-50 text-white px-6 py-3 rounded-lg font-bold transition-all disabled:cursor-not-allowed`}
            >
              {isBenchmarking ? "⏳ Running..." : "▶️ Run Benchmark"}
            </button>
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto space-y-6">
        {/* Progress */}
        {isBenchmarking && (
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
            <div className="flex justify-between mb-2">
              <span className="text-sm font-semibold">Running Benchmark Tests...</span>
              <span className="text-sm font-bold">{progress}%</span>
            </div>
            <div className="w-full bg-gray-700 rounded-full h-3">
              <div
                className={`bg-gradient-to-r ${god.color} h-3 rounded-full transition-all duration-300`}
                style={{ width: `${progress}%` }}
              />
            </div>
          </div>
        )}

        {results && (
          <>
            {/* Overall Score */}
            <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-8 text-center">
              <div className="text-sm text-gray-400 mb-2">Overall Performance Score</div>
              <div className={`text-7xl font-bold bg-gradient-to-r ${god.color} bg-clip-text text-transparent mb-2`}>
                {results.overall.score.toFixed(1)}
              </div>
              <div className="text-3xl font-bold text-green-400 mb-2">{results.overall.grade}</div>
              <div className="text-sm text-gray-500">{results.overall.status}</div>
            </div>

            {/* Performance Metrics */}
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              {[
                { label: "Inference Speed", value: results.performance.inferenceSpeed, unit: "ms", icon: "⚡" },
                { label: "Tokens/Second", value: results.performance.tokensPerSecond, unit: "t/s", icon: "📊" },
                { label: "Latency", value: results.performance.latency, unit: "ms", icon: "⏱️" },
                { label: "Throughput", value: results.performance.throughput, unit: "req/s", icon: "📈" },
              ].map((metric, idx) => (
                <div key={idx} className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-4">
                  <div className="text-3xl mb-2">{metric.icon}</div>
                  <div className="text-xs text-gray-400 mb-1">{metric.label}</div>
                  <div className="text-2xl font-bold">
                    {metric.value} <span className="text-sm text-gray-500">{metric.unit}</span>
                  </div>
                </div>
              ))}
            </div>

            {/* Resource Usage */}
            <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
              <h3 className="text-lg font-bold mb-4">Resource Utilization</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                {[
                  { label: "CPU Usage", value: results.resources.cpuUsage, icon: "🖥️" },
                  { label: "GPU Usage", value: results.resources.gpuUsage, icon: "🎮" },
                  { label: "RAM Usage", value: results.resources.ramUsage, icon: "💾", unit: "GB" },
                  { label: "VRAM Usage", value: results.resources.vramUsage, icon: "📊", unit: "GB" },
                ].map((resource, idx) => (
                  <div key={idx}>
                    <div className="flex justify-between mb-2 text-sm">
                      <span className="flex items-center gap-2">
                        <span>{resource.icon}</span>
                        <span>{resource.label}</span>
                      </span>
                      <span className="font-bold">
                        {resource.value}
                        {resource.unit || "%"}
                      </span>
                    </div>
                    <div className="w-full bg-gray-700 rounded-full h-2">
                      <div
                        className={`bg-gradient-to-r ${god.color} h-2 rounded-full`}
                        style={{ width: resource.unit ? "75%" : `${resource.value}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Model Status */}
            <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
              <h3 className="text-lg font-bold mb-4">Model Status</h3>
              <div className="space-y-3">
                {results.models.map((model: any, idx: number) => (
                  <div
                    key={idx}
                    className="bg-gray-800 rounded-lg p-4 border border-gray-700 flex justify-between items-center"
                  >
                    <div className="flex items-center gap-4">
                      <span
                        className={`w-3 h-3 rounded-full ${
                          model.status === "operational" ? "bg-green-500 animate-pulse" : "bg-yellow-500"
                        }`}
                      />
                      <div>
                        <div className="font-semibold">{model.name}</div>
                        <div className="text-xs text-gray-400">Load time: {model.loadTime}s</div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-xl font-bold">{model.score}</div>
                      <div className="text-xs text-gray-400">score</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Test Results */}
            <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
              <h3 className="text-lg font-bold mb-4">Test Results</h3>
              <div className="space-y-2">
                {results.tests.map((test: any, idx: number) => (
                  <div
                    key={idx}
                    className="bg-gray-800 rounded-lg p-3 border border-gray-700 flex justify-between items-center"
                  >
                    <span className="font-semibold text-sm">{test.name}</span>
                    <div className="flex items-center gap-3">
                      <span className="text-sm text-gray-400">{test.result}</span>
                      <span
                        className={`text-xs px-2 py-1 rounded font-semibold ${
                          test.status === "pass" ? "bg-green-600" : "bg-red-600"
                        }`}
                      >
                        {test.status.toUpperCase()}
                      </span>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Export */}
            <div className="flex gap-4">
              <button className="flex-1 bg-green-600 hover:bg-green-700 text-white py-3 rounded-lg font-bold transition-all">
                📊 Export Report
              </button>
              <button className="flex-1 bg-blue-600 hover:bg-blue-700 text-white py-3 rounded-lg font-bold transition-all">
                📈 Compare with Others
              </button>
              <button
                onClick={runBenchmark}
                className="flex-1 bg-purple-600 hover:bg-purple-700 text-white py-3 rounded-lg font-bold transition-all"
              >
                🔄 Run Again
              </button>
            </div>

            <div className="text-center text-xs text-gray-500">
              Last run: {new Date(results.timestamp).toLocaleString()}
            </div>
          </>
        )}

        {!results && !isBenchmarking && (
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-12 text-center">
            <div className="text-6xl mb-4">{god.icon}</div>
            <p className="text-xl text-gray-400 mb-2">Ready to benchmark {god.name}</p>
            <p className="text-sm text-gray-600">Click "Run Benchmark" to start performance testing</p>
          </div>
        )}
      </div>
    </div>
  );
}
