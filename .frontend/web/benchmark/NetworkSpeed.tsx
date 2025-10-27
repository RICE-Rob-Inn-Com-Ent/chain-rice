'use client';
import React, { useState } from 'react';

export default function NetworkSpeed() {
  const [isRunning, setIsRunning] = useState(false);
  const [results, setResults] = useState<any>(null);

  const runTest = async () => {
    setIsRunning(true);
    try {
      const startTime = performance.now();

      // Test download speed with a small image
      const response = await fetch('https://picsum.photos/1024/768?random=' + Date.now());
      const blob = await response.blob();
      const endTime = performance.now();

      const duration = (endTime - startTime) / 1000; // seconds
      const sizeBytes = blob.size;
      const sizeMB = sizeBytes / (1024 * 1024);
      const speedMbps = (sizeMB * 8) / duration; // Megabits per second

      setResults({
        downloadSpeed: speedMbps.toFixed(2),
        latency: duration.toFixed(2),
        size: sizeMB.toFixed(2),
        timestamp: new Date().toLocaleTimeString(),
      });
    } catch (error) {
      console.error('Network test failed:', error);
      setResults({ error: 'Test failed' });
    } finally {
      setIsRunning(false);
    }
  };

  return (
    <div className="space-y-4">
      <button
        onClick={runTest}
        disabled={isRunning}
        className="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 disabled:from-gray-700 disabled:to-gray-800 text-white py-3 rounded-lg font-bold transition-all disabled:cursor-not-allowed"
      >
        {isRunning ? '⏳ Testing...' : '🚀 Run Speed Test'}
      </button>

      {results && !results.error && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
            <div className="text-xs text-gray-400 mb-1">Download Speed</div>
            <div className="text-2xl font-bold text-green-400">{results.downloadSpeed} Mbps</div>
          </div>
          <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
            <div className="text-xs text-gray-400 mb-1">Latency</div>
            <div className="text-2xl font-bold text-cyan-400">{results.latency}s</div>
          </div>
          <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
            <div className="text-xs text-gray-400 mb-1">Test Size</div>
            <div className="text-2xl font-bold text-blue-400">{results.size} MB</div>
          </div>
          <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
            <div className="text-xs text-gray-400 mb-1">Timestamp</div>
            <div className="text-sm font-semibold text-gray-300">{results.timestamp}</div>
          </div>
        </div>
      )}

      {results?.error && (
        <div className="bg-red-900/20 border border-red-500/30 rounded-lg p-4 text-red-400">{results.error}</div>
      )}
    </div>
  );
}
