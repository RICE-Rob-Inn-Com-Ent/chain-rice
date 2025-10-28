import React from "react";
import { Icon } from "@iconify/react";

export const Prices: React.FC = () => {
  return (
    <div className="p-8">
      {/* Header */}
      <div className="mb-8 text-center">
        <h1 className="text-4xl font-bold text-white mb-2">Cennik Usług</h1>
        <p className="text-gray-300">
          Programujemy wszystko • Full-Stack Web Development • AI Integration • Cloud Infrastructure
        </p>
      </div>

      {/* Main Service Categories */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-12">
        {/* AI Models Subscription */}
        <div className="bg-gradient-to-b from-purple-900/30 to-purple-950/30 rounded-2xl p-8 border border-purple-500/30 hover:border-purple-500/50 transition">
          <div className="text-5xl mb-4">🤖</div>
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
          <button className="w-full bg-purple-600 hover:bg-purple-700 text-white font-semibold py-3 rounded-lg transition">
            Zapytaj o ofertę
          </button>
        </div>

        {/* Development Services */}
        <div className="bg-gradient-to-b from-blue-900/30 to-blue-950/30 rounded-2xl p-8 border border-blue-500/30 hover:border-blue-500/50 transition relative">
          <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
            <span className="bg-blue-500 text-white text-xs px-3 py-1 rounded-full font-semibold">
              Najpopularniejsze
            </span>
          </div>
          <div className="text-5xl mb-4">💻</div>
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
          <button className="w-full bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 rounded-lg transition">
            Zamów konsultację
          </button>
        </div>

        {/* Integration & Support */}
        <div className="bg-gradient-to-b from-amber-900/30 to-amber-950/30 rounded-2xl p-8 border border-amber-500/30 hover:border-amber-500/50 transition">
          <div className="text-5xl mb-4">🔧</div>
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
          <button className="w-full bg-amber-600 hover:bg-amber-700 text-white font-semibold py-3 rounded-lg transition">
            Wycena projektu
          </button>
        </div>
      </div>

      {/* Additional Services Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-12">
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-4 hover:border-white/20 transition">
          <Icon icon="mdi:web" width={32} className="text-cyan-400 mb-2" />
          <h4 className="text-white font-semibold mb-2">Web Development</h4>
          <p className="text-gray-400 text-sm mb-2">Landing pages, portale, dashboardy</p>
          <p className="text-cyan-400 font-bold">od 5,000 zł</p>
        </div>

        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-4 hover:border-white/20 transition">
          <Icon icon="mdi:cellphone" width={32} className="text-green-400 mb-2" />
          <h4 className="text-white font-semibold mb-2">Mobile Apps</h4>
          <p className="text-gray-400 text-sm mb-2">iOS, Android, React Native, Flutter</p>
          <p className="text-green-400 font-bold">od 15,000 zł</p>
        </div>

        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-4 hover:border-white/20 transition">
          <Icon icon="mdi:robot-outline" width={32} className="text-orange-400 mb-2" />
          <h4 className="text-white font-semibold mb-2">AI Chatbots</h4>
          <p className="text-gray-400 text-sm mb-2">WhatsApp, Messenger, custom UI</p>
          <p className="text-orange-400 font-bold">od 8,000 zł</p>
        </div>

        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-4 hover:border-white/20 transition">
          <Icon icon="mdi:server" width={32} className="text-purple-400 mb-2" />
          <h4 className="text-white font-semibold mb-2">Backend API</h4>
          <p className="text-gray-400 text-sm mb-2">REST, GraphQL, microservices</p>
          <p className="text-purple-400 font-bold">od 10,000 zł</p>
        </div>
      </div>

      {/* Package Deals */}
      <div className="mb-12">
        <h2 className="text-3xl font-bold text-white text-center mb-8">Pakiety Kompleksowe</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6 hover:border-white/20 transition">
            <div className="text-center mb-4">
              <div className="text-4xl mb-2">🚀</div>
              <h3 className="text-2xl font-bold text-white mb-2">Startup MVP</h3>
              <p className="text-gray-400 text-sm">Szybki start dla startupów</p>
            </div>
            <ul className="space-y-2 mb-6 text-sm text-gray-300">
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-green-400 mt-0.5" width={20} />
                <span>Landing page + dashboard</span>
              </li>
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-green-400 mt-0.5" width={20} />
                <span>Backend API (REST)</span>
              </li>
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-green-400 mt-0.5" width={20} />
                <span>Baza danych PostgreSQL</span>
              </li>
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-green-400 mt-0.5" width={20} />
                <span>Deployment na cloud</span>
              </li>
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-green-400 mt-0.5" width={20} />
                <span>2 miesiące wsparcia</span>
              </li>
            </ul>
            <div className="text-center">
              <div className="text-3xl font-bold text-white mb-2">35,000 zł</div>
              <p className="text-sm text-gray-400 mb-4">4-6 tygodni realizacji</p>
              <button className="w-full bg-gradient-to-r from-cyan-600 to-blue-600 hover:opacity-90 text-white font-semibold py-3 rounded-lg transition">
                Zamów pakiet
              </button>
            </div>
          </div>

          <div className="bg-gradient-to-b from-purple-900/30 to-pink-900/30 rounded-xl border-2 border-purple-500 p-6 relative">
            <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
              <span className="bg-gradient-to-r from-purple-600 to-pink-600 text-white text-xs px-3 py-1 rounded-full font-semibold">
                ⭐ REKOMENDOWANY
              </span>
            </div>
            <div className="text-center mb-4">
              <div className="text-4xl mb-2">💎</div>
              <h3 className="text-2xl font-bold text-white mb-2">Enterprise</h3>
              <p className="text-gray-400 text-sm">Kompleksowe rozwiązanie biznesowe</p>
            </div>
            <ul className="space-y-2 mb-6 text-sm text-gray-300">
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-purple-400 mt-0.5" width={20} />
                <span>Web + Mobile + Admin panel</span>
              </li>
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-purple-400 mt-0.5" width={20} />
                <span>AI Integration (wybrane modele)</span>
              </li>
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-purple-400 mt-0.5" width={20} />
                <span>Mikrousługi + API Gateway</span>
              </li>
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-purple-400 mt-0.5" width={20} />
                <span>CI/CD + monitoring</span>
              </li>
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-purple-400 mt-0.5" width={20} />
                <span>6 miesięcy wsparcia 24/7</span>
              </li>
            </ul>
            <div className="text-center">
              <div className="text-3xl font-bold text-white mb-2">120,000 zł</div>
              <p className="text-sm text-gray-400 mb-4">3-4 miesiące realizacji</p>
              <button className="w-full bg-gradient-to-r from-purple-600 to-pink-600 hover:opacity-90 text-white font-semibold py-3 rounded-lg transition">
                Zamów pakiet
              </button>
            </div>
          </div>

          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6 hover:border-white/20 transition">
            <div className="text-center mb-4">
              <div className="text-4xl mb-2">🎯</div>
              <h3 className="text-2xl font-bold text-white mb-2">Custom</h3>
              <p className="text-gray-400 text-sm">Dedykowane rozwiązanie</p>
            </div>
            <ul className="space-y-2 mb-6 text-sm text-gray-300">
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-blue-400 mt-0.5" width={20} />
                <span>Indywidualny zakres projektu</span>
              </li>
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-blue-400 mt-0.5" width={20} />
                <span>Wybór technologii</span>
              </li>
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-blue-400 mt-0.5" width={20} />
                <span>Dedykowany team</span>
              </li>
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-blue-400 mt-0.5" width={20} />
                <span>Agile methodology</span>
              </li>
              <li className="flex items-start gap-2">
                <Icon icon="mdi:check" className="text-blue-400 mt-0.5" width={20} />
                <span>Elastyczne wsparcie</span>
              </li>
            </ul>
            <div className="text-center">
              <div className="text-3xl font-bold text-white mb-2">Indywidualnie</div>
              <p className="text-sm text-gray-400 mb-4">Wycena po konsultacji</p>
              <button className="w-full bg-gradient-to-r from-blue-600 to-cyan-600 hover:opacity-90 text-white font-semibold py-3 rounded-lg transition">
                Skontaktuj się
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Important Notes */}
      <div className="bg-yellow-900/20 border border-yellow-500/30 rounded-xl p-6">
        <h3 className="text-lg font-bold text-yellow-400 mb-3 flex items-center gap-2">
          <Icon icon="mdi:information" width={24} />
          Ważne informacje
        </h3>
        <ul className="space-y-2 text-sm text-gray-300">
          <li>• Ceny podane są orientacyjne - każdy projekt wyceniamy indywidualnie po analizie wymagań</li>
          <li>• Integracje z systemami zewnętrznymi (WhatsApp, AWS, Azure) wyceniane oddzielnie</li>
          <li>• Legacy systems mogą wymagać dodatkowych prac modernizacyjnych</li>
          <li>• Hosting modeli w chmurze - koszty infrastruktury doliczane do faktury</li>
          <li>• Training custom LoRA - wymaga dostarczenia datasetu (min. 1000 przykładów)</li>
          <li>• Wsparcie 24/7 dostępne w pakietach Enterprise (wycena indywidualna)</li>
        </ul>
      </div>
    </div>
  );
};
