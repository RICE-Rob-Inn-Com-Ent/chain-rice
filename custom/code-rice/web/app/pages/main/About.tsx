"use client";

import React from "react";
import { Icon } from "@iconify/react";

const About: React.FC = () => {
  return (
    <div className="min-h-screen bg-gradient-to-b from-black via-gray-900 to-black py-20">
      <div className="container mx-auto px-6">
        {/* Hero Section */}
        <div className="max-w-4xl mx-auto text-center mb-20">
          <h1 className="text-5xl md:text-6xl font-bold font-orbitron mb-6 bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
            About RICE
          </h1>
          <p className="text-xl text-gray-300">
            Building the future of decentralized AI training and deployment
          </p>
        </div>

        {/* Mission Section */}
        <div className="max-w-5xl mx-auto mb-20">
          <div className="grid md:grid-cols-2 gap-12 items-center">
            <div>
              <h2 className="text-3xl font-bold font-orbitron mb-4">Our Mission</h2>
              <p className="text-gray-300 mb-4">
                We believe AI development should be accessible to everyone. RICE democratizes access to powerful 
                GPU resources through a decentralized network, making custom AI model training affordable and scalable.
              </p>
              <p className="text-gray-300">
                Our platform combines cutting-edge technology with community-driven GPU sharing to create 
                an ecosystem where developers, researchers, and organizations can train, fine-tune, and deploy 
                AI models without breaking the bank.
              </p>
            </div>
            <div className="bg-gradient-to-br from-gray-900 to-gray-800 p-8 rounded-xl border border-gray-700">
              <div className="space-y-6">
                <div className="flex items-start gap-4">
                  <Icon icon="mdi:target" className="text-3xl text-blue-400 flex-shrink-0" />
                  <div>
                    <h3 className="font-semibold mb-1">Accessibility</h3>
                    <p className="text-sm text-gray-400">Make AI training accessible to everyone</p>
                  </div>
                </div>
                <div className="flex items-start gap-4">
                  <Icon icon="mdi:network" className="text-3xl text-purple-400 flex-shrink-0" />
                  <div>
                    <h3 className="font-semibold mb-1">Decentralization</h3>
                    <p className="text-sm text-gray-400">Build a global network of shared compute</p>
                  </div>
                </div>
                <div className="flex items-start gap-4">
                  <Icon icon="mdi:rocket-launch" className="text-3xl text-pink-400 flex-shrink-0" />
                  <div>
                    <h3 className="font-semibold mb-1">Innovation</h3>
                    <p className="text-sm text-gray-400">Push the boundaries of AI development</p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Technology Stack */}
        <div className="mb-20">
          <h2 className="text-3xl font-bold font-orbitron mb-8 text-center">Technology Stack</h2>
          <div className="grid md:grid-cols-3 gap-6">
            {[
              {
                category: "AI & ML",
                technologies: ["Ollama", "PyTorch", "LoRA Fine-tuning", "HuggingFace", "Computer Vision", "NLP"]
              },
              {
                category: "Backend",
                technologies: ["Go + gRPC", "Python", "PostgreSQL", "MongoDB", "Redis", "Bazel"]
              },
              {
                category: "Frontend",
                technologies: ["Next.js 14", "React", "TypeScript", "Tailwind CSS", "Apollo GraphQL"]
              },
              {
                category: "Infrastructure",
                technologies: ["Docker", "Kubernetes", "Cloud GPU", "Edge Computing", "CDN"]
              },
              {
                category: "Blockchain",
                technologies: ["Smart Contracts", "Cosmos SDK", "Token Economics", "Decentralized Storage"]
              },
              {
                category: "DevOps",
                technologies: ["CI/CD", "Monitoring", "Auto-scaling", "Load Balancing", "Security"]
              }
            ].map((stack, index) => (
              <div key={index} className="bg-gradient-to-br from-gray-900 to-gray-800 p-6 rounded-xl border border-gray-700">
                <h3 className="text-lg font-semibold mb-4 text-blue-400">{stack.category}</h3>
                <div className="flex flex-wrap gap-2">
                  {stack.technologies.map((tech, i) => (
                    <span key={i} className="bg-gray-700 px-3 py-1 rounded-full text-xs">
                      {tech}
                    </span>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Features Highlight */}
        <div className="mb-20">
          <h2 className="text-3xl font-bold font-orbitron mb-8 text-center">What Makes Us Different</h2>
          <div className="grid md:grid-cols-2 gap-8">
            {[
              {
                icon: "mdi:share-variant",
                title: "GPU Sharing Network",
                description: "Free tier users contribute their idle GPU power to the network, creating a decentralized compute infrastructure that benefits everyone."
              },
              {
                icon: "mdi:dna",
                title: "Gene System",
                description: "Modular parameter sets (genes) that can be mixed and matched to create unique model behaviors without training from scratch."
              },
              {
                icon: "mdi:store",
                title: "Model Marketplace",
                description: "Share your trained models with the community or download pre-trained models. Build on each other's work."
              },
              {
                icon: "mdi:speedometer",
                title: "Real-time Monitoring",
                description: "Track training progress, benchmark performance, and optimize your models with live metrics and analytics."
              }
            ].map((feature, index) => (
              <div key={index} className="flex gap-4">
                <div className="flex-shrink-0">
                  <div className="w-12 h-12 bg-blue-600 rounded-lg flex items-center justify-center">
                    <Icon icon={feature.icon} className="text-2xl" />
                  </div>
                </div>
                <div>
                  <h3 className="text-xl font-semibold mb-2">{feature.title}</h3>
                  <p className="text-gray-400">{feature.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Stats Section */}
        <div className="bg-gradient-to-r from-blue-900/20 to-purple-900/20 rounded-xl p-12 border border-gray-700">
          <div className="grid md:grid-cols-4 gap-8 text-center">
            <div>
              <div className="text-4xl font-bold text-blue-400 mb-2">10K+</div>
              <div className="text-gray-400">Active Users</div>
            </div>
            <div>
              <div className="text-4xl font-bold text-purple-400 mb-2">50K+</div>
              <div className="text-gray-400">Models Trained</div>
            </div>
            <div>
              <div className="text-4xl font-bold text-pink-400 mb-2">5K+</div>
              <div className="text-gray-400">Shared GPUs</div>
            </div>
            <div>
              <div className="text-4xl font-bold text-green-400 mb-2">99.9%</div>
              <div className="text-gray-400">Uptime</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default About;

