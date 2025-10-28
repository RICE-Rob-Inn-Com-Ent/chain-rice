'use client';
import React, { useState } from 'react';

const MODELS = [
  { id: 'thoth', name: 'Thoth (Mistral 7B)', endpoint: '/api/gods/thoth', port: 8001 },
  { id: 'maat', name: 'Maat (Mistral 13B)', endpoint: '/api/gods/maat', port: 8005 },
  { id: 'khnum', name: 'Khnum (PlotGPT)', endpoint: '/api/gods/khnum', port: 8006 },
  { id: 'ra', name: 'Ra (FLUX.1)', endpoint: '/api/gods/ra', port: 8002 },
  { id: 'isis', name: 'Isis (Monai)', endpoint: '/api/gods/isis', port: 8003 },
  { id: 'bastet', name: 'Bastet (InsightFace)', endpoint: '/api/gods/bastet', port: 8004 },
];

export default function ModelLatency() {
  const [results, setResults] = useState<Record<string, any>>({});
  const [isTesting, setIsTesting] = useState(false);

  const testModel = async (modelId: string, endpoint: string) => {
    const startTime = performance.now();

    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt: 'Hello', max_tokens: 10 }),
        signal: AbortSignal.timeout(30000),
      });

      const endTime = performance.now();
      const latency = endTime - startTime;

      if (response.ok) {
        return { status: 'online', latency: latency.toFixed(0), unit: 'ms' };
      } else {
        return { status: 'error', latency: '-', error: response.statusText };
      }
    } catch (error: any) {
      const endTime = performance.now();
      return {
        status: 'offline',
        latency: '-',
        error: error.message.includes('aborted') ? 'Timeout' : 'Offline',
      };
    }
  };

  const runAllTests = async () => {
    setIsTesting(true);
    setResults({});

    for (const model of MODELS) {
      const result = await testModel(model.id, model.endpoint);
      setResults((prev) => ({ ...prev, [model.id]: result }));
    }

    setIsTesting(false);
  };

  return (
    <div className="space-y-4">
      <button
        onClick={runAllTests}
        disabled={isTesting}
        className="w-full bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 disabled:from-gray-700 disabled:to-gray-800 text-white py-3 rounded-lg font-bold transition-all disabled:cursor-not-allowed"
      >
        {isTesting ? '⏳ Testing All Models...' : '🔬 Test All Models'}
      </button>

      <div className="grid gap-3">
        {MODELS.map((model) => {
          const result = results[model.id];
          const statusColor =
            result?.status === 'online'
              ? 'text-green-400'
              : result?.status === 'error'
                ? 'text-yellow-400'
                : result?.status === 'offline'
                  ? 'text-red-400'
                  : 'text-gray-400';

          return (
            <div
              key={model.id}
              className="bg-gray-800 rounded-lg p-4 border border-gray-700 flex justify-between items-center"
            >
              <div>
                <div className="font-semibold">{model.name}</div>
                <div className="text-xs text-gray-400">Port {model.port}</div>
              </div>
              <div className="text-right">
                {result ? (
                  <>
                    <div className={`text-xl font-bold ${statusColor}`}>
                      {result.latency} {result.latency !== '-' && 'ms'}
                    </div>
                    <div className="text-xs text-gray-400 capitalize">{result.status}</div>
                  </>
                ) : (
                  <div className="text-sm text-gray-500">-</div>
                )}
              </div>
            </div>
          );
        })}
      </div>

      {Object.keys(results).length > 0 && (
        <div className="text-xs text-gray-500 text-center">ℹ️ Lower latency = faster response time</div>
      )}
    </div>
  );
}
