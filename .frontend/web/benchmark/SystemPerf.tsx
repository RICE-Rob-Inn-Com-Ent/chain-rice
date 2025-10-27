'use client';
import React, { useState, useEffect } from 'react';

export default function SystemPerf() {
  const [metrics, setMetrics] = useState<any>(null);

  useEffect(() => {
    const updateMetrics = () => {
      const memory = (performance as any).memory;

      setMetrics({
        memoryUsed: memory ? (memory.usedJSHeapSize / 1024 / 1024).toFixed(2) : 'N/A',
        memoryTotal: memory ? (memory.totalJSHeapSize / 1024 / 1024).toFixed(2) : 'N/A',
        memoryLimit: memory ? (memory.jsHeapSizeLimit / 1024 / 1024).toFixed(2) : 'N/A',
        cores: navigator.hardwareConcurrency || 'N/A',
        connection: (navigator as any).connection?.effectiveType || 'unknown',
        deviceMemory: (navigator as any).deviceMemory || 'N/A',
        platform: navigator.platform,
      });
    };

    updateMetrics();
    const interval = setInterval(updateMetrics, 2000);

    return () => clearInterval(interval);
  }, []);

  if (!metrics) return <div className="text-gray-400">Loading...</div>;

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
      <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
        <div className="text-xs text-gray-400 mb-1">Memory Used</div>
        <div className="text-2xl font-bold text-cyan-400">{metrics.memoryUsed} MB</div>
      </div>
      <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
        <div className="text-xs text-gray-400 mb-1">Memory Limit</div>
        <div className="text-2xl font-bold text-blue-400">{metrics.memoryLimit} MB</div>
      </div>
      <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
        <div className="text-xs text-gray-400 mb-1">CPU Cores</div>
        <div className="text-2xl font-bold text-purple-400">{metrics.cores}</div>
      </div>
      <div className="bg-gray-800 rounded-lg p-4 border border-gray-700">
        <div className="text-xs text-gray-400 mb-1">Connection</div>
        <div className="text-lg font-bold text-green-400 uppercase">{metrics.connection}</div>
      </div>
      <div className="bg-gray-800 rounded-lg p-4 border border-gray-700 md:col-span-2">
        <div className="text-xs text-gray-400 mb-1">Platform</div>
        <div className="text-lg font-semibold text-gray-300">{metrics.platform}</div>
      </div>
      <div className="bg-gray-800 rounded-lg p-4 border border-gray-700 md:col-span-2">
        <div className="text-xs text-gray-400 mb-1">Device Memory</div>
        <div className="text-2xl font-bold text-amber-400">{metrics.deviceMemory} GB</div>
      </div>
    </div>
  );
}
