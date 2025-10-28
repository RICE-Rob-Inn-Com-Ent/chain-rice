"use client";
import { useState, useRef, useEffect } from "react";

interface Message {
  role: "user" | "assistant";
  content: string;
  timestamp: Date;
  links?: Array<{ url: string; text: string }>;
}

export default function ThothUI() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [loginEmail, setLoginEmail] = useState("");
  const [loginPassword, setLoginPassword] = useState("");

  // Login handler
  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    if (loginEmail && loginPassword) {
      setIsLoggedIn(true);
    }
  };

  // If not logged in - show login screen
  if (!isLoggedIn) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-gray-900 via-black to-gray-900 text-white flex items-center justify-center p-4">
        <div className="max-w-md w-full">
          {/* Logo */}
          <div className="text-center mb-8">
            <div className="text-7xl mb-4">📜</div>
            <h1 className="text-4xl font-bold bg-gradient-to-r from-cyan-400 via-blue-500 to-blue-600 bg-clip-text text-transparent mb-2">
              Thoth Document App
            </h1>
            <p className="text-gray-400 text-sm">Analiza dokumentów i asystent tekstowy</p>
          </div>

          {/* Login Form */}
          <div className="bg-gray-900/80 backdrop-blur rounded-2xl border border-gray-700 p-8">
            <h2 className="text-xl font-bold mb-6 text-center">Zaloguj się</h2>
            <form onSubmit={handleLogin} autoComplete="off" className="space-y-4">
              <div>
                <label className="block text-sm font-semibold mb-2">Email</label>
                <input
                  type="text"
                  name="demo-email"
                  autoComplete="off"
                  value={loginEmail}
                  onChange={(e) => setLoginEmail(e.target.value)}
                  placeholder="alex@example.com"
                  className="w-full bg-gray-800 text-white rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-cyan-500"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-semibold mb-2">Hasło</label>
                <input
                  type="password"
                  name="demo-password"
                  autoComplete="new-password"
                  value={loginPassword}
                  onChange={(e) => setLoginPassword(e.target.value)}
                  placeholder="••••••••"
                  className="w-full bg-gray-800 text-white rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-cyan-500"
                  required
                />
              </div>
              <button
                type="submit"
                className="w-full bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-700 hover:to-blue-700 text-white py-3 rounded-lg font-bold transition-all"
              >
                🔐 Zaloguj się
              </button>
            </form>
            <div className="mt-6 text-center text-sm text-gray-500">
              🎮 Demo mode - wpisz dowolny email i hasło aby wejść
            </div>
          </div>

          {/* Info */}
          <div className="mt-6 bg-cyan-900/20 rounded-lg p-4 border border-cyan-500/30 text-sm text-gray-300">
            <div className="font-semibold text-cyan-400 mb-2">💡 Co możesz zrobić:</div>
            <ul className="space-y-1">
              <li>• Analizować dokumenty (TXT, PDF)</li>
              <li>• OCR - wyciąganie tekstu z obrazów</li>
              <li>• Tłumaczenia wielojęzyczne</li>
              <li>• AI asystent tekstowy</li>
            </ul>
          </div>
        </div>
      </div>
    );
  }

  // Main app (after login)
  return <ThothApp />;
}

