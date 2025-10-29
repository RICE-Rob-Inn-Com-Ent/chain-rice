import React, { useState } from "react";
import { Icon } from "@iconify/react";

type DemoMode = "text" | "image" | "vision" | "code";

export const Demo: React.FC = () => {
  const [mode, setMode] = useState<DemoMode>("text");
  const [input, setInput] = useState("");
  const [output, setOutput] = useState("");
  const [isGenerating, setIsGenerating] = useState(false);

  const handleGenerate = async () => {
    setIsGenerating(true);
    setOutput("");

    // Simulate API call
    setTimeout(() => {
      switch (mode) {
        case "text":
          setOutput(
            "Here's a generated response from GiPT-1 combining wisdom from Thoth, Maat, and Khnum. This multimodal model can understand context, generate creative text, and provide technical insights all in one response."
          );
          break;
        case "image":
          setOutput("[Image would be generated here by Ra - Stable Diffusion component]");
          break;
        case "vision":
          setOutput(
            "Bastet's vision analysis: Detected 3 people, 1 dog, outdoor scene, sunny weather. Poses: standing, smiling. Objects: bench, trees, sky."
          );
          break;
        case "code":
          setOutput(`// Khnum's code generation:\nfunction fibonacci(n: number): number {\n  if (n <= 1) return n;\n  return fibonacci(n - 1) + fibonacci(n - 2);\n}\n\n// Optimized with memoization:\nconst fib = (n: number, memo: Map<number, number> = new Map()): number => {\n  if (n <= 1) return n;\n  if (memo.has(n)) return memo.get(n)!;\n  const result = fib(n - 1, memo) + fib(n - 2, memo);\n  memo.set(n, result);\n  return result;\n};`);
          break;
      }
      setIsGenerating(false);
    }, 2000);
  };

  return (
    <div className="py-12">
      {/* Header */}
      <div className="max-w-6xl mx-auto px-6 mb-12 text-center">
        <h1 className="text-5xl font-bold text-white mb-4">Try GiPT-1 Live</h1>
        <p className="text-xl text-gray-300">
          Experience the power of multimodal AI. Select a mode and see GiPT-1 in action.
        </p>
      </div>

      <div className="max-w-6xl mx-auto px-6">
        {/* Mode Selection */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          {[
            { id: "text", icon: "mdi:text", label: "Text Generation", desc: "Thoth, Maat, Isis" },
            { id: "image", icon: "mdi:image", label: "Image Creation", desc: "Ra (Stable Diffusion)" },
            { id: "vision", icon: "mdi:eye", label: "Vision Analysis", desc: "Bastet (LLaVA)" },
            { id: "code", icon: "mdi:code-braces", label: "Code Generation", desc: "Khnum (CodeLlama)" },
          ].map((m) => (
            <button
              key={m.id}
              onClick={() => setMode(m.id as DemoMode)}
              className={`p-6 rounded-xl border-2 transition ${
                mode === m.id
                  ? "bg-purple-500/20 border-purple-500 text-white"
                  : "bg-white/5 border-white/10 text-gray-400 hover:border-white/30"
              }`}
            >
              <Icon icon={m.icon} width={40} className="mx-auto mb-2" />
              <div className="font-semibold mb-1">{m.label}</div>
              <div className="text-xs opacity-70">{m.desc}</div>
            </button>
          ))}
        </div>

        {/* Demo Interface */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Input */}
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
            <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <Icon icon="mdi:pencil" width={24} />
              Input
            </h3>

            {mode === "text" && (
              <textarea
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="Enter your prompt here... Example: 'Write a professional email about a project delay'"
                className="w-full h-64 bg-black/30 border border-white/10 rounded-lg p-4 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-purple-500"
              />
            )}

            {mode === "image" && (
              <textarea
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="Describe the image you want to generate... Example: 'A futuristic city with flying cars at sunset, cyberpunk style'"
                className="w-full h-64 bg-black/30 border border-white/10 rounded-lg p-4 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-orange-500"
              />
            )}

            {mode === "vision" && (
              <div>
                <input
                  type="file"
                  accept="image/*"
                  className="w-full mb-4 text-sm text-gray-400 file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:bg-purple-500 file:text-white hover:file:bg-purple-600"
                />
                <textarea
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  placeholder="What do you want to know about the image? Example: 'Describe what you see' or 'Count the people'"
                  className="w-full h-40 bg-black/30 border border-white/10 rounded-lg p-4 text-white placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-yellow-500"
                />
              </div>
            )}

            {mode === "code" && (
              <textarea
                value={input}
                onChange={(e) => setInput(e.target.value)}
                placeholder="Describe the code you need... Example: 'Create a React component for a file uploader with drag and drop'"
                className="w-full h-64 bg-black/30 border border-white/10 rounded-lg p-4 text-white font-mono text-sm placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
            )}

            <button
              onClick={handleGenerate}
              disabled={isGenerating || !input}
              className="w-full mt-4 px-6 py-3 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 disabled:from-gray-600 disabled:to-gray-700 text-white font-bold rounded-lg transition flex items-center justify-center gap-2"
            >
              {isGenerating ? (
                <>
                  <Icon icon="svg-spinners:90-ring-with-bg" width={20} />
                  Generating...
                </>
              ) : (
                <>
                  <Icon icon="mdi:magic-staff" width={20} />
                  Generate with GiPT-1
                </>
              )}
            </button>
          </div>

          {/* Output */}
          <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
            <h3 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
              <Icon icon="mdi:lightning-bolt" width={24} />
              Output
            </h3>

            {output ? (
              <div className="bg-black/30 border border-green-500/30 rounded-lg p-4 h-64 overflow-y-auto">
                <pre className="text-gray-300 text-sm whitespace-pre-wrap font-mono">{output}</pre>
              </div>
            ) : (
              <div className="bg-black/30 border border-white/10 rounded-lg p-4 h-64 flex items-center justify-center">
                <div className="text-center text-gray-500">
                  <Icon icon="mdi:message-off" width={48} className="mx-auto mb-2 opacity-50" />
                  <p>No output yet. Enter a prompt and click Generate.</p>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Info Note */}
        <div className="mt-8 bg-blue-900/20 border border-blue-500/30 rounded-xl p-6">
          <div className="flex items-start gap-3">
            <Icon icon="mdi:information" width={24} className="text-blue-400 flex-shrink-0 mt-0.5" />
            <div className="text-sm text-blue-200">
              <p className="font-semibold mb-1">This is a demo interface</p>
              <p>
                For full access to GiPT-1 with all features, API integration, and production-ready deployment, 
                check out our <a href="/pricing" className="text-blue-400 underline hover:text-blue-300">pricing plans</a> or 
                visit the <a href="http://localhost:3001" className="text-purple-400 underline hover:text-purple-300" target="_blank" rel="noopener noreferrer">admin panel</a>.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

