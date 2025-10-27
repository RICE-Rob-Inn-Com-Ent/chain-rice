import React from 'react';
import NetworkSpeed from '../../benchmark/NetworkSpeed';
import SystemPerf from '../../benchmark/SystemPerf';
import ModelLatency from '../../benchmark/ModelLatency';

export default function BenchmarksView() {
  return (
    <div className="mx-auto max-w-7xl px-4 space-y-8">
      {/* Hero */}
      <div className="text-center mb-12">
        <h2 className="text-4xl font-bold mb-4 bg-gradient-to-r from-green-400 via-cyan-500 to-blue-600 bg-clip-text text-transparent">
          Performance Benchmarks
        </h2>
        <p className="text-gray-400 max-w-2xl mx-auto">
          Real-time performance monitoring: network speed, system resources, and AI model latency
        </p>
      </div>

      {/* Network Speed */}
      <section className="bg-gray-900/50 rounded-2xl p-6 border border-gray-700">
        <h3 className="text-xl font-bold mb-4 text-green-400">🌐 Network Speed Test</h3>
        <NetworkSpeed />
      </section>

      {/* System Performance */}
      <section className="bg-gray-900/50 rounded-2xl p-6 border border-gray-700">
        <h3 className="text-xl font-bold mb-4 text-cyan-400">💻 System Performance</h3>
        <SystemPerf />
      </section>

      {/* Model Latency */}
      <section className="bg-gray-900/50 rounded-2xl p-6 border border-gray-700">
        <h3 className="text-xl font-bold mb-4 text-purple-400">🤖 AI Model Latency</h3>
        <ModelLatency />
      </section>
    </div>
  );
}
