import React, { useState } from 'react';
import BastetUI from '../../models/BastetUI';
import IsisUI from '../../models/IsisUI';
import KhnumUI from '../../models/KhnumUI';
import MaatUI from '../../models/MaatUI';
import RaUI from '../../models/RaUI';
import ThothUI from '../../models/ThothUI';

type Model = 'bastet' | 'isis' | 'khnum' | 'maat' | 'ra' | 'thoth';

const models = [
  { id: 'bastet' as Model, name: 'Bastet', icon: '🐱', desc: 'Computer Vision', color: 'from-yellow-600 to-amber-600' },
  { id: 'isis' as Model, name: 'Isis', icon: '✨', desc: 'Medical AI', color: 'from-purple-600 to-pink-600' },
  {
    id: 'khnum' as Model,
    name: 'Khnum',
    icon: '💰',
    desc: 'Financial Analysis',
    color: 'from-green-600 to-emerald-600',
  },
  { id: 'maat' as Model, name: 'Maat', icon: '⚖️', desc: 'Legal AI', color: 'from-blue-600 to-indigo-600' },
  { id: 'ra' as Model, name: 'Ra', icon: '☀️', desc: 'Image Generation', color: 'from-amber-600 to-orange-600' },
  { id: 'thoth' as Model, name: 'Thoth', icon: '📜', desc: 'Knowledge Assistant', color: 'from-cyan-600 to-blue-600' },
];

export default function ModelsView() {
  const [activeModel, setActiveModel] = useState<Model>('thoth');

  const renderModel = () => {
    switch (activeModel) {
      case 'bastet':
        return <BastetUI />;
      case 'isis':
        return <IsisUI />;
      case 'khnum':
        return <KhnumUI />;
      case 'maat':
        return <MaatUI />;
      case 'ra':
        return <RaUI />;
      case 'thoth':
        return <ThothUI />;
      default:
        return null;
    }
  };

  return (
    <div className="space-y-6">
      {/* Model Selector */}
      <div className="mx-auto max-w-7xl px-4">
        <div className="bg-gray-900/50 rounded-2xl p-6 border border-gray-700">
          <h2 className="text-2xl font-bold mb-4 bg-gradient-to-r from-cyan-400 to-purple-600 bg-clip-text text-transparent">
            AI Model Demos
          </h2>
          <p className="text-gray-400 mb-6">
            Interactive demos for each AI god model. Click to explore their capabilities.
          </p>

          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
            {models.map((model) => (
              <button
                key={model.id}
                onClick={() => setActiveModel(model.id)}
                className={`p-4 rounded-xl text-center transition-all ${
                  activeModel === model.id
                    ? `bg-gradient-to-r ${model.color} text-white shadow-lg`
                    : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
                }`}
              >
                <div className="text-4xl mb-2">{model.icon}</div>
                <div className="font-bold text-sm">{model.name}</div>
                <div className="text-xs opacity-70 mt-1">{model.desc}</div>
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Active Model UI */}
      <div>{renderModel()}</div>
    </div>
  );
}
