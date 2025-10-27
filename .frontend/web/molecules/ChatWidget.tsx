"use client";
import React, { useEffect, useRef, useState } from "react";
import { MessageSquare, X } from "lucide-react";
import { Button } from "../components/Button";

type ChatMsg = {
  role: "user" | "assistant";
  text: string;
  links?: Array<{ url: string; text: string }>;
};

const ChatWidget: React.FC = () => {
  const [open, setOpen] = useState(false);
  const [selectedGod, setSelectedGod] = useState<string>("thoth");
  const [messages, setMessages] = useState<ChatMsg[]>([
    {
      role: "assistant",
      text: "𓅝 Witaj! Jestem Thoth, twój przewodnik po RICE. Pytaj o usługi, ceny, projekty!",
      links: [
        { url: "/services", text: "Usługi" },
        { url: "/pricing", text: "Cennik" },
        { url: "/contact", text: "Kontakt" },
      ],
    },
  ]);
  const [input, setInput] = useState("");
  const [showLoRAUpload, setShowLoRAUpload] = useState(false);
  const [loraFile, setLoraFile] = useState<File | null>(null);
  const viewportRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    viewportRef.current?.scrollTo({ top: viewportRef.current.scrollHeight });
  }, [messages, open]);

  async function send() {
    if (!input.trim()) return;
    const userMsg: ChatMsg = { role: "user", text: input.trim() };
    setMessages((m: any) => [...m, userMsg]);
    setInput("");

    try {
      // Dodaj wiadomość "thinking" z oszacowanym czasem
      setMessages((m: any) => [...m, { role: "assistant", text: "🤔 Thoth myśli... (~30 sekund na CPU)" }]);

      // Wywołaj API z całą historią konwersacji
      const response = await fetch(`/api/gods/${selectedGod}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          messages: [...messages, userMsg].map((msg) => ({
            role: msg.role,
            content: msg.text,
          })),
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to get response");
      }

      const data = await response.json();

      // Parse linki z odpowiedzi
      const content = data.message.content || data.message;
      const links = extractLinks(content);
      const cleanContent = removeLinksFromContent(content);

      // Usuń "thinking" i dodaj prawdziwą odpowiedź
      setMessages((m: any) => {
        const newMessages = [...m];
        newMessages[newMessages.length - 1] = {
          role: "assistant",
          text: cleanContent,
          links: links,
        };
        return newMessages;
      });
    } catch (error) {
      console.error("Chat error:", error);
      setMessages((m: any) => {
        const newMessages = [...m];
        newMessages[newMessages.length - 1] = {
          role: "assistant",
          text: "Przepraszam, wystąpił błąd. Spróbuj ponownie.",
        };
        return newMessages;
      });
    }
  }

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

  const handleLoRAUpload = async () => {
    if (!loraFile) return;

    try {
      const formData = new FormData();
      formData.append("file", loraFile);
      formData.append("godId", selectedGod);

      const response = await fetch("/api/lora/upload", {
        method: "POST",
        body: formData,
      });

      if (response.ok) {
        setMessages((m) => [
          ...m,
          {
            role: "assistant",
            text: `✅ LoRA adapter "${loraFile.name}" załadowany! Thoth jest teraz dostrojony.`,
          },
        ]);
        setLoraFile(null);
        setShowLoRAUpload(false);
      }
    } catch (error) {
      console.error("LoRA upload error:", error);
    }
  };

  return (
    <>
      {/* Floating button */}
      <button
        aria-label="Otwórz czat"
        onClick={() => setOpen(true)}
        className="fixed bottom-5 right-5 z-50 h-12 w-12 rounded-full bg-white text-black shadow-lg ring-1 ring-white/20 hover:scale-105 smooth"
      >
        <MessageSquare className="mx-auto" size={22} />
      </button>

      {/* Panel */}
      {open && (
        <div className="fixed bottom-20 right-5 z-50 w-[360px] overflow-hidden rounded-xl border border-white/10 bg-black/90 backdrop-blur-md">
          <div className="flex items-center justify-between border-b border-white/10 px-3 py-2">
            <div className="text-sm text-amber-400 font-semibold">📜 Thoth - Sales Agent</div>
            <button aria-label="Zamknij" onClick={() => setOpen(false)} className="text-slate-300 hover:text-white">
              <X size={18} />
            </button>
          </div>
          <div ref={viewportRef} className="max-h-80 overflow-y-auto p-3">
            {/* Quick Action Buttons - pokazuj tylko gdy 1 wiadomość */}
            {messages.length === 1 && (
              <div className="mb-3 flex flex-wrap gap-2">
                {[
                  { text: "📦 Pakiety AI", action: "Jakie macie pakiety AI models?" },
                  { text: "💼 Portfolio", action: "Jakie macie projekty?" },
                  { text: "💰 Cennik", action: "Ile kosztują usługi?" },
                  { text: "📞 Kontakt", action: "Gdzie was znaleźć?" },
                ].map((btn, idx) => (
                  <button
                    key={idx}
                    onClick={() => setInput(btn.action)}
                    className="text-xs bg-cyan-900/40 hover:bg-cyan-800/60 border border-cyan-500/30 text-cyan-300 px-3 py-1.5 rounded transition-all"
                  >
                    {btn.text}
                  </button>
                ))}
              </div>
            )}

            {messages.map((m: any, i: number) => (
              <div key={i} className={`mb-3 flex ${m.role === "user" ? "justify-end" : "justify-start"}`}>
                <div
                  className={`${
                    m.role === "user" ? "bg-white text-black" : "bg-white/5 text-slate-100"
                  } rounded-md px-3 py-2 text-sm max-w-[85%]`}
                >
                  <div className="whitespace-pre-wrap">{m.text}</div>
                  {/* Links as buttons */}
                  {m.role === "assistant" && m.links && m.links.length > 0 && (
                    <div className="mt-2 pt-2 border-t border-white/10 flex flex-wrap gap-1.5">
                      {m.links.map((link: any, idx: number) => (
                        <a
                          key={idx}
                          href={link.url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-[11px] bg-cyan-600 hover:bg-cyan-700 text-white px-2 py-1 rounded transition-all font-semibold inline-flex items-center gap-1"
                        >
                          {link.text}
                          <span>→</span>
                        </a>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>

          {/* LoRA Upload Section */}
          {showLoRAUpload && (
            <div className="border-t border-white/10 p-3 bg-purple-900/20">
              <div className="text-xs font-semibold text-purple-400 mb-2">🔮 Fine-tune Thoth</div>
              <label className="block cursor-pointer">
                <div className="border-2 border-dashed border-purple-500/30 rounded-lg p-3 text-center hover:border-purple-500/60 transition-colors">
                  {loraFile ? (
                    <div>
                      <div className="text-2xl mb-1">✅</div>
                      <div className="text-xs text-purple-400">{loraFile.name}</div>
                    </div>
                  ) : (
                    <div>
                      <div className="text-2xl mb-1">📁</div>
                      <div className="text-xs text-gray-400">Upload LoRA adapter (.safetensors, .bin)</div>
                    </div>
                  )}
                </div>
                <input
                  type="file"
                  onChange={(e) => {
                    if (e.target.files && e.target.files[0]) {
                      setLoraFile(e.target.files[0]);
                    }
                  }}
                  accept=".safetensors,.bin,.pt,.pth"
                  className="hidden"
                />
              </label>
              {loraFile && (
                <div className="flex gap-2 mt-2">
                  <button
                    onClick={handleLoRAUpload}
                    className="flex-1 bg-purple-600 hover:bg-purple-700 text-white text-xs py-2 rounded transition-all font-semibold"
                  >
                    🚀 Apply
                  </button>
                  <button
                    onClick={() => {
                      setLoraFile(null);
                      setShowLoRAUpload(false);
                    }}
                    className="px-3 bg-gray-700 hover:bg-gray-600 text-white text-xs rounded transition-all"
                  >
                    ✕
                  </button>
                </div>
              )}
            </div>
          )}

          {/* Input Area */}
          <div className="border-t border-white/10 p-3">
            <div className="flex items-center gap-2 mb-2">
              <button
                onClick={() => setShowLoRAUpload(!showLoRAUpload)}
                className="text-xs text-purple-400 hover:text-purple-300 transition-colors font-semibold"
                title="Fine-tune z własnym LoRA"
              >
                🔮 {showLoRAUpload ? "Ukryj" : "LoRA"}
              </button>
            </div>
            <div className="flex items-center gap-2">
              <input
                value={input}
                onChange={(e: any) => setInput(e.target.value)}
                onKeyDown={(e: any) => e.key === "Enter" && (e.preventDefault(), send())}
                placeholder="Pytaj o usługi, ceny..."
                className="h-10 flex-1 rounded-md border border-white/10 bg-white/5 px-3 text-slate-100 text-sm placeholder:text-slate-400 outline-none focus:border-white/30"
              />
              <Button onClick={send} size="sm" variant="outline">
                Wyślij
              </Button>
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default ChatWidget;
