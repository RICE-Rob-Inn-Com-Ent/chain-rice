import React from "react";
import { Icon } from "@iconify/react";

export const About: React.FC = () => {
  return (
    <div className="py-12">
      {/* Hero */}
      <div className="max-w-7xl mx-auto px-6 mb-16 text-center">
        <div className="inline-block text-6xl mb-6">🧬</div>
        <h1 className="text-5xl md:text-6xl font-bold text-white mb-4">About GiPT-1</h1>
        <p className="text-xl text-gray-300 max-w-3xl mx-auto">
          The world's first unified multimodal AI combining 6 specialized models into one revolutionary platform.
        </p>
      </div>

      {/* Mission */}
      <div className="max-w-6xl mx-auto px-6 mb-16">
        <div className="bg-gradient-to-r from-purple-900/20 to-pink-900/20 border border-purple-500/30 rounded-2xl p-12">
          <h2 className="text-3xl font-bold text-white mb-4 text-center">Our Mission</h2>
          <p className="text-gray-300 text-lg text-center leading-relaxed">
            We believe AI should be <span className="text-purple-400 font-semibold">accessible</span>, <span className="text-pink-400 font-semibold">powerful</span>, and <span className="text-blue-400 font-semibold">specialized</span>. 
            GiPT-1 brings together the best of text, vision, code, audio, and image generation in a single, easy-to-use platform.
          </p>
        </div>
      </div>

      {/* The Technology */}
      <div className="max-w-7xl mx-auto px-6 mb-16">
        <h2 className="text-4xl font-bold text-white text-center mb-12">The Technology Behind GiPT-1</h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-8">
            <Icon icon="mdi:brain" width={48} className="text-purple-400 mb-4" />
            <h3 className="text-2xl font-bold text-white mb-3">LoRA Fusion</h3>
            <p className="text-gray-300 leading-relaxed">
              Using Low-Rank Adaptation, we combine multiple specialized models without sacrificing performance. 
              Each "god" contributes its expertise while maintaining a compact, efficient architecture.
            </p>
          </div>

          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-8">
            <Icon icon="mdi:memory" width={48} className="text-blue-400 mb-4" />
            <h3 className="text-2xl font-bold text-white mb-3">6GB VRAM Optimized</h3>
            <p className="text-gray-300 leading-relaxed">
              Runs on consumer hardware! With FP16 precision, attention slicing, and lazy loading, 
              GiPT-1 delivers enterprise-grade AI on a single RTX 3060 GPU.
            </p>
          </div>

          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-8">
            <Icon icon="mdi:server-network" width={48} className="text-green-400 mb-4" />
            <h3 className="text-2xl font-bold text-white mb-3">Multi-Backend Architecture</h3>
            <p className="text-gray-300 leading-relaxed">
              Ollama for LLMs, FastAPI for Stable Diffusion. Each component uses the best runtime for its task, 
              orchestrated through a unified API layer.
            </p>
          </div>

          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-8">
            <Icon icon="mdi:open-source-initiative" width={48} className="text-orange-400 mb-4" />
            <h3 className="text-2xl font-bold text-white mb-3">Open Source Foundation</h3>
            <p className="text-gray-300 leading-relaxed">
              Built on open-source models: Mistral, Llama, Stable Diffusion. Our UI kit is published to npm 
              and available for free under MIT license.
            </p>
          </div>
        </div>
      </div>

      {/* Team */}
      <div className="max-w-6xl mx-auto px-6 mb-16">
        <h2 className="text-4xl font-bold text-white text-center mb-12">Built by Code-Rice</h2>
        
        <div className="bg-white/5 backdrop-blur-lg rounded-2xl border border-white/10 p-12 text-center">
          <div className="text-6xl mb-6">👨‍💻</div>
          <p className="text-gray-300 text-lg leading-relaxed max-w-3xl mx-auto">
            Code-Rice is a software development agency specializing in AI integration and full-stack development. 
            We created GiPT-1 to democratize access to powerful multimodal AI, making it available to everyone 
            from solo developers to enterprise teams.
          </p>
          <div className="flex justify-center gap-4 mt-8">
            <a
              href="https://github.com/rice-mono"
              target="_blank"
              rel="noopener noreferrer"
              className="px-6 py-3 bg-white/10 hover:bg-white/20 text-white font-semibold rounded-lg transition flex items-center gap-2"
            >
              <Icon icon="mdi:github" width={20} />
              GitHub
            </a>
            <a
              href="https://npmjs.com/package/@rice-mono/ui-kit"
              target="_blank"
              rel="noopener noreferrer"
              className="px-6 py-3 bg-white/10 hover:bg-white/20 text-white font-semibold rounded-lg transition flex items-center gap-2"
            >
              <Icon icon="mdi:npm" width={20} />
              NPM Package
            </a>
          </div>
        </div>
      </div>

      {/* Values */}
      <div className="max-w-7xl mx-auto px-6">
        <h2 className="text-4xl font-bold text-white text-center mb-12">Our Values</h2>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="text-center">
            <div className="w-16 h-16 bg-purple-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
              <Icon icon="mdi:shield-check" width={32} className="text-purple-400" />
            </div>
            <h3 className="text-xl font-bold text-white mb-2">Privacy First</h3>
            <p className="text-gray-400 text-sm">
              Your data stays yours. On-premise options available for sensitive workloads.
            </p>
          </div>

          <div className="text-center">
            <div className="w-16 h-16 bg-blue-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
              <Icon icon="mdi:lightning-bolt" width={32} className="text-blue-400" />
            </div>
            <h3 className="text-xl font-bold text-white mb-2">Performance</h3>
            <p className="text-gray-400 text-sm">
              Optimized for speed. Responses in seconds, not minutes.
            </p>
          </div>

          <div className="text-center">
            <div className="w-16 h-16 bg-pink-500/20 rounded-full flex items-center justify-center mx-auto mb-4">
              <Icon icon="mdi:heart-multiple" width={32} className="text-pink-400" />
            </div>
            <h3 className="text-xl font-bold text-white mb-2">Open Source</h3>
            <p className="text-gray-400 text-sm">
              Built on open foundations. UI kit free on npm, models transparent.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

