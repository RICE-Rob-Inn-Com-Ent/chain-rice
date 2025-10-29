import React from "react";
import { Link } from "react-router-dom";
import { Icon } from "@iconify/react";

export const Home: React.FC = () => {
  return (
    <div>
      {/* Hero Section */}
      <section className="relative overflow-hidden">
        {/* Background gradient */}
        <div className="absolute inset-0 bg-gradient-to-br from-purple-900/20 via-transparent to-pink-900/20" />
        
        <div className="relative max-w-7xl mx-auto px-6 py-20 md:py-32">
          <div className="text-center max-w-4xl mx-auto">
            {/* Badge */}
            <div className="inline-flex items-center gap-2 bg-purple-500/20 border border-purple-500/30 rounded-full px-4 py-2 mb-6">
              <span className="w-2 h-2 bg-purple-500 rounded-full animate-pulse" />
              <span className="text-purple-300 text-sm font-semibold">Introducing GiPT-1 v1.0</span>
            </div>

            {/* Main Heading */}
            <h1 className="text-5xl md:text-7xl font-bold text-white mb-6">
              <span className="text-transparent bg-clip-text bg-gradient-to-r from-purple-400 via-pink-400 to-purple-400 animate-gradient">
                One Model
              </span>
              <br />
              <span>Six Superpowers</span>
            </h1>

            <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
              GiPT-1 combines text generation, vision, code, audio, and image creation into a single unified AI model. The power of 6 specialized models in one.
            </p>

            {/* CTA Buttons */}
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link
                to="/demo"
                className="px-8 py-4 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-bold rounded-lg transition text-lg shadow-xl shadow-purple-500/30"
              >
                Try Live Demo →
              </Link>
              <Link
                to="/pricing"
                className="px-8 py-4 bg-white/10 hover:bg-white/20 backdrop-blur text-white font-semibold rounded-lg transition text-lg border border-white/20"
              >
                View Pricing
              </Link>
            </div>

            {/* Stats */}
            <div className="grid grid-cols-3 gap-6 mt-16 max-w-2xl mx-auto">
              <div className="text-center">
                <div className="text-4xl font-bold text-purple-400 mb-1">6</div>
                <div className="text-sm text-gray-400">AI Models</div>
              </div>
              <div className="text-center">
                <div className="text-4xl font-bold text-pink-400 mb-1">1</div>
                <div className="text-sm text-gray-400">Unified Interface</div>
              </div>
              <div className="text-center">
                <div className="text-4xl font-bold text-purple-400 mb-1">∞</div>
                <div className="text-sm text-gray-400">Possibilities</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20 bg-black/20">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-4xl font-bold text-white mb-4">The 6 Gods of AI</h2>
            <p className="text-gray-400 text-lg">Each god specializes in a unique domain, united in GiPT-1</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {[
              {
                icon: "📚",
                name: "Thoth",
                title: "God of Wisdom",
                desc: "Text generation, NLP, translation, document analysis",
                color: "from-blue-900 to-indigo-900",
              },
              {
                icon: "☀️",
                name: "Ra",
                title: "God of Light",
                desc: "Image generation, editing, upscaling with Stable Diffusion",
                color: "from-amber-900 to-orange-900",
              },
              {
                icon: "✨",
                name: "Isis",
                title: "Goddess of Healing",
                desc: "Medical AI, speech synthesis, voice cloning, music gen",
                color: "from-purple-900 to-pink-900",
              },
              {
                icon: "🐱",
                name: "Bastet",
                title: "Goddess of Vision",
                desc: "Computer vision, face recognition, object detection, visual QA",
                color: "from-yellow-900 to-amber-900",
              },
              {
                icon: "⚖️",
                name: "Maat",
                title: "Goddess of Justice",
                desc: "Legal analysis, sentiment analysis, data visualization",
                color: "from-cyan-900 to-blue-900",
              },
              {
                icon: "🏺",
                name: "Khnum",
                title: "God of Creation",
                desc: "3D modeling, code generation, game AI, recommendations",
                color: "from-emerald-900 to-teal-900",
              },
            ].map((god) => (
              <div
                key={god.name}
                className={`bg-gradient-to-br ${god.color} rounded-xl border border-white/20 p-6 hover:scale-105 transition-transform`}
              >
                <div className="text-5xl mb-3">{god.icon}</div>
                <h3 className="text-xl font-bold text-white mb-1">{god.name}</h3>
                <p className="text-gray-300 text-sm mb-2">{god.title}</p>
                <p className="text-gray-400 text-sm">{god.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Tech Stack Section */}
      <section className="py-20">
        <div className="max-w-7xl mx-auto px-6">
          <div className="text-center mb-12">
            <h2 className="text-4xl font-bold text-white mb-4">Powered by Best-in-Class AI</h2>
            <p className="text-gray-400 text-lg">Built on proven, production-ready technologies</p>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
            {[
              { name: "Mistral 7B", desc: "Text LLM" },
              { name: "Stable Diffusion 2.1", desc: "Image Gen" },
              { name: "LLaVA 7B", desc: "Vision" },
              { name: "CodeLlama 7B", desc: "Code" },
              { name: "Llama2 7B", desc: "Audio" },
              { name: "RealESRGAN", desc: "Upscaling" },
              { name: "Ollama", desc: "Runtime" },
              { name: "LoRA", desc: "Fusion" },
            ].map((tech) => (
              <div
                key={tech.name}
                className="bg-white/5 backdrop-blur-lg rounded-lg border border-white/10 p-4 text-center hover:border-purple-500/30 transition"
              >
                <div className="font-semibold text-white mb-1">{tech.name}</div>
                <div className="text-xs text-gray-400">{tech.desc}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 bg-gradient-to-r from-purple-900/30 to-pink-900/30">
        <div className="max-w-4xl mx-auto px-6 text-center">
          <h2 className="text-4xl md:text-5xl font-bold text-white mb-6">
            Ready to Experience GiPT-1?
          </h2>
          <p className="text-xl text-gray-300 mb-8">
            Start using the most advanced multimodal AI platform today
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              to="/demo"
              className="px-8 py-4 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white font-bold rounded-lg transition text-lg"
            >
              Try Free Demo
            </Link>
            <Link
              to="/contact"
              className="px-8 py-4 bg-white/10 hover:bg-white/20 backdrop-blur text-white font-semibold rounded-lg transition text-lg border border-white/20"
            >
              Contact Sales
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
};