function ThothApp() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [modelStatus, setModelStatus] = useState<"checking" | "loading" | "ready" | "error">("checking");
  const [loadingProgress, setLoadingProgress] = useState(0);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Check model status on mount
  useEffect(() => {
    const checkStatus = async () => {
      try {
        const response = await fetch("http://localhost:8001/health");
        const data = await response.json();

        if (data.model_loaded) {
          setModelStatus("ready");
        } else if (data.status === "loading" || data.ollama === "online") {
          setModelStatus("loading");
          // Start polling for status
          const interval = setInterval(async () => {
            try {
              const statusResp = await fetch("http://localhost:8001/health");
              const statusData = await statusResp.json();

              if (statusData.model_loaded) {
                setModelStatus("ready");
                clearInterval(interval);
              } else {
                // Estimate progress (0-100% over ~30 seconds)
                setLoadingProgress((prev) => Math.min(prev + 3, 95));
              }
            } catch (err) {
              console.error("Status check error:", err);
            }
          }, 1000);

          // Auto-clear after 40 seconds
          setTimeout(() => {
            clearInterval(interval);
            setModelStatus("ready");
            setLoadingProgress(100);
          }, 40000);
        }
      } catch (error) {
        console.error("Failed to check model status:", error);
        setModelStatus("error");
      }
    };

    checkStatus();
  }, []);

  // Initialize welcome message on client side only (prevents hydration mismatch)
  useEffect(() => {
    if (modelStatus === "ready") {
      setMessages([
        {
          role: "assistant",
          content:
            "𓅝 Witaj! Jestem Thoth, twój przewodnik po RICE.\n\nPomagam w:\n• Nawigacji po stronie\n• Informacjach o usługach i cenach\n• Kontakcie z zespołem\n• Poznaniu naszych projektów\n\nO co chcesz zapytać?\n\n───────\n📋 Przydatne linki:",
          timestamp: new Date(),
          links: [
            { url: "/services", text: "Nasze usługi" },
            { url: "/pricing", text: "Cennik" },
            { url: "/portfolio", text: "Portfolio" },
            { url: "/contact", text: "Kontakt" },
          ],
        },
      ]);
    }
  }, [modelStatus]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!input.trim()) return;

    const userMessage: Message = {
      role: "user",
      content: input,
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMessage]);
    setInput("");
    setIsLoading(true);

    try {
      // Wywołaj prawdziwe API Thoth
      const response = await fetch("/api/gods/thoth", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          messages: [...messages, userMessage].map((m) => ({
            role: m.role,
            content: m.content,
          })),
        }),
      });

      if (!response.ok) {
        throw new Error(`API error: ${response.status}`);
      }

      const data = await response.json();

      // Wyekstraktuj linki z odpowiedzi
      const content = data.message.content;
      const links = extractLinks(content);
      const cleanContent = removeLinksFromContent(content);

      const assistantMessage: Message = {
        role: "assistant",
        content: cleanContent,
        timestamp: new Date(),
        links: links,
      };

      setMessages((prev) => [...prev, assistantMessage]);
    } catch (error: any) {
      console.error("Error:", error);

      let errorContent = `❌ Error: ${error.message}`;

      // Check if it's a 503 (model loading) error
      if (error.message.includes("503")) {
        setModelStatus("loading");
        setLoadingProgress(0);
        errorContent =
          "⏳ Model is loading to GPU. Please wait ~30-60 seconds and try again.\n\nThe model loads to GPU memory on first use. Subsequent requests will be instant.";
      } else if (error.message.includes("404")) {
        setModelStatus("offline");
        errorContent =
          "⚠️ Model is offline or not loaded yet.\n\nPlease click the 'Wake Model' button in the header to start the model, then wait ~30 seconds for it to load to GPU.";
      }

      const errorMessage: Message = {
        role: "assistant",
        content: errorContent,
        timestamp: new Date(),
      };
      setMessages((prev) => [...prev, errorMessage]);
    } finally {
      setIsLoading(false);
    }
  };

  // Funkcja do wyciągania linków z formatu [link:URL|Text]
  const extractLinks = (content: string): Array<{ url: string; text: string }> => {
    const linkRegex = /\[link:([^\|]+)\|([^\]]+)\]/g;
    const links: Array<{ url: string; text: string }> = [];
    let match;

    while ((match = linkRegex.exec(content)) !== null) {
      links.push({
        url: match[1].trim(),
        text: match[2].trim(),
      });
    }

    return links;
  };

  // Usuń linki z treści (zostaw czysty tekst)
  const removeLinksFromContent = (content: string): string => {
    return content.replace(/\[link:[^\|]+\|[^\]]+\]/g, "").trim();
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-900 via-black to-gray-900 text-white p-4">
      {/* Header */}
      <div className="max-w-5xl mx-auto mb-6">
        <div className="bg-gradient-to-r from-cyan-900/30 to-blue-900/30 rounded-2xl p-6 border border-cyan-500/30">
          <div className="flex items-center gap-4">
            <div className="text-6xl">📜</div>
            <div className="flex-1">
              <div className="flex items-center gap-3 mb-2">
                <h1 className="text-3xl font-bold bg-gradient-to-r from-cyan-400 via-blue-500 to-blue-600 bg-clip-text text-transparent">
                  Thoth AI Model
                </h1>

                {/* Wake/Sleep Button */}
                {modelStatus === "offline" && (
                  <button
                    onClick={wakeModel}
                    disabled={isWaking}
                    className="bg-green-600 hover:bg-green-700 disabled:bg-gray-600 text-white text-xs px-3 py-1 rounded-lg font-semibold transition"
                  >
                    {isWaking ? "⏳ Waking..." : "▶️ Wake Model"}
                  </button>
                )}
              </div>

              <p className="text-sm text-gray-400 mt-1">Mistral 7B Q4_K_M • NLP & Chat Assistant</p>
              <div className="flex gap-4 mt-2 text-xs text-cyan-400">
                <span>✓ Natural Language</span>
                <span>✓ Context Aware</span>
                <span>✓ Fast Response</span>
                <span>✓ Local Inference</span>
              </div>

              {/* Loading Progress Bar */}
              {modelStatus === "loading" && (
                <div className="mt-4">
                  <div className="flex items-center gap-2 mb-2">
                    <div className="animate-spin text-xl">⏳</div>
                    <span className="text-sm text-yellow-400 font-semibold">
                      Loading model to GPU... {Math.round(loadingProgress)}%
                    </span>
                  </div>
                  <div className="w-full bg-gray-700 rounded-full h-2 overflow-hidden">
                    <div
                      className="bg-gradient-to-r from-cyan-500 to-blue-500 h-full transition-all duration-300 ease-out"
                      style={{ width: `${loadingProgress}%` }}
                    />
                  </div>
                  <p className="text-xs text-gray-500 mt-1">
                    First load: ~30-60 seconds • Loading Mistral 7B to GPU memory...
                  </p>
                </div>
              )}

              {/* Ready Status */}
              {modelStatus === "ready" && (
                <div className="mt-3 flex items-center gap-2">
                  <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
                  <span className="text-xs text-green-400 font-semibold">● Online</span>
                  <span className="text-xs text-gray-500">• Model loaded on GPU</span>
                </div>
              )}

              {/* Offline Status */}
              {modelStatus === "offline" && (
                <div className="mt-3 flex items-center gap-2">
                  <div className="w-2 h-2 bg-gray-500 rounded-full"></div>
                  <span className="text-xs text-gray-400">● Offline</span>
                  <span className="text-xs text-gray-500">• Click "Wake Model" to start</span>
                </div>
              )}

              {/* Error Status */}
              {modelStatus === "error" && (
                <div className="mt-3 text-xs text-red-400">
                  ⚠️ Cannot connect to model API. Check if container is running on port 8001.
                </div>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Chat Container */}
      <div
        className="max-w-5xl mx-auto bg-gray-900/50 backdrop-blur rounded-2xl border border-gray-700 shadow-2xl overflow-hidden flex flex-col"
        style={{ height: "calc(100vh - 200px)" }}
      >
        {/* Messages */}
        <div className="flex-1 overflow-y-auto p-6 space-y-4">
          {messages.map((msg, idx) => (
            <div key={idx} className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}>
              <div
                className={`max-w-[70%] rounded-2xl p-4 ${
                  msg.role === "user"
                    ? "bg-gradient-to-r from-blue-600 to-blue-700 text-white"
                    : "bg-gradient-to-r from-gray-800 to-gray-700 text-gray-100 border border-cyan-500/30"
                }`}
              >
                <div className="text-sm leading-relaxed whitespace-pre-wrap">{msg.content}</div>
                <div className="text-xs opacity-50 mt-2" suppressHydrationWarning>
                  {msg.timestamp.toLocaleTimeString()}
                </div>

                {/* Links */}
                {msg.role === "assistant" && msg.links && msg.links.length > 0 && (
                  <div className="mt-3 pt-3 border-t border-gray-600/30">
                    <div className="flex flex-wrap gap-2">
                      {msg.links.map((link, idx) => (
                        <a
                          key={idx}
                          href={link.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-xs bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-700 hover:to-blue-700 text-white px-4 py-2 rounded-lg transition-all hover:scale-105 shadow-lg hover:shadow-cyan-500/50 font-semibold flex items-center gap-1"
                        >
                          {link.text}
                          <span className="text-[10px]">→</span>
                        </a>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>
          ))}
          {isLoading && (
            <div className="flex justify-start">
              <div className="bg-gradient-to-r from-gray-800 to-gray-700 rounded-2xl p-4 border border-cyan-500/30">
                <div className="flex gap-2">
                  <div className="w-2 h-2 bg-cyan-400 rounded-full animate-bounce"></div>
                  <div className="w-2 h-2 bg-cyan-400 rounded-full animate-bounce delay-100"></div>
                  <div className="w-2 h-2 bg-cyan-400 rounded-full animate-bounce delay-200"></div>
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Input Area */}
        <form onSubmit={handleSubmit} className="border-t border-gray-700 p-4 bg-gray-900/80">
          <div className="flex gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="Pytaj o usługi, ceny, portfolio... Thoth ci pomoże!"
              className="flex-1 bg-gray-800 text-white rounded-lg px-4 py-2 focus:outline-none focus:ring-2 focus:ring-cyan-500 text-sm"
              disabled={isLoading}
            />
            <button
              type="submit"
              disabled={isLoading || !input.trim()}
              className="bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-700 hover:to-blue-700 disabled:from-gray-700 disabled:to-gray-800 text-white px-6 py-2 rounded-lg font-semibold transition-all disabled:cursor-not-allowed"
            >
              {isLoading ? "⏳" : "📤"}
            </button>
          </div>
          <div className="mt-2 text-xs text-gray-500">
            💡 Przykłady: "Gdzie was znaleźć?", "Ile kosztują usługi?", "Jakie macie projekty?"
          </div>
        </form>
      </div>

      {/* Footer */}
      <div className="max-w-5xl mx-auto mt-4 text-center text-xs text-gray-500">
        𓅝 Thoth Sales Agent • Mistral 7B Q4_K_M • Twój przewodnik po RICE
      </div>
    </div>
  );
}
