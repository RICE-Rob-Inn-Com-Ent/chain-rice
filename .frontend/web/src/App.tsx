import React, { useState } from 'react';
import ComponentsView from './routes/ComponentsView';
import ModelsView from './routes/ModelsView';
import BenchmarksView from './routes/BenchmarksView';

type View = 'components' | 'models' | 'benchmarks';

export default function App() {
  const [activeView, setActiveView] = useState<View>('components');

  return (
    <div className="min-h-screen bg-black text-white">
      {/* Header */}
      <header className="fixed top-0 left-0 right-0 z-50 border-b border-white/10 bg-black/95 backdrop-blur-sm">
        <div className="mx-auto max-w-7xl px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="text-3xl">🎨</div>
              <div>
                <h1 className="text-xl font-bold bg-gradient-to-r from-cyan-400 via-purple-500 to-pink-600 bg-clip-text text-transparent">
                  @rice/ui-kit
                </h1>
                <p className="text-xs text-gray-500">Component Library & Demo Gallery</p>
              </div>
            </div>

            {/* Navigation Tabs */}
            <nav className="flex gap-2">
              {[
                { id: 'components' as View, label: 'Components', icon: '🧩' },
                { id: 'models' as View, label: 'AI Models', icon: '🤖' },
                { id: 'benchmarks' as View, label: 'Benchmarks', icon: '⚡' },
              ].map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setActiveView(tab.id)}
                  className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all ${
                    activeView === tab.id
                      ? 'bg-gradient-to-r from-cyan-600 to-purple-600 text-white'
                      : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
                  }`}
                >
                  <span className="mr-2">{tab.icon}</span>
                  {tab.label}
                </button>
              ))}
            </nav>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="pt-24 pb-8">
        {activeView === 'components' && <ComponentsView />}
        {activeView === 'models' && <ModelsView />}
        {activeView === 'benchmarks' && <BenchmarksView />}
      </main>

      {/* Footer */}
      <footer className="border-t border-white/10 bg-black py-6">
        <div className="mx-auto max-w-7xl px-4 text-center text-sm text-gray-500">
          <p>🚀 Rice UI Kit • Vite {import.meta.env.MODE} • Port 3000</p>
        </div>
      </footer>
    </div>
  );
}
