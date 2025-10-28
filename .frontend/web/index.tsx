import React, { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import { createRoot } from "react-dom/client";
import "./index.css";
import schemaData from "./schema.json";

interface ModelStatus {
  [key: string]: boolean;
}

const aiModels = [
  {
    id: "thoth",
    name: "Thoth",
    subtitle: "Bóg Mądrości i Tekstu",
    icon: "📚",
    gradient: "from-blue-900 to-indigo-900",
    description: "NLP Stack • Przetwarzanie tekstu i dokumentów",
    features: ["Text Generation (Mistral 7B)", "OCR (PaddleOCR)", "Translation (Opus-MT)", "Document Analysis (Donut)"],
    tech: "Mistral 7B Q4 • PaddleOCR • Opus-MT",
    port: 8001,
  },
  {
    id: "ra",
    name: "Ra",
    subtitle: "Bóg Światła i Kreacji",
    icon: "☀️",
    gradient: "from-amber-900 to-orange-900",
    description: "Image & Video Generation • Kreacja wizualna",
    features: ["Image Generation (SD 2.1)", "Image Editing", "Upscaling (RealESRGAN)", "Style Transfer"],
    tech: "SD 2.1 FP16 • RealESRGAN • RVM",
    port: 8002,
  },
  {
    id: "isis",
    name: "Isis",
    subtitle: "Bogini Uzdrawiania i Audio",
    icon: "✨",
    gradient: "from-purple-900 to-pink-900",
    description: "Medical & Audio AI • Diagnostyka i synteza głosu",
    features: ["Medical Imaging (MONAI)", "Speech Synthesis (XTTS)", "Voice Cloning", "Music Generation"],
    tech: "MONAI • XTTS • MusicGen",
    port: 8003,
  },
  {
    id: "bastet",
    name: "Bastet",
    subtitle: "Bogini Wzroku",
    icon: "🐱",
    gradient: "from-yellow-900 to-amber-900",
    description: "Computer Vision • Analiza obrazu w czasie rzeczywistym",
    features: [
      "Face Recognition (InsightFace)",
      "Pose Estimation (MMPose)",
      "Object Detection (MMDetection)",
      "Visual QA (LLaVa 7B)",
    ],
    tech: "InsightFace • MMDetection • LLaVa 7B",
    port: 8004,
  },
  {
    id: "maat",
    name: "Maat",
    subtitle: "Bogini Sprawiedliwości",
    icon: "⚖️",
    gradient: "from-cyan-900 to-blue-900",
    description: "Legal & Analytics AI • Analiza prawna i danych",
    features: ["Legal Analysis", "Sentiment Analysis", "Text Summarization", "Data Visualization"],
    tech: "Mistral 7B Q4 • XLM-RoBERTa",
    port: 8005,
  },
  {
    id: "khnum",
    name: "Khnum",
    subtitle: "Bóg Tworzenia 3D",
    icon: "🏺",
    gradient: "from-emerald-900 to-teal-900",
    description: "3D & Game AI • Modelowanie i rekomendacje",
    features: [
      "3D Modeling (Tripo SR)",
      "System Recommendations (RecBole)",
      "Code Generation (StarCoder 7B)",
      "Game AI",
    ],
    tech: "Tripo SR • RecBole • StarCoder 7B",
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
        } catch {
          // Model is offline or unreachable
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
        <div className="flex items-center justify-center gap-3 mb-6">
          {isChecking ? (
            <div className="bg-gray-800/50 px-4 py-2 rounded-full border border-gray-600/50">
              <span className="text-gray-400 text-sm">Sprawdzam status modeli...</span>
            </div>
          ) : (
            <div className="flex gap-3">
              <div className="bg-green-600/20 px-4 py-2 rounded-full border border-green-500/30">
                <span className="text-green-400 text-sm font-semibold">
                  {Object.values(modelStatus).filter(Boolean).length} Online
                </span>
              </div>
              <div className="bg-red-600/20 px-4 py-2 rounded-full border border-red-500/30">
                <span className="text-red-400 text-sm font-semibold">
                  {Object.values(modelStatus).filter((s) => !s).length} Offline
                </span>
              </div>
            </div>
          )}
        </div>
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
                  {(() => {
                    if (isChecking) {
                      return (
                        <div className="bg-gray-600/20 text-gray-400 text-xs px-3 py-1 rounded-full border border-gray-500/30 animate-pulse">
                          Sprawdzam...
                        </div>
                      );
                    }
                    if (modelStatus[model.id]) {
                      return (
                        <div className="bg-green-600/20 text-green-400 text-xs px-3 py-1 rounded-full border border-green-500/30 flex items-center gap-1">
                          <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse" />
                          <span>Online</span>
                        </div>
                      );
                    }
                    return (
                      <div className="bg-red-600/20 text-red-400 text-xs px-3 py-1 rounded-full border border-red-500/30">
                        Offline
                      </div>
                    );
                  })()}
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
                  
                  <div className="flex gap-2">
                    {/* Wake/Sleep Button */}
                    {modelStatus[model.id] === "checking" ? (
                      <button
                        disabled
                        className="flex-1 bg-gray-700 text-gray-500 py-2 px-3 rounded-lg text-sm font-semibold cursor-not-allowed"
                      >
                        ⏳ Checking...
                      </button>
                    ) : modelStatus[model.id] === "online" ? (
                      <>
                        <button
                          onClick={() => handleSleepModel(model.id)}
                          className="bg-orange-600 hover:bg-orange-700 text-white py-2 px-3 rounded-lg text-sm font-semibold transition flex items-center gap-1"
                        >
                          💤 Sleep
                        </button>
                        <a
                          href={`/demo/${model.id}.html`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex-1 bg-purple-600 hover:bg-purple-700 text-white text-center py-2 px-3 rounded-lg text-sm font-semibold transition"
                        >
                          Try {model.name} →
                        </a>
                      </>
                    ) : (
                      <button
                        onClick={() => handleWakeModel(model.id)}
                        className="flex-1 bg-green-600 hover:bg-green-700 text-white py-2 px-3 rounded-lg text-sm font-semibold transition"
                      >
                        ▶️ Wake Model
                      </button>
                    )}
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </section>

      {/* Pricing Section */}
      <section id="cennik" className="max-w-7xl mx-auto px-4 py-20">
        <h2 className="text-4xl font-bold text-white text-center mb-4">Cennik Usług</h2>
        <p className="text-gray-400 text-center mb-12 max-w-3xl mx-auto">
          Programujemy wszystko • Full-Stack Web Development • AI Integration • Cloud Infrastructure
        </p>

        {/* Main Service Categories */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-12">
          {/* AI Models Subscription */}
          <div className="bg-gradient-to-b from-purple-900/30 to-purple-950/30 rounded-2xl p-8 border border-purple-500/30">
            <div className="text-4xl mb-4">🤖</div>
            <h3 className="text-2xl font-bold text-white mb-3">Subskrypcja Modeli AI</h3>
            <p className="text-gray-400 text-sm mb-6">Dostęp do modeli w chmurze lub lokalnie</p>
            <div className="space-y-4 mb-6">
              <div>
                <div className="flex justify-between items-baseline mb-2">
                  <span className="text-white font-semibold">Cloud (Managed)</span>
                  <span className="text-purple-400 font-bold">od 499 zł/msc</span>
                </div>
                <p className="text-xs text-gray-500">Hosting w Polsce, API ready, auto-scaling</p>
              </div>
              <div>
                <div className="flex justify-between items-baseline mb-2">
                  <span className="text-white font-semibold">Self-Hosted</span>
                  <span className="text-purple-400 font-bold">od 199 zł/msc</span>
                </div>
                <p className="text-xs text-gray-500">Docker images, dokumentacja, updates</p>
              </div>
            </div>
            <a
              href="#kontakt"
              className="block w-full bg-purple-600 hover:bg-purple-700 text-white text-center font-semibold py-3 rounded-lg transition"
            >
              Zapytaj o ofertę
            </a>
          </div>

          {/* Development Services */}
          <div className="bg-gradient-to-b from-blue-900/30 to-blue-950/30 rounded-2xl p-8 border border-blue-500/30 relative">
            <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
              <span className="bg-blue-500 text-white text-xs px-3 py-1 rounded-full font-semibold">
                Najpopularniejsze
              </span>
            </div>
            <div className="text-4xl mb-4">💻</div>
            <h3 className="text-2xl font-bold text-white mb-3">Usługi Programistyczne</h3>
            <p className="text-gray-400 text-sm mb-6">Senior developers • Stawki godzinowe</p>
            <div className="space-y-4 mb-6">
              <div>
                <div className="flex justify-between items-baseline mb-2">
                  <span className="text-white font-semibold">Full-Stack Developer</span>
                  <span className="text-blue-400 font-bold">300-400 zł/h</span>
                </div>
                <p className="text-xs text-gray-500">React, Next.js, Node, Python, Go</p>
              </div>
              <div>
                <div className="flex justify-between items-baseline mb-2">
                  <span className="text-white font-semibold">AI/ML Engineer</span>
                  <span className="text-blue-400 font-bold">350-450 zł/h</span>
                </div>
                <p className="text-xs text-gray-500">Model training, fine-tuning, deployment</p>
              </div>
              <div>
                <div className="flex justify-between items-baseline mb-2">
                  <span className="text-white font-semibold">DevOps Engineer</span>
                  <span className="text-blue-400 font-bold">280-380 zł/h</span>
                </div>
                <p className="text-xs text-gray-500">Docker, K8s, AWS, Azure, GCP</p>
              </div>
            </div>
            <a
              href="#kontakt"
              className="block w-full bg-blue-600 hover:bg-blue-700 text-white text-center font-semibold py-3 rounded-lg transition"
            >
              Zamów konsultację
            </a>
          </div>

          {/* Integration & Support */}
          <div className="bg-gradient-to-b from-amber-900/30 to-amber-950/30 rounded-2xl p-8 border border-amber-500/30">
            <div className="text-4xl mb-4">🔧</div>
            <h3 className="text-2xl font-bold text-white mb-3">Integracja & Wsparcie</h3>
            <p className="text-gray-400 text-sm mb-6">Kompleksowa integracja z Twoim systemem</p>
            <div className="space-y-4 mb-6">
              <div>
                <div className="flex justify-between items-baseline mb-2">
                  <span className="text-white font-semibold">Instalacja lokalna</span>
                  <span className="text-amber-400 font-bold">od 3,000 zł</span>
                </div>
                <p className="text-xs text-gray-500">Setup, konfiguracja, szkolenie zespołu</p>
              </div>
              <div>
                <div className="flex justify-between items-baseline mb-2">
                  <span className="text-white font-semibold">Integracja API</span>
                  <span className="text-amber-400 font-bold">od 5,000 zł</span>
                </div>
                <p className="text-xs text-gray-500">WhatsApp, Slack, custom webhooks</p>
              </div>
              <div>
                <div className="flex justify-between items-baseline mb-2">
                  <span className="text-white font-semibold">Custom LoRA Training</span>
                  <span className="text-amber-400 font-bold">od 8,000 zł</span>
                </div>
                <p className="text-xs text-gray-500">Fine-tuning na własnych danych</p>
              </div>
            </div>
            <a
              href="#kontakt"
              className="block w-full bg-amber-600 hover:bg-amber-700 text-white text-center font-semibold py-3 rounded-lg transition"
            >
              Wycena projektu
            </a>
          </div>
        </div>

        {/* Additional Services */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-12">
          {/* Cloud & Infrastructure */}
          <div className="bg-white/5 backdrop-blur-sm rounded-xl p-6 border border-white/10">
            <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <span className="text-2xl">☁️</span>
              <span>Cloud & Infrastruktura</span>
            </h3>
            <div className="space-y-3 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-300">Dockerizacja projektu</span>
                <span className="text-purple-400 font-semibold">od 2,500 zł</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-300">Setup AWS/Azure/GCP</span>
                <span className="text-purple-400 font-semibold">od 4,000 zł</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-300">CI/CD Pipeline</span>
                <span className="text-purple-400 font-semibold">od 3,500 zł</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-300">Kubernetes deployment</span>
                <span className="text-purple-400 font-semibold">od 6,000 zł</span>
              </div>
            </div>
          </div>

          {/* Security & Optimization */}
          <div className="bg-white/5 backdrop-blur-sm rounded-xl p-6 border border-white/10">
            <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <span className="text-2xl">🔒</span>
              <span>Security & Optymalizacja</span>
            </h3>
            <div className="space-y-3 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-300">Security audit</span>
                <span className="text-purple-400 font-semibold">od 5,000 zł</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-300">Optymalizacja SEO</span>
                <span className="text-purple-400 font-semibold">od 3,000 zł</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-300">Performance optimization</span>
                <span className="text-purple-400 font-semibold">od 4,000 zł</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-300">RODO compliance</span>
                <span className="text-purple-400 font-semibold">od 3,500 zł</span>
              </div>
            </div>
          </div>
        </div>

        {/* System Requirements */}
        <div className="bg-gradient-to-r from-gray-900 to-black rounded-2xl p-8 border border-gray-700 mb-12">
          <h3 className="text-2xl font-bold text-white mb-6 text-center">💻 Wymagania Systemowe (Self-Hosted)</h3>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div>
              <h4 className="text-lg font-semibold text-purple-400 mb-3">Minimum (7B models)</h4>
              <ul className="space-y-2 text-sm text-gray-300">
                <li>• GPU: 6GB VRAM (GTX 1660, RTX 3050)</li>
                <li>• RAM: 16GB</li>
                <li>• CPU: 4 cores</li>
                <li>• Storage: 50GB SSD</li>
                <li>• OS: Ubuntu 22.04 / Docker</li>
              </ul>
            </div>
            <div>
              <h4 className="text-lg font-semibold text-blue-400 mb-3">Recommended (13B models)</h4>
              <ul className="space-y-2 text-sm text-gray-300">
                <li>• GPU: 12GB VRAM (RTX 3060, RTX 4060)</li>
                <li>• RAM: 32GB</li>
                <li>• CPU: 8 cores</li>
                <li>• Storage: 100GB NVMe SSD</li>
                <li>• OS: Ubuntu 22.04 / Docker</li>
              </ul>
            </div>
            <div>
              <h4 className="text-lg font-semibold text-amber-400 mb-3">Production (All models)</h4>
              <ul className="space-y-2 text-sm text-gray-300">
                <li>• GPU: 24GB VRAM (RTX 3090, RTX 4090)</li>
                <li>• RAM: 64GB</li>
                <li>• CPU: 16 cores</li>
                <li>• Storage: 500GB NVMe SSD</li>
                <li>• OS: Ubuntu 22.04 / K8s</li>
              </ul>
            </div>
          </div>
        </div>

        {/* Tech Stack */}
        <div className="bg-gradient-to-r from-purple-900/20 to-blue-900/20 rounded-2xl p-8 border border-purple-500/30">
          <h3 className="text-2xl font-bold text-white mb-6 text-center">🛠️ Nasz Stack Technologiczny</h3>
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-6 gap-4">
            {/* Frontend */}
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:react" width="40" height="40" />
              <div className="text-xs font-semibold text-white">React</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:nextjs-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Next.js</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:vue" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Vue.js</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:svelte-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Svelte</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:tailwindcss-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Tailwind</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:typescript-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">TypeScript</div>
            </div>

            {/* Backend */}
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:nodejs-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Node.js</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:python" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Python</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:go" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Go</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:rust" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Rust</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:fastapi" width="40" height="40" />
              <div className="text-xs font-semibold text-white">FastAPI</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:nestjs" width="40" height="40" />
              <div className="text-xs font-semibold text-white">NestJS</div>
            </div>

            {/* AI/ML */}
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:pytorch-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">PyTorch</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:tensorflow" width="40" height="40" />
              <div className="text-xs font-semibold text-white">TensorFlow</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="simple-icons:ollama" width="40" height="40" className="text-white" />
              <div className="text-xs font-semibold text-white">Ollama</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="simple-icons:openai" width="40" height="40" className="text-white" />
              <div className="text-xs font-semibold text-white">OpenAI</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="simple-icons:huggingface" width="40" height="40" className="text-yellow-500" />
              <div className="text-xs font-semibold text-white">HuggingFace</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:langchain-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">LangChain</div>
            </div>

            {/* Cloud */}
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:aws" width="40" height="40" />
              <div className="text-xs font-semibold text-white">AWS</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:microsoft-azure" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Azure</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:google-cloud" width="40" height="40" />
              <div className="text-xs font-semibold text-white">GCP</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:docker-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Docker</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:kubernetes" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Kubernetes</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:terraform-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Terraform</div>
            </div>

            {/* Databases */}
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:postgresql" width="40" height="40" />
              <div className="text-xs font-semibold text-white">PostgreSQL</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:mongodb-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">MongoDB</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:redis" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Redis</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:elasticsearch" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Elastic</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:mysql" width="40" height="40" />
              <div className="text-xs font-semibold text-white">MySQL</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:sqlite" width="40" height="40" />
              <div className="text-xs font-semibold text-white">SQLite</div>
            </div>

            {/* Blockchain */}
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:ethereum" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Ethereum</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:solidity" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Solidity</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:web3js" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Web3.js</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="simple-icons:hardhat" width="40" height="40" className="text-yellow-500" />
              <div className="text-xs font-semibold text-white">Hardhat</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="simple-icons:ipfs" width="40" height="40" className="text-cyan-400" />
              <div className="text-xs font-semibold text-white">IPFS</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="simple-icons:chainlink" width="40" height="40" className="text-blue-500" />
              <div className="text-xs font-semibold text-white">Chainlink</div>
            </div>

            {/* Mobile */}
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:flutter" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Flutter</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:react" width="40" height="40" />
              <div className="text-xs font-semibold text-white">React Native</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:swift" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Swift</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:kotlin-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Kotlin</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:android-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Android</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:apple" width="40" height="40" />
              <div className="text-xs font-semibold text-white">iOS</div>
            </div>

            {/* DevOps & Tools */}
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:git-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Git</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:github-icon" width="40" height="40" />
              <div className="text-xs font-semibold text-white">GitHub</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:gitlab" width="40" height="40" />
              <div className="text-xs font-semibold text-white">GitLab</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:nginx" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Nginx</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:grafana" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Grafana</div>
            </div>
            <div className="bg-white/5 rounded-lg p-4 border border-white/10 flex flex-col items-center gap-2">
              <Icon icon="logos:prometheus" width="40" height="40" />
              <div className="text-xs font-semibold text-white">Prometheus</div>
            </div>
          </div>
        </div>

        {/* Important Notes */}
        <div className="mt-12 bg-yellow-900/20 border border-yellow-500/30 rounded-xl p-6">
          <h4 className="text-lg font-bold text-yellow-400 mb-3 flex items-center gap-2">
            <span className="text-2xl">⚠️</span>
            <span>Ważne informacje</span>
          </h4>
          <ul className="space-y-2 text-sm text-gray-300">
            <li>• Ceny podane są orientacyjne - każdy projekt wyceniamy indywidualnie po analizie wymagań</li>
            <li>• Integracje z systemami zewnętrznymi (WhatsApp, AWS, Azure) wyceniane oddzielnie</li>
            <li>• Legacy systems mogą wymagać dodatkowych prac modernizacyjnych</li>
            <li>• Hosting modeli w chmurze - koszty infrastruktury doliczane do faktury</li>
            <li>• Training custom LoRA - wymaga dostarczenia datasetu (min. 1000 przykładów)</li>
            <li>• Wsparcie 24/7 dostępne w pakietach Enterprise (wycena indywidualna)</li>
          </ul>
        </div>
      </section>

      {/* CTA Section */}
      <section id="uslugi" className="max-w-7xl mx-auto px-4 py-20">
        <div className="bg-gradient-to-r from-purple-900/30 to-pink-900/30 rounded-3xl p-12 border border-purple-500/30 text-center">
          <h2 className="text-4xl font-bold text-white mb-6">Gotowy na moc AI?</h2>
          <p className="text-xl text-gray-300 mb-8 max-w-2xl mx-auto">
            Rozpocznij za darmo lub wybierz plan Premium za 999 zł/miesiąc
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
