"use client";

import React, { useState } from "react";
import Link from "next/link";
import { Icon } from "@iconify/react";

const Dashboard: React.FC = () => {
  const [subscription] = useState({
    tier: "PLUS",
    usage: {
      models: 5,
      maxModels: 20,
      storage: 45,
      maxStorage: 200,
      gpuHours: 23,
      maxGpuHours: 100,
    },
  });

  const [trainedModels] = useState([
    {
      id: "1",
      name: "Customer Support Bot",
      type: "LLM",
      genes: ["Polish Language", "Customer Service"],
      rating: 4.5,
      downloads: 234,
      createdAt: "2025-10-15",
    },
    {
      id: "2",
      name: "E-commerce Analyzer",
      type: "LLM",
      genes: ["Market Analysis", "Product Recommendations"],
      rating: 4.8,
      downloads: 567,
      createdAt: "2025-10-20",
    },
    {
      id: "3",
      name: "Plant Disease Detector",
      type: "VISION",
      genes: ["Image Classification", "IoT Integration"],
      rating: 4.3,
      downloads: 189,
      createdAt: "2025-10-28",
    },
  ]);

  const [recentActivity] = useState([
    { type: "training", message: "Completed training: Customer Support Bot", time: "2 hours ago" },
    { type: "download", message: "Model downloaded by user123", time: "5 hours ago" },
    { type: "benchmark", message: "Benchmark completed: 95% accuracy", time: "1 day ago" },
  ]);

  return (
    <div className="min-h-screen bg-gradient-to-b from-black via-gray-900 to-black p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold font-orbitron mb-2">User Dashboard</h1>
          <p className="text-gray-400">Manage your AI models and subscription</p>
        </div>

        {/* Subscription Overview */}
        <div className="grid md:grid-cols-3 gap-6 mb-8">
          <div className="bg-gradient-to-br from-blue-900/40 to-blue-800/20 rounded-xl p-6 border border-blue-700">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold">Subscription</h3>
              <Icon icon="mdi:crown" className="text-3xl text-blue-400" />
            </div>
            <div className="text-3xl font-bold text-blue-400 mb-1">{subscription.tier}</div>
            <p className="text-sm text-gray-400">Active subscription</p>
            <Link
              href="/admin/subscription"
              className="mt-4 inline-block text-sm text-blue-400 hover:text-blue-300 transition-colors"
            >
              Manage subscription →
            </Link>
          </div>

          <div className="bg-gradient-to-br from-purple-900/40 to-purple-800/20 rounded-xl p-6 border border-purple-700">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold">Models</h3>
              <Icon icon="mdi:brain" className="text-3xl text-purple-400" />
            </div>
            <div className="text-3xl font-bold text-purple-400 mb-1">
              {subscription.usage.models}/{subscription.usage.maxModels}
            </div>
            <p className="text-sm text-gray-400">Trained models</p>
            <div className="mt-4 w-full bg-gray-700 rounded-full h-2">
              <div
                className="bg-purple-500 h-2 rounded-full"
                style={{ width: `${(subscription.usage.models / subscription.usage.maxModels) * 100}%` }}
              ></div>
            </div>
          </div>

          <div className="bg-gradient-to-br from-pink-900/40 to-pink-800/20 rounded-xl p-6 border border-pink-700">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-lg font-semibold">GPU Hours</h3>
              <Icon icon="mdi:gpu" className="text-3xl text-pink-400" />
            </div>
            <div className="text-3xl font-bold text-pink-400 mb-1">
              {subscription.usage.gpuHours}/{subscription.usage.maxGpuHours}
            </div>
            <p className="text-sm text-gray-400">This month</p>
            <div className="mt-4 w-full bg-gray-700 rounded-full h-2">
              <div
                className="bg-pink-500 h-2 rounded-full"
                style={{ width: `${(subscription.usage.gpuHours / subscription.usage.maxGpuHours) * 100}%` }}
              ></div>
            </div>
          </div>
        </div>

        {/* Trained Models */}
        <div className="mb-8">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-2xl font-bold font-orbitron">Your Trained Models</h2>
            <Link
              href="/admin/new-model"
              className="px-4 py-2 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg font-semibold hover:from-blue-700 hover:to-purple-700 transition-all inline-flex items-center gap-2"
            >
              <Icon icon="mdi:plus" />
              New Model
            </Link>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
            {trainedModels.map((model) => (
              <div
                key={model.id}
                className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-xl p-6 border border-gray-700 hover:border-blue-500 transition-all hover:transform hover:scale-105"
              >
                <div className="flex items-start justify-between mb-4">
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold mb-1">{model.name}</h3>
                    <span className="inline-block px-2 py-1 bg-blue-600 text-xs rounded">{model.type}</span>
                  </div>
                  <button className="text-gray-400 hover:text-white transition-colors">
                    <Icon icon="mdi:dots-vertical" className="text-xl" />
                  </button>
                </div>

                <div className="space-y-2 mb-4">
                  <div className="text-sm">
                    <span className="text-gray-400">Genes:</span>
                    <div className="flex flex-wrap gap-1 mt-1">
                      {model.genes.map((gene, idx) => (
                        <span key={idx} className="px-2 py-0.5 bg-purple-900/40 text-purple-300 text-xs rounded">
                          {gene}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>

                <div className="flex items-center justify-between text-sm text-gray-400">
                  <div className="flex items-center gap-1">
                    <Icon icon="mdi:star" className="text-yellow-400" />
                    <span>{model.rating}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Icon icon="mdi:download" />
                    <span>{model.downloads}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Icon icon="mdi:calendar" />
                    <span>{model.createdAt}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Activity */}
        <div>
          <h2 className="text-2xl font-bold font-orbitron mb-4">Recent Activity</h2>
          <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-xl border border-gray-700">
            {recentActivity.map((activity, idx) => (
              <div
                key={idx}
                className={`p-4 flex items-center gap-4 ${
                  idx !== recentActivity.length - 1 ? "border-b border-gray-700" : ""
                }`}
              >
                <div className="flex-shrink-0">
                  <div className="w-10 h-10 rounded-full bg-blue-600 flex items-center justify-center">
                    <Icon
                      icon={
                        activity.type === "training"
                          ? "mdi:brain"
                          : activity.type === "download"
                          ? "mdi:download"
                          : "mdi:chart-line"
                      }
                      className="text-xl"
                    />
                  </div>
                </div>
                <div className="flex-1">
                  <p className="text-white">{activity.message}</p>
                  <p className="text-sm text-gray-400">{activity.time}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;

