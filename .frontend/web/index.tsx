import React, { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import schemaData from "./schema.json";

interface ModelStatus {
  [key: string]: boolean;
}

const aiModels = [
  {
    id: "ra",
    name: "Ra",
    subtitle: "Bóg Światła i Kreacji",
    icon: "☀️",
    gradient: "from-amber-900 to-orange-900",
    description: "Stable Diffusion 2.1 • Generowanie obrazów AI",
    features: ["Image Generation", "4x Upscaling", "Background Removal"],
    tech: "SD 2.1 FP16 • 6GB VRAM",
    port: 8001,
  },
  {
    id: "bastet",
    name: "Bastet",
    subtitle: "Bogini Wzroku",
    icon: "🐱",
    gradient: "from-yellow-900 to-amber-900",
    description: "Computer Vision • Analiza obrazu w czasie rzeczywistym",
    features: ["Face Recognition", "Pose Estimation", "Object Detection"],
    tech: "InsightFace • MMDetection",
    port: 8002,
  },
  {
    id: "thoth",
    name: "Thoth",
    subtitle: "Bóg Mądrości",
    icon: "📚",
    gradient: "from-blue-900 to-indigo-900",
    description: "NLP • Przetwarzanie języka naturalnego",
    features: ["Text Generation", "Q&A", "Summarization"],
    tech: "Llama 3.1 70B • RAG",
    port: 8003,
  },
  {
    id: "isis",
    name: "Isis",
    subtitle: "Bogini Magii",
    icon: "✨",
    gradient: "from-purple-900 to-pink-900",
    description: "Audio Processing • Synteza i analiza dźwięku",
    features: ["Speech-to-Text", "Text-to-Speech", "Audio Enhancement"],
    tech: "Whisper • Bark • RVC",
    port: 8004,
  },
  {
    id: "khnum",
    name: "Khnum",
    subtitle: "Bóg Kształtowania",
    icon: "🏺",
    gradient: "from-emerald-900 to-teal-900",
    description: "3D Modeling • Generowanie modeli 3D",
    features: ["Text-to-3D", "Image-to-3D", "3D Enhancement"],
    tech: "Zero123 • TripoSR",
    port: 8005,
  },
  {
    id: "maat",
    name: "Maat",
    subtitle: "Bogini Prawdy",
    icon: "⚖️",
    gradient: "from-cyan-900 to-blue-900",
    description: "AI Moderation • Analiza treści i moderacja",
    features: ["Content Moderation", "Fact Checking", "Bias Detection"],
    tech: "CLIP • BERT • Custom",
    port: 8006,
  },
];

function App() {
  const [modelStatus, setModelStatus] = useState<ModelStatus>({});
  const [isChecking, setIsChecking] = useState(true);

  useEffect(() => {
    // Add JSON-LD schema to head
    const script = document.createElement("script");
    script.type = "application/ld+json";
    script.text = JSON.stringify(schemaData);
    document.head.appendChild(script);

    return () => {
      // Cleanup on unmount
      script.remove();
    };
  }, []);

  // Check model status
  useEffect(() => {
    const checkModels = async () => {
      setIsChecking(true);
      const status: ModelStatus = {};

      for (const model of aiModels) {
        try {
          // Try to fetch health endpoint with timeout
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), 2000);

          const response = await fetch(`http://localhost:${model.port}/health`, {
            signal: controller.signal,
            method: "GET",
          });

          clearTimeout(timeoutId);
          status[model.id] = response.ok;
        } catch (error) {
          status[model.id] = false;
        }
      }

      setModelStatus(status);
      setIsChecking(false);
    };

    checkModels();

    // Refresh status every 30 seconds
    const interval = setInterval(checkModels, 30000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      {/* Header */}
      <header className="bg-black/30 backdrop-blur-md border-b border-white/10 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <span className="text-3xl">🌾</span>
            <span className="text-2xl font-bold text-white">RICE</span>
          </div>
          <nav className="hidden md:flex items-center gap-6">
            <a href="#modele" className="text-gray-300 hover:text-white transition">
              Modele AI
            </a>
            <a href="#uslugi" className="text-gray-300 hover:text-white transition">
              Usługi
            </a>
            <a
              href="#cennik"
              className="bg-purple-600 hover:bg-purple-700 text-white px-6 py-2 rounded-lg font-semibold transition"
            >
              Cennik
            </a>
            <a href="#kontakt" className="text-gray-300 hover:text-white transition">
              Kontakt
            </a>
          </nav>
          <button className="md:hidden text-white text-2xl">☰</button>
        </div>
      </header>

      {/* Hero Section */}
      <section className="max-w-7xl mx-auto px-4 py-20 text-center">
        <h1 className="text-6xl md:text-7xl font-bold text-white mb-6 leading-tight">GiPT-1</h1>
        <h2 className="text-2xl md:text-3xl font-semibold text-purple-300 mb-6">
          6 Potężnych Modeli AI dla Twojego Biznesu
        </h2>
        <p className="text-xl text-gray-300 leading-relaxed max-w-3xl mx-auto mb-12">
          Od generowania obrazów po analizę 3D - kompletny zestaw narzędzi AI zoptymalizowanych dla wydajności
        </p>
        <div className="flex flex-wrap gap-4 justify-center">
          <a
            href="#modele"
            className="bg-purple-600 hover:bg-purple-700 text-white font-bold py-4 px-10 rounded-lg transition text-lg shadow-lg hover:shadow-purple-500/50"
          >
            Poznaj Modele
          </a>
          <a
            href="#cennik"
            className="bg-white/10 hover:bg-white/20 text-white font-bold py-4 px-10 rounded-lg backdrop-blur-sm transition text-lg border border-white/20"
          >
            Zobacz Cennik
          </a>
        </div>
      </section>

      {/* AI Models Section */}
      <section id="modele" className="max-w-7xl mx-auto px-4 py-16">
        <h2 className="text-4xl font-bold text-white text-center mb-4">Nasze Modele AI</h2>
        <p className="text-gray-400 text-center mb-12 max-w-2xl mx-auto">
          Każdy model jest zoptymalizowany pod kątem wydajności i działa na GPU z 6-8GB VRAM
        </p>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {aiModels.map((model) => (
            <div
              key={model.id}
              className="group relative bg-gradient-to-br from-gray-900 to-black rounded-2xl overflow-hidden border border-white/10 hover:border-purple-500/50 transition-all duration-300 hover:scale-105 hover:shadow-2xl hover:shadow-purple-500/20"
            >
              {/* Gradient Overlay */}
              <div
                className={`absolute inset-0 bg-gradient-to-br ${model.gradient} opacity-20 group-hover:opacity-30 transition-opacity`}
              ></div>

              {/* Content */}
              <div className="relative p-6">
                <div className="flex items-start justify-between mb-4">
                  <div className="text-6xl">{model.icon}</div>
                  <div className="bg-purple-600/20 text-purple-300 text-xs px-3 py-1 rounded-full border border-purple-500/30">
                    Live
                  </div>
                </div>

                <h3 className="text-2xl font-bold text-white mb-1">{model.name}</h3>
                <p className="text-sm text-gray-400 mb-4">{model.subtitle}</p>

                <p className="text-gray-300 mb-4 text-sm leading-relaxed">{model.description}</p>

                <div className="space-y-2 mb-4">
                  {model.features.map((feature) => (
                    <div key={feature} className="flex items-center gap-2 text-xs text-gray-400">
                      <span className="text-purple-400">✓</span>
                      <span>{feature}</span>
                    </div>
                  ))}
                </div>

                <div className="pt-4 border-t border-white/10">
                  <p className="text-xs text-gray-500 mb-3">{model.tech}</p>
                  <button className="w-full bg-purple-600 hover:bg-purple-700 text-white font-semibold py-2 px-4 rounded-lg transition">
                    Wypróbuj {model.name}
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* CTA Section */}
      <section id="uslugi" className="max-w-7xl mx-auto px-4 py-20">
        <div className="bg-gradient-to-r from-purple-900/30 to-pink-900/30 rounded-3xl p-12 border border-purple-500/30 text-center">
          <h2 className="text-4xl font-bold text-white mb-6">Gotowy na moc AI?</h2>
          <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
            Rozpocznij od 99 zł/miesiąc i uzyskaj dostęp do wszystkich 6 modeli AI
          </p>
          <div className="flex flex-wrap gap-4 justify-center">
            <a
              href="#cennik"
              className="bg-white text-purple-900 hover:bg-gray-100 font-bold py-4 px-10 rounded-lg transition text-lg"
            >
              Zobacz Cennik
            </a>
            <a
              href="#kontakt"
              className="bg-purple-600 hover:bg-purple-700 text-white font-bold py-4 px-10 rounded-lg transition text-lg"
            >
              Kontakt
            </a>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-black/50 border-t border-white/10 py-8 mt-20">
        <div className="max-w-7xl mx-auto px-4 text-center text-gray-500 text-sm">
          <p>© 2024 Code-Rice. Wszystkie prawa zastrzeżone.</p>
          <p className="mt-2">🌾 Powered by Egyptian AI Gods</p>
        </div>
      </footer>
    </div>
  );
}

export default App;

const root = document.getElementById("root");
if (!root) throw new Error("Root element not found");

createRoot(root).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
