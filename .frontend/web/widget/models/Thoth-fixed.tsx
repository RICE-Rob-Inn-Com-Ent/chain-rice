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
              Thoth AI Model
            </h1>
            <p className="text-gray-400 text-sm">NLP & Chat Assistant • Mistral 7B</p>
          </div>

          {/* Login Form */}
          <div className="bg-gray-900/80 backdrop-blur rounded-2xl border border-gray-700 p-8">
            <h2 className="text-xl font-bold mb-6 text-center">Login</h2>
            <form onSubmit={handleLogin} autoComplete="off" className="space-y-4">
              <div>
                <label className="block text-sm font-semibold mb-2">Email</label>
                <input
                  type="text"
                  name="demo-email"
                  autoComplete="off"
                  value={loginEmail}
                  onChange={(e) => setLoginEmail(e.target.value)}
                  placeholder="demo@example.com"
                  className="w-full bg-gray-800 text-white rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-cyan-500"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-semibold mb-2">Password</label>
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
                🔐 Login
              </button>
            </form>
            <div className="mt-6 text-center text-sm text-gray-500">🎮 Demo mode - enter any credentials to access</div>
          </div>

          {/* Info */}
          <div className="mt-8 text-center text-xs text-gray-600">
            <p>Thoth AI Model Demo • Mistral 7B Q4_K_M</p>
            <p className="mt-1">Natural Language Processing & Chat</p>
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
  const [modelStatus, setModelStatus] = useState<"checking" | "loading" | "ready" | "offline" | "error">("checking");
  const [loadingProgress, setLoadingProgress] = useState(0);
  const [isWaking, setIsWaking] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Check model status on mount and periodically
  useEffect(() => {
    const checkStatus = async () => {
      try {
        const response = await fetch("http://localhost:8001/health");
        const data = await response.json();

        if (data.model_loaded) {
          setModelStatus("ready");
          setLoadingProgress(100);
        } else if (data.status === "loading" || data.ollama === "online") {
          setModelStatus("loading");
        } else {
          setModelStatus("offline");
        }
      } catch (error) {
        console.error("Failed to check model status:", error);
        setModelStatus("error");
      }
    };

    checkStatus();

    // Poll every 3 seconds
    const pollInterval = setInterval(checkStatus, 3000);

    return () => clearInterval(pollInterval);
  }, []);

  // Progress bar animation when loading
  useEffect(() => {
    if (modelStatus === "loading") {
      const progressInterval = setInterval(() => {
        setLoadingProgress((prev) => Math.min(prev + 2, 95));
      }, 1000);

      return () => clearInterval(progressInterval);
    }
  }, [modelStatus]);

  // Wake model function
  const wakeModel = async () => {
    setIsWaking(true);
    setModelStatus("loading");
    setLoadingProgress(0);

    try {
      await fetch("http://localhost:8001/wake", { method: "POST" });

      // Start polling for ready status
      let attempts = 0;
      const checkReady = setInterval(async () => {
        attempts++;
        try {
          const resp = await fetch("http://localhost:8001/health");
          const data = await resp.json();

          if (data.model_loaded) {
            setModelStatus("ready");
            setLoadingProgress(100);
            setIsWaking(false);
            clearInterval(checkReady);
          } else if (attempts > 60) {
            // Timeout after 60 seconds
            setIsWaking(false);
            clearInterval(checkReady);
          }
        } catch (err) {
          console.error("Wake check error:", err);
        }
      }, 1000);
    } catch (error) {
      console.error("Failed to wake model:", error);
      setIsWaking(false);
      setModelStatus("error");
    }
  };

  // Initialize welcome message on client side only (prevents hydration mismatch)
  useEffect(() => {
    if (modelStatus === "ready" && messages.length === 0) {
      setMessages([
        {
          role: "assistant",
          content:
            "📜 Hello! I'm Thoth AI - your intelligent assistant.\n\nI can help with:\n• Natural language queries\n• Context-aware responses\n• Information retrieval\n• Technical Q&A\n\nWhat would you like to know?",
          timestamp: new Date(),
        },
      ]);
    }
  }, [modelStatus, messages.length]);

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
      // Call Thoth API directly
      const response = await fetch("http://localhost:8001/chat", {
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
        const errorData = await response.json().catch(() => ({}));
        throw new Error(`API error: ${response.status} - ${JSON.stringify(errorData)}`);
      }

      const data = await response.json();

      // Extract links from response
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

  // Function to extract links from format [link:URL|Text]
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

  // Remove links from content (keep clean text)
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
                <p className="whitespace-pre-wrap">{msg.content}</p>
                {msg.links && msg.links.length > 0 && (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {msg.links.map((link, linkIdx) => (
                      <a
                        key={linkIdx}
                        href={link.url}
                        className="inline-block bg-cyan-600/20 hover:bg-cyan-600/40 text-cyan-300 px-3 py-1 rounded-lg text-sm transition"
                      >
                        🔗 {link.text}
                      </a>
                    ))}
                  </div>
                )}
                <div className="text-xs text-gray-500 mt-2">{msg.timestamp.toLocaleTimeString()}</div>
              </div>
            </div>
          ))}
          {isLoading && (
            <div className="flex justify-start">
              <div className="max-w-[70%] rounded-2xl p-4 bg-gradient-to-r from-gray-800 to-gray-700 border border-cyan-500/30">
                <div className="flex items-center gap-2">
                  <div className="animate-spin text-xl">⏳</div>
                  <span className="text-gray-400">Thinking...</span>
                </div>
              </div>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Input */}
        <div className="p-4 border-t border-gray-700 bg-gray-900/70">
          <form onSubmit={handleSubmit} className="flex gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder={modelStatus === "ready" ? "Ask me anything..." : "Model is loading..."}
              disabled={isLoading || modelStatus !== "ready"}
              className="flex-1 bg-gray-800 text-white rounded-lg px-4 py-3 focus:outline-none focus:ring-2 focus:ring-cyan-500 disabled:opacity-50"
            />
            <button
              type="submit"
              disabled={isLoading || !input.trim() || modelStatus !== "ready"}
              className="bg-gradient-to-r from-cyan-600 to-blue-600 hover:from-cyan-700 hover:to-blue-700 disabled:from-gray-700 disabled:to-gray-800 text-white px-6 py-3 rounded-lg font-semibold transition disabled:cursor-not-allowed"
            >
              {isLoading ? "⏳" : "Send"}
            </button>
          </form>
        </div>
      </div>
    </div>
  );
}
