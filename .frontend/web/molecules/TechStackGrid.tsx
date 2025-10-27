'use client';
import React from 'react';
import { Cloud, Database, Code2, Container, Server, Cpu, Brain, Shield, Zap, Workflow } from 'lucide-react';

interface TechItem {
  name: string;
  category: string;
  icon?: React.ReactNode;
  color: string;
}

const techStack: TechItem[] = [
  // Cloud Providers
  { name: 'AWS', category: 'Cloud', icon: <Cloud size={24} />, color: 'from-orange-500 to-amber-600' },
  { name: 'Azure', category: 'Cloud', icon: <Cloud size={24} />, color: 'from-blue-500 to-cyan-600' },
  { name: 'Google Cloud', category: 'Cloud', icon: <Cloud size={24} />, color: 'from-red-500 to-yellow-500' },
  { name: 'Vercel', category: 'Cloud', icon: <Zap size={24} />, color: 'from-gray-700 to-gray-900' },
  { name: 'DigitalOcean', category: 'Cloud', icon: <Cloud size={24} />, color: 'from-blue-600 to-blue-800' },

  // AI/ML
  { name: 'OpenAI', category: 'AI/ML', icon: <Brain size={24} />, color: 'from-green-500 to-emerald-600' },
  { name: 'Claude', category: 'AI/ML', icon: <Brain size={24} />, color: 'from-orange-500 to-amber-600' },
  { name: 'Gemini', category: 'AI/ML', icon: <Brain size={24} />, color: 'from-blue-500 to-indigo-600' },
  { name: 'HuggingFace', category: 'AI/ML', icon: <Brain size={24} />, color: 'from-yellow-500 to-orange-500' },
  { name: 'Ollama', category: 'AI/ML', icon: <Brain size={24} />, color: 'from-purple-500 to-pink-600' },
  { name: 'Cursor AI', category: 'AI/ML', icon: <Code2 size={24} />, color: 'from-cyan-500 to-blue-600' },

  // Infrastructure
  { name: 'Docker', category: 'Infrastructure', icon: <Container size={24} />, color: 'from-blue-500 to-cyan-600' },
  {
    name: 'Kubernetes',
    category: 'Infrastructure',
    icon: <Workflow size={24} />,
    color: 'from-blue-600 to-indigo-700',
  },
  { name: 'Terraform', category: 'Infrastructure', icon: <Server size={24} />, color: 'from-purple-600 to-violet-700' },
  { name: 'Ansible', category: 'Infrastructure', icon: <Server size={24} />, color: 'from-red-600 to-red-700' },
  { name: 'Bazel', category: 'Infrastructure', icon: <Workflow size={24} />, color: 'from-green-600 to-emerald-700' },

  // Frontend
  { name: 'Next.js', category: 'Frontend', icon: <Code2 size={24} />, color: 'from-gray-800 to-black' },
  { name: 'React', category: 'Frontend', icon: <Code2 size={24} />, color: 'from-cyan-500 to-blue-600' },
  { name: 'TypeScript', category: 'Frontend', icon: <Code2 size={24} />, color: 'from-blue-600 to-blue-800' },
  { name: 'Tailwind CSS', category: 'Frontend', icon: <Code2 size={24} />, color: 'from-cyan-400 to-teal-600' },
  { name: 'Flutter', category: 'Frontend', icon: <Code2 size={24} />, color: 'from-blue-500 to-sky-600' },

  // Backend
  { name: 'Go', category: 'Backend', icon: <Cpu size={24} />, color: 'from-cyan-500 to-blue-600' },
  { name: 'Python', category: 'Backend', icon: <Cpu size={24} />, color: 'from-blue-500 to-yellow-500' },
  { name: 'FastAPI', category: 'Backend', icon: <Zap size={24} />, color: 'from-teal-500 to-green-600' },
  { name: 'GraphQL', category: 'Backend', icon: <Workflow size={24} />, color: 'from-pink-500 to-purple-600' },
  { name: 'gRPC', category: 'Backend', icon: <Server size={24} />, color: 'from-blue-600 to-cyan-700' },

  // Database
  { name: 'PostgreSQL', category: 'Database', icon: <Database size={24} />, color: 'from-blue-600 to-blue-800' },
  { name: 'MongoDB', category: 'Database', icon: <Database size={24} />, color: 'from-green-600 to-emerald-700' },
  { name: 'Redis', category: 'Database', icon: <Database size={24} />, color: 'from-red-600 to-red-700' },
  { name: 'Qdrant', category: 'Database', icon: <Database size={24} />, color: 'from-purple-600 to-violet-700' },
];

interface TechStackGridProps {
  filterCategory?: string;
}

export const TechStackGrid: React.FC<TechStackGridProps> = ({ filterCategory }) => {
  const filteredTech = filterCategory ? techStack.filter((t) => t.category === filterCategory) : techStack;

  const categories = Array.from(new Set(techStack.map((t) => t.category)));

  return (
    <div className="space-y-12">
      {!filterCategory && (
        <div className="text-center">
          <h3 className="text-3xl font-bold mb-3 bg-gradient-to-r from-cyan-400 via-blue-500 to-purple-600 bg-clip-text text-transparent">
            Technologies We Use
          </h3>
          <p className="text-gray-400">Nasz stack technologiczny - nowoczesne narzędzia i platformy</p>
        </div>
      )}

      {filterCategory ? (
        // Single category grid
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
          {filteredTech.map((tech) => (
            <TechCard key={tech.name} tech={tech} />
          ))}
        </div>
      ) : (
        // Grouped by category
        <div className="space-y-10">
          {categories.map((category) => (
            <div key={category}>
              <h4 className="text-xl font-bold text-gray-300 mb-4">{category}</h4>
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
                {techStack
                  .filter((t) => t.category === category)
                  .map((tech) => (
                    <TechCard key={tech.name} tech={tech} />
                  ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

const TechCard: React.FC<{ tech: TechItem }> = ({ tech }) => {
  return (
    <div className="group relative overflow-hidden rounded-xl border border-gray-700 bg-gray-900/50 p-4 transition-all hover:border-cyan-500/50 hover:shadow-[0_0_20px_rgba(34,211,238,0.3)] hover:scale-105">
      <div
        className={`absolute inset-0 bg-gradient-to-br ${tech.color} opacity-0 group-hover:opacity-10 transition-opacity`}
      />
      <div className="relative flex flex-col items-center text-center">
        <div className="text-gray-400 group-hover:text-cyan-400 transition-colors mb-2">{tech.icon}</div>
        <div className="text-sm font-semibold text-gray-200 group-hover:text-white transition-colors">{tech.name}</div>
      </div>
    </div>
  );
};

export default TechStackGrid;
