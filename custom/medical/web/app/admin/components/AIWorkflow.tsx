"use client";

import { useState } from "react";
import { Sparkles, X, Loader2, Shield, Calculator, MessageSquare } from "lucide-react";

type AIWorkflowProps = {
  workflowName: string;
  workflowDescription: string;
  iconName: "shield" | "calculator" | "messageSquare";
  iconColor?: string;
  iconBgColor?: string;
  workflowType: "dashboard" | "accounting" | "social";
};

const iconMap = {
  shield: Shield,
  calculator: Calculator,
  messageSquare: MessageSquare,
};

export default function AIWorkflow({
  workflowName,
  workflowDescription,
  iconName,
  iconColor = "text-ember-400",
  iconBgColor = "bg-ember-500/20",
  workflowType,
}: AIWorkflowProps) {
  const Icon = iconMap[iconName];
  const [showAIWorkflow, setShowAIWorkflow] = useState(false);
  const [aiQuery, setAIQuery] = useState("");
  const [aiResponse, setAIResponse] = useState("");
  const [isAIProcessing, setIsAIProcessing] = useState(false);

  const handleAIQuery = async () => {
    if (!aiQuery.trim()) return;
    setIsAIProcessing(true);
    setAIResponse("");

    try {
      const response = await fetch("/api/ai/workflow", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          query: aiQuery,
          workflowType,
        }),
      });

      const data = await response.json();
      if (!response.ok) throw new Error(data.error || "Błąd podczas przetwarzania zapytania");

      setAIResponse(data.response || "Brak odpowiedzi od AI");
    } catch (error: any) {
      setAIResponse(`Błąd: ${error.message}`);
    } finally {
      setIsAIProcessing(false);
    }
  };

  const quickActions = {
    dashboard: [
      {
        title: "🔍 Znajdź wolne terminy",
        description: "Wyszukaj dostępne sloty",
        query: "Znajdź wolne terminy na najbliższy tydzień",
      },
      {
        title: "⚡ Optymalizuj grafik",
        description: "Lepsze wykorzystanie czasu",
        query: "Zoptymalizuj grafik na ten tydzień",
      },
      {
        title: "📊 Statystyki",
        description: "Analiza danych",
        query: "Przeanalizuj statystyki wizyt",
      },
      {
        title: "💡 Propozycje terminów",
        description: "Sugestie dla pacjentów",
        query: "Zaproponuj terminy dla nowych pacjentów",
      },
    ],
    accounting: [
      {
        title: "💰 Analiza przychodów",
        description: "Przeanalizuj przychody z ostatniego miesiąca",
        query: "Przeanalizuj przychody z ostatniego miesiąca",
      },
      {
        title: "📈 Prognoza finansowa",
        description: "Przewidź przychody na następny miesiąc",
        query: "Przewidź przychody na następny miesiąc",
      },
      {
        title: "💸 Analiza kosztów",
        description: "Przeanalizuj koszty kadrowe",
        query: "Przeanalizuj koszty kadrowe",
      },
      {
        title: "📋 Raport faktur",
        description: "Wygeneruj raport faktur",
        query: "Wygeneruj raport faktur",
      },
    ],
    social: [
      {
        title: "📱 Plan postów",
        description: "Zaplanuj posty na media społecznościowe",
        query: "Zaplanuj posty na media społecznościowe",
      },
      {
        title: "📊 Analiza zasięgu",
        description: "Przeanalizuj zasięg postów",
        query: "Przeanalizuj zasięg postów",
      },
      {
        title: "💬 Odpowiedzi na komentarze",
        description: "Pomóż odpowiedzieć na komentarze",
        query: "Pomóż odpowiedzieć na komentarze",
      },
      {
        title: "🎯 Kampania reklamowa",
        description: "Zaplanuj kampanię reklamową",
        query: "Zaplanuj kampanię reklamową",
      },
    ],
  };

  return (
    <>
      {/* AI Workflow Button */}
      <button
        type="button"
        onClick={() => setShowAIWorkflow(true)}
        className="fixed bottom-24 right-8 w-14 h-14 rounded-full bg-gradient-to-br from-ember-500 to-ember-700 text-white shadow-lg flex items-center justify-center hover:from-ember-600 hover:to-ember-800 transition-all transform hover:scale-105 z-30"
        title={workflowName}
      >
        <Icon className="h-6 w-6" />
      </button>

      {/* AI Workflow Modal */}
      {showAIWorkflow && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-slate-900/70 p-4">
          <div className="w-full max-w-2xl rounded-3xl border border-white/10 bg-obsidian-900 p-6 shadow-2xl">
            <div className="flex items-center justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 rounded-full ${iconBgColor} flex items-center justify-center`}>
                  <Icon className={`h-6 w-6 ${iconColor}`} />
                </div>
                <div>
                  <h2 className="text-2xl font-semibold text-ivory-100">{workflowName}</h2>
                  <p className="text-sm text-ivory-100/60">{workflowDescription}</p>
                </div>
              </div>
              <button
                onClick={() => {
                  setShowAIWorkflow(false);
                  setAIQuery("");
                  setAIResponse("");
                  setIsAIProcessing(false);
                }}
                className="rounded-full border border-white/15 px-3 py-1 text-sm text-ivory-100/70 hover:bg-white/10 transition-colors"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {!aiResponse ? (
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-ivory-100/70 mb-2">
                    Co chcesz zrobić?
                  </label>
                  <textarea
                    value={aiQuery}
                    onChange={(e) => setAIQuery(e.target.value)}
                    placeholder={`Np. "${quickActions[workflowType][0]?.query || "Zapytaj mnie o cokolwiek"}..."`}
                    className="w-full rounded-lg border border-white/10 bg-white/5 px-4 py-3 text-sm text-ivory-100 placeholder:text-ivory-100/40 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20 min-h-[120px] resize-none"
                  />
                </div>

                {/* Quick actions */}
                <div className="grid grid-cols-2 gap-3">
                  {quickActions[workflowType].map((action, idx) => (
                    <button
                      key={idx}
                      type="button"
                      onClick={() => setAIQuery(action.query)}
                      className="px-4 py-3 rounded-lg border border-white/10 bg-white/5 text-left text-sm text-ivory-100 hover:bg-white/10 transition-colors"
                    >
                      <div className="font-medium mb-1">{action.title}</div>
                      <div className="text-xs text-ivory-100/60">{action.description}</div>
                    </button>
                  ))}
                </div>

                <button
                  type="button"
                  onClick={handleAIQuery}
                  disabled={!aiQuery.trim() || isAIProcessing}
                  className="w-full rounded-lg py-3 text-sm font-semibold text-white bg-gradient-to-r from-ember-500 to-ember-600 hover:from-ember-600 hover:to-ember-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all flex items-center justify-center gap-2"
                >
                  {isAIProcessing ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin" />
                      Przetwarzanie...
                    </>
                  ) : (
                    <>
                      <Sparkles className="h-4 w-4" />
                      Uruchom workflow AI
                    </>
                  )}
                </button>
              </div>
            ) : (
              <div className="space-y-4">
                <div className="rounded-lg border border-white/10 bg-white/5 p-4">
                  <div className="flex items-start gap-3 mb-3">
                    <Icon className={`h-5 w-5 ${iconColor} flex-shrink-0 mt-0.5`} />
                    <div className="flex-1">
                      <div className="text-sm font-medium text-ivory-100 mb-2">Twoje zapytanie:</div>
                      <div className="text-sm text-ivory-100/70 italic">{aiQuery}</div>
                    </div>
                  </div>
                  <div className="border-t border-white/10 pt-3 mt-3">
                    <div className="text-sm font-medium text-ivory-100 mb-2">Odpowiedź AI:</div>
                    <div className="text-sm text-ivory-100/80 whitespace-pre-line">{aiResponse}</div>
                  </div>
                </div>

                <div className="flex gap-2">
                  <button
                    type="button"
                    onClick={() => {
                      setAIQuery("");
                      setAIResponse("");
                      setIsAIProcessing(false);
                    }}
                    className="flex-1 rounded-lg py-2 text-sm font-semibold text-white bg-ember-500 hover:bg-ember-600"
                  >
                    Nowe zapytanie
                  </button>
                  <button
                    type="button"
                    onClick={() => {
                      setShowAIWorkflow(false);
                      setAIQuery("");
                      setAIResponse("");
                      setIsAIProcessing(false);
                    }}
                    className="flex-1 rounded-lg border border-white/10 py-2 text-sm text-ivory-100 transition hover:bg-white/5"
                  >
                    Zamknij
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </>
  );
}

