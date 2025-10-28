import React, { useState } from "react";
import { Icon } from "@iconify/react";

/**
 * Maat Training - Legal & Analytics AI Training
 * For: Legal Analysis, Sentiment Analysis, Text Summarization, Data Visualization
 */
export const MaatTraining: React.FC = () => {
  const [trainingType, setTrainingType] = useState<"legal" | "sentiment" | "summary">("legal");

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3 mb-6">
        <span className="text-5xl">⚖️</span>
        <div>
          <h2 className="text-3xl font-bold text-white">Maat - Legal & Analytics Training</h2>
          <p className="text-gray-400">Trenuj modele analiz prawnych i sentymentu</p>
        </div>
      </div>

      {/* Training Type Selection */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Wybierz Typ Treningu</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <button
            onClick={() => setTrainingType("legal")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "legal"
                ? "bg-cyan-500/20 border-cyan-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:gavel" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Legal Analysis</div>
            <div className="text-xs mt-1">Mistral 7B legal fine-tuning</div>
          </button>

          <button
            onClick={() => setTrainingType("sentiment")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "sentiment"
                ? "bg-blue-500/20 border-blue-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:emoticon-happy-outline" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Sentiment Analysis</div>
            <div className="text-xs mt-1">XLM-RoBERTa training</div>
          </button>

          <button
            onClick={() => setTrainingType("summary")}
            className={`p-4 rounded-lg border-2 transition ${
              trainingType === "summary"
                ? "bg-teal-500/20 border-teal-500 text-white"
                : "bg-white/5 border-white/10 text-gray-400 hover:border-white/20"
            }`}
          >
            <Icon icon="mdi:file-document-edit-outline" width={32} className="mx-auto mb-2" />
            <div className="font-bold">Text Summarization</div>
            <div className="text-xs mt-1">Abstractive summarization</div>
          </button>
        </div>
      </div>

      {/* Legal Analysis Training */}
      {trainingType === "legal" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Legal Documents Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Document Type</label>
              <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-cyan-500 focus:outline-none">
                <option>Contracts</option>
                <option>Court Decisions</option>
                <option>Legal Opinions</option>
                <option>Regulations</option>
                <option>Case Law</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Legal Documents (PDF/TXT)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:file-document-multiple" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload legal documents</div>
                <div className="text-sm text-gray-400 mt-1">PDF, DOCX, TXT - umowy, wyroki, opinie prawne</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Q&A Pairs for Legal Questions</label>
              <textarea
                className="w-full px-4 py-3 bg-black/30 border border-white/20 rounded-lg text-white text-sm focus:border-cyan-500 focus:outline-none font-mono"
                rows={8}
                placeholder={`Question: Jakie są wymogi formalne umowy sprzedaży?
Answer: Zgodnie z art. 158 KC, umowa sprzedaży nieruchomości wymaga formy aktu notarialnego...

Question: Co to jest vacatio legis?
Answer: Vacatio legis to okres odroczenia wejścia w życie ustawy...`}
              />
            </div>

            <div className="bg-cyan-900/20 border border-cyan-500/30 rounded-lg p-4">
              <div className="flex gap-2 text-cyan-400 text-sm">
                <Icon icon="mdi:shield-check" width={20} className="flex-shrink-0 mt-0.5" />
                <div>
                  <strong>UWAGA:</strong> Upewnij się, że dokumenty nie zawierają danych wrażliwych klientów (RODO).
                  Zanonimizuj dane przed uploadem.
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Sentiment Analysis Training */}
      {trainingType === "sentiment" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Sentiment Training Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Data Source</label>
              <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-blue-500 focus:outline-none">
                <option>Product Reviews</option>
                <option>Social Media Posts</option>
                <option>Customer Feedback</option>
                <option>Survey Responses</option>
                <option>Comments</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Labeled Text Data (CSV/JSON)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:table" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload labeled sentiment data</div>
                <div className="text-sm text-gray-400 mt-1">CSV with columns: text, sentiment (positive/negative/neutral)</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Sample Format Preview</label>
              <div className="bg-black/20 rounded-lg p-4 font-mono text-xs text-gray-300 overflow-x-auto">
                text,sentiment<br />
                "Produkt świetny, polecam!",positive<br />
                "Rozczarowanie, słaba jakość",negative<br />
                "Przeciętny, nic specjalnego",neutral
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Number of Classes</label>
              <select className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-blue-500 focus:outline-none">
                <option>3 (Positive, Negative, Neutral)</option>
                <option>2 (Positive, Negative)</option>
                <option>5 (Very Positive, Positive, Neutral, Negative, Very Negative)</option>
              </select>
            </div>
          </div>
        </div>
      )}

      {/* Text Summarization Training */}
      {trainingType === "summary" && (
        <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
          <h3 className="text-xl font-bold text-white mb-4">Summarization Training Dataset</h3>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Document-Summary Pairs (JSON/CSV)</label>
              <div className="border-2 border-dashed border-white/20 rounded-lg p-8 text-center hover:border-white/40 transition cursor-pointer">
                <Icon icon="mdi:file-compare" width={48} className="text-gray-400 mx-auto mb-2" />
                <div className="text-white font-medium">Upload document-summary pairs</div>
                <div className="text-sm text-gray-400 mt-1">Each row: full_text, summary</div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Example Format</label>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <div className="text-xs text-gray-400 mb-2">Full Document:</div>
                  <textarea
                    className="w-full px-3 py-2 bg-black/30 border border-white/20 rounded-lg text-white text-xs focus:border-teal-500 focus:outline-none"
                    rows={6}
                    placeholder="W dniu dzisiejszym odbyło się posiedzenie zarządu spółki, na którym omówiono wyniki finansowe za trzeci kwartał..."
                    readOnly
                  />
                </div>
                <div>
                  <div className="text-xs text-gray-400 mb-2">Summary:</div>
                  <textarea
                    className="w-full px-3 py-2 bg-black/30 border border-white/20 rounded-lg text-white text-xs focus:border-teal-500 focus:outline-none"
                    rows={6}
                    placeholder="Zarząd omówił wyniki Q3 i zaplanował działania na Q4."
                    readOnly
                  />
                </div>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-300 mb-2">Summary Length Target</label>
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs text-gray-400 mb-1">Min Words</label>
                  <input
                    type="number"
                    defaultValue={20}
                    className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-teal-500 focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs text-gray-400 mb-1">Max Words</label>
                  <input
                    type="number"
                    defaultValue={100}
                    className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-teal-500 focus:outline-none"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Training Configuration */}
      <div className="bg-white/5 backdrop-blur-lg rounded-xl border border-white/10 p-6">
        <h3 className="text-xl font-bold text-white mb-4">Konfiguracja</h3>
        <div className="grid grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Epochs</label>
            <input
              type="number"
              defaultValue={5}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-cyan-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Batch Size</label>
            <input
              type="number"
              defaultValue={8}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-cyan-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-300 mb-2">Learning Rate</label>
            <input
              type="number"
              step="0.00001"
              defaultValue={0.00005}
              className="w-full px-4 py-2 bg-black/30 border border-white/20 rounded-lg text-white focus:border-cyan-500 focus:outline-none"
            />
          </div>
        </div>
      </div>

      {/* Start Button */}
      <button className="w-full px-6 py-4 bg-gradient-to-r from-cyan-600 to-blue-600 text-white rounded-lg font-bold text-lg hover:opacity-90 transition flex items-center justify-center gap-2">
        <Icon icon="mdi:play" width={24} />
        Start Maat Training
      </button>
    </div>
  );
};

