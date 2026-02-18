"use client";

import React, { useState } from "react";
import { Icon } from "@iconify/react";

const Genes: React.FC = () => {
  const [genes] = useState([
    {
      id: "1",
      name: "Polish Language Expert",
      description: "Specialized in Polish language understanding and generation",
      vramImpact: 512,
      parameters: { language: "pl", dialect: "standard" },
      createdAt: "2025-10-01",
    },
    {
      id: "2",
      name: "Customer Service",
      description: "Trained on customer support conversations and best practices",
      vramImpact: 256,
      parameters: { tone: "professional", empathy: "high" },
      createdAt: "2025-10-05",
    },
    {
      id: "3",
      name: "E-commerce Optimizer",
      description: "Product recommendations and market analysis",
      vramImpact: 384,
      parameters: { domain: "retail", analysis: "market-trends" },
      createdAt: "2025-10-10",
    },
    {
      id: "4",
      name: "Image Classification",
      description: "Computer vision for plant disease detection",
      vramImpact: 768,
      parameters: { classes: "50", backbone: "resnet50" },
      createdAt: "2025-10-15",
    },
  ]);

  const [showCreateModal, setShowCreateModal] = useState(false);

  return (
    <div className="min-h-screen bg-gradient-to-b from-black via-gray-900 to-black p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div>
            <h1 className="text-4xl font-bold font-orbitron mb-2">Gene Library</h1>
            <p className="text-gray-400">Modular parameter sets for your AI models</p>
          </div>
          <button
            onClick={() => setShowCreateModal(true)}
            className="px-6 py-3 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg font-semibold hover:from-blue-700 hover:to-purple-700 transition-all inline-flex items-center gap-2"
          >
            <Icon icon="mdi:plus" className="text-xl" />
            Create Gene
          </button>
        </div>

        {/* Info Card */}
        <div className="bg-gradient-to-r from-blue-900/20 to-purple-900/20 rounded-xl p-6 border border-gray-700 mb-8">
          <div className="flex items-start gap-4">
            <Icon icon="mdi:information-outline" className="text-3xl text-blue-400 flex-shrink-0" />
            <div>
              <h3 className="text-lg font-semibold mb-2">What are Genes?</h3>
              <p className="text-gray-300 mb-2">
                Genes are modular parameter sets that define specific behaviors or capabilities for your AI models.
                You can mix and match genes to create unique model configurations without training from scratch.
              </p>
              <p className="text-sm text-gray-400">
                Each gene has a VRAM impact - the total VRAM required for your model is calculated based on the base model plus all selected genes.
              </p>
            </div>
          </div>
        </div>

        {/* Genes Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {genes.map((gene) => (
            <div
              key={gene.id}
              className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-xl p-6 border border-gray-700 hover:border-purple-500 transition-all hover:transform hover:scale-105"
            >
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center gap-2">
                  <div className="w-10 h-10 rounded-lg bg-purple-600 flex items-center justify-center">
                    <Icon icon="mdi:dna" className="text-xl" />
                  </div>
                  <div>
                    <h3 className="font-semibold">{gene.name}</h3>
                    <div className="flex items-center gap-1 text-xs text-gray-400">
                      <Icon icon="mdi:memory" />
                      <span>{gene.vramImpact} MB</span>
                    </div>
                  </div>
                </div>
                <button className="text-gray-400 hover:text-white transition-colors">
                  <Icon icon="mdi:dots-vertical" className="text-xl" />
                </button>
              </div>

              <p className="text-sm text-gray-400 mb-4">{gene.description}</p>

              <div className="space-y-2">
                <div className="text-xs text-gray-500">Parameters:</div>
                <div className="flex flex-wrap gap-2">
                  {Object.entries(gene.parameters).map(([key, value]) => (
                    <span key={key} className="px-2 py-1 bg-gray-700 rounded text-xs">
                      <span className="text-gray-400">{key}:</span>{" "}
                      <span className="text-white">{value}</span>
                    </span>
                  ))}
                </div>
              </div>

              <div className="mt-4 pt-4 border-t border-gray-700 flex items-center justify-between text-xs text-gray-400">
                <div className="flex items-center gap-1">
                  <Icon icon="mdi:calendar" />
                  <span>{gene.createdAt}</span>
                </div>
                <button className="px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors">
                  Use Gene
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* Create Gene Modal (Placeholder) */}
        {showCreateModal && (
          <div className="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-xl p-8 border border-gray-700 max-w-lg w-full mx-4">
              <div className="flex items-center justify-between mb-6">
                <h3 className="text-2xl font-bold font-orbitron">Create New Gene</h3>
                <button
                  onClick={() => setShowCreateModal(false)}
                  className="text-gray-400 hover:text-white transition-colors"
                >
                  <Icon icon="mdi:close" className="text-2xl" />
                </button>
              </div>

              <form className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">Gene Name</label>
                  <input
                    type="text"
                    className="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-blue-500"
                    placeholder="e.g., Polish Language Expert"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">Description</label>
                  <textarea
                    rows={3}
                    className="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-blue-500 resize-none"
                    placeholder="Describe what this gene does..."
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-300 mb-2">VRAM Impact (MB)</label>
                  <input
                    type="number"
                    className="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white focus:outline-none focus:border-blue-500"
                    placeholder="256"
                  />
                </div>

                <div className="flex gap-3 pt-4">
                  <button
                    type="button"
                    onClick={() => setShowCreateModal(false)}
                    className="flex-1 px-4 py-3 bg-gray-700 rounded-lg font-semibold hover:bg-gray-600 transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className="flex-1 px-4 py-3 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg font-semibold hover:from-blue-700 hover:to-purple-700 transition-all"
                  >
                    Create Gene
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default Genes;

