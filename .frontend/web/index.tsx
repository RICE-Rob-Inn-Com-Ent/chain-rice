import React from "react";
import { createRoot } from "react-dom/client";
import "./index.css";

function App() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 flex items-center justify-center p-8">
      <div className="max-w-4xl mx-auto text-center space-y-8">
        <h1 className="text-6xl font-bold text-white mb-4">
          🌾 RICE
        </h1>
        <h2 className="text-3xl font-semibold text-purple-300 mb-6">
          AI, Web Development, Blockchain & Cloud
        </h2>
        <p className="text-xl text-gray-300 leading-relaxed">
          Nowoczesne rozwiązania technologiczne dla Twojego biznesu
        </p>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mt-12">
          <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 hover:bg-white/20 transition">
            <div className="text-4xl mb-3">🤖</div>
            <h3 className="text-xl font-bold text-white mb-2">AI & Machine Learning</h3>
            <p className="text-gray-300">Implementacja modeli AI i automatyzacja procesów</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 hover:bg-white/20 transition">
            <div className="text-4xl mb-3">💻</div>
            <h3 className="text-xl font-bold text-white mb-2">Web & Mobile</h3>
            <p className="text-gray-300">Aplikacje web i mobile nowej generacji</p>
          </div>
          <div className="bg-white/10 backdrop-blur-sm rounded-lg p-6 hover:bg-white/20 transition">
            <div className="text-4xl mb-3">⛓️</div>
            <h3 className="text-xl font-bold text-white mb-2">Blockchain</h3>
            <p className="text-gray-300">Smart contracts i rozwiązania DeFi</p>
          </div>
        </div>
        <div className="mt-12 space-x-4">
          <button className="bg-purple-600 hover:bg-purple-700 text-white font-bold py-3 px-8 rounded-lg transition">
            Rozpocznij projekt
          </button>
          <button className="bg-white/10 hover:bg-white/20 text-white font-bold py-3 px-8 rounded-lg backdrop-blur-sm transition">
            Dowiedz się więcej
          </button>
        </div>
      </div>
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
