"use client";

import React, { useState } from "react";
import { Icon } from "@iconify/react";

const HowToUse: React.FC = () => {
  const [activeSection, setActiveSection] = useState("getting-started");

  const sections = [
    {
      id: "getting-started",
      title: "Getting Started",
      icon: "mdi:rocket-launch",
      content: [
        {
          title: "1. Choose Your Subscription",
          description: "Select a plan that fits your needs. Start with Free tier to try local training.",
        },
        {
          title: "2. Create Your First Project",
          description: "Projects help organize your models and genes. Go to Dashboard and click 'New Project'.",
        },
        {
          title: "3. Select a Base Model",
          description: "Choose from our library of pre-trained models like Phi-3, Llama 2, or custom models.",
        },
        {
          title: "4. Add Genes",
          description: "Select genes to customize your model's behavior. Check VRAM requirements.",
        },
      ],
    },
    {
      id: "training",
      title: "Training Models",
      icon: "mdi:brain",
      content: [
        {
          title: "Upload Dataset",
          description: "Prepare your training data in JSONL or CSV format. Upload to MongoDB storage.",
        },
        {
          title: "Configure Training",
          description: "Set hyperparameters: epochs, batch size, learning rate, and LoRA configuration.",
        },
        {
          title: "Allocate GPU",
          description: "Select GPU resources. Free tier uses local GPU, paid tiers use cloud GPUs.",
        },
        {
          title: "Monitor Progress",
          description: "Track training metrics in real-time: loss, accuracy, and progress percentage.",
        },
      ],
    },
    {
      id: "genes",
      title: "Working with Genes",
      icon: "mdi:dna",
      content: [
        {
          title: "What are Genes?",
          description: "Modular parameter sets that define specific behaviors or capabilities.",
        },
        {
          title: "Creating Genes",
          description: "Define parameters, VRAM impact, and configuration for reusable model features.",
        },
        {
          title: "Mixing Genes",
          description: "Combine multiple genes to create unique model behaviors without full retraining.",
        },
        {
          title: "VRAM Calculation",
          description: "Total VRAM = Base Model + Sum of all Gene VRAM impacts.",
        },
      ],
    },
    {
      id: "marketplace",
      title: "Model Marketplace",
      icon: "mdi:store",
      content: [
        {
          title: "Sharing Models",
          description: "Publish your trained models to the community. Free tier requires sharing.",
        },
        {
          title: "Downloading Models",
          description: "Browse and download models from other users. Rate and review models.",
        },
        {
          title: "Versioning",
          description: "Keep track of model versions and updates. Download specific versions.",
        },
        {
          title: "Privacy",
          description: "Set model visibility: Private, Shared (specific users), or Public.",
        },
      ],
    },
    {
      id: "gpu-sharing",
      title: "GPU Sharing (Free Tier)",
      icon: "mdi:gpu",
      content: [
        {
          title: "Install Desktop App",
          description: "Download and install the GPU sharing client on your machine.",
        },
        {
          title: "Automatic Sharing",
          description: "Your GPU is shared when idle. You retain priority when you need it.",
        },
        {
          title: "Earn Credits",
          description: "Contribution hours earn credits toward paid tier upgrades.",
        },
        {
          title: "Monitor Contribution",
          description: "Track your GPU sharing stats and earned credits in the dashboard.",
        },
      ],
    },
  ];

  const currentSection = sections.find((s) => s.id === activeSection);

  return (
    <div className="min-h-screen bg-gradient-to-b from-black via-gray-900 to-black p-8">
      <div className="max-w-7xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold font-orbitron mb-2">How to Use RICE AI</h1>
          <p className="text-gray-400">Complete guide to training and deploying AI models</p>
        </div>

        <div className="grid md:grid-cols-4 gap-6">
          {/* Sidebar Navigation */}
          <div className="md:col-span-1">
            <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-xl p-4 border border-gray-700 sticky top-8">
              <h3 className="text-sm font-semibold text-gray-400 mb-3">SECTIONS</h3>
              <nav className="space-y-1">
                {sections.map((section) => (
                  <button
                    key={section.id}
                    onClick={() => setActiveSection(section.id)}
                    className={`w-full flex items-center gap-3 px-3 py-2 rounded-lg transition-all ${
                      activeSection === section.id
                        ? "bg-blue-600 text-white"
                        : "text-gray-400 hover:bg-gray-700 hover:text-white"
                    }`}
                  >
                    <Icon icon={section.icon} className="text-lg" />
                    <span className="text-sm font-medium">{section.title}</span>
                  </button>
                ))}
              </nav>
            </div>
          </div>

          {/* Content Area */}
          <div className="md:col-span-3">
            <div className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-xl p-8 border border-gray-700">
              <div className="flex items-center gap-3 mb-6">
                <div className="w-12 h-12 rounded-xl bg-blue-600 flex items-center justify-center">
                  <Icon icon={currentSection?.icon || "mdi:help"} className="text-2xl" />
                </div>
                <h2 className="text-3xl font-bold font-orbitron">{currentSection?.title}</h2>
              </div>

              <div className="space-y-6">
                {currentSection?.content.map((item, idx) => (
                  <div
                    key={idx}
                    className="bg-gray-800/50 rounded-lg p-6 border border-gray-700"
                  >
                    <h4 className="text-lg font-semibold mb-2 flex items-center gap-2">
                      <span className="flex-shrink-0 w-6 h-6 rounded-full bg-blue-600 flex items-center justify-center text-sm">
                        {idx + 1}
                      </span>
                      {item.title}
                    </h4>
                    <p className="text-gray-400 ml-8">{item.description}</p>
                  </div>
                ))}
              </div>

              {/* Quick Links */}
              <div className="mt-8 pt-8 border-t border-gray-700">
                <h3 className="text-lg font-semibold mb-4">Quick Links</h3>
                <div className="grid grid-cols-2 gap-4">
                  <Link
                    href="/admin/dashboard"
                    className="flex items-center gap-2 px-4 py-3 bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
                  >
                    <Icon icon="mdi:view-dashboard" />
                    <span>Go to Dashboard</span>
                  </Link>
                  <Link
                    href="/admin/genes"
                    className="flex items-center gap-2 px-4 py-3 bg-purple-600 rounded-lg hover:bg-purple-700 transition-colors"
                  >
                    <Icon icon="mdi:dna" />
                    <span>Gene Library</span>
                  </Link>
                  <Link
                    href="/contact"
                    className="flex items-center gap-2 px-4 py-3 bg-gray-700 rounded-lg hover:bg-gray-600 transition-colors"
                  >
                    <Icon icon="mdi:help-circle" />
                    <span>Get Help</span>
                  </Link>
                  <Link
                    href="/prices"
                    className="flex items-center gap-2 px-4 py-3 bg-gray-700 rounded-lg hover:bg-gray-600 transition-colors"
                  >
                    <Icon icon="mdi:currency-usd" />
                    <span>View Pricing</span>
                  </Link>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default HowToUse;

