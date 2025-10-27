'use client';
import { useState } from 'react';

export default function MaatUI() {
  const [uploadedDoc, setUploadedDoc] = useState<File | null>(null);
  const [analysis, setAnalysis] = useState<any>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [docText, setDocText] = useState('');

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setUploadedDoc(e.target.files[0]);
    }
  };

  const handleAnalyze = async () => {
    if (!uploadedDoc && !docText.trim()) {
      alert('Wprowadź tekst lub wgraj dokument!');
      return;
    }

    setIsAnalyzing(true);
    try {
      await new Promise((resolve) => setTimeout(resolve, 2500));

      setAnalysis({
        documentType: 'Contract Agreement',
        language: 'Polish',
        sentiment: {
          score: 0.65,
          label: 'Neutral-Positive',
        },
        risks: [
          { type: 'High', description: 'Brak klauzuli o odpowiedzialności', severity: 8 },
          { type: 'Medium', description: 'Niejasne warunki płatności', severity: 5 },
          { type: 'Low', description: 'Brak daty końcowej umowy', severity: 3 },
        ],
        clauses: [
          { id: 1, title: '§1 Strony umowy', status: 'complete', risk: 'low' },
          { id: 2, title: '§2 Przedmiot umowy', status: 'complete', risk: 'low' },
          { id: 3, title: '§3 Wynagrodzenie', status: 'incomplete', risk: 'medium' },
          { id: 4, title: '§4 Odpowiedzialność', status: 'missing', risk: 'high' },
          { id: 5, title: '§5 Postanowienia końcowe', status: 'complete', risk: 'low' },
        ],
        entities: [
          { type: 'Organization', value: 'ABC Sp. z o.o.', count: 5 },
          { type: 'Person', value: 'Jan Kowalski', count: 3 },
          { type: 'Date', value: '2025-01-15', count: 2 },
          { type: 'Money', value: '50,000 PLN', count: 4 },
        ],
        compliance: {
          gdpr: { status: 'partial', score: 65 },
          rodo: { status: 'complete', score: 90 },
          commercial: { status: 'complete', score: 85 },
        },
      });
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setIsAnalyzing(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-blue-900/20 via-black to-indigo-900/20 text-white p-4">
      {/* Header */}
      <div className="max-w-7xl mx-auto mb-6">
        <div className="bg-gradient-to-r from-blue-900/30 to-indigo-900/30 rounded-2xl p-6 border border-blue-500/30">
          <div className="flex items-center gap-4">
            <div className="text-6xl">⚖️</div>
            <div>
              <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-400 via-indigo-500 to-purple-600 bg-clip-text text-transparent">
                Maat - Bogini Sprawiedliwości
              </h1>
              <p className="text-sm text-gray-400 mt-1">Mistral-13B • XLM-RoBERTa • Donut</p>
              <div className="flex gap-4 mt-2 text-xs text-blue-400">
                <span>✓ Legal Analysis</span>
                <span>✓ Contract Review</span>
                <span>✓ Compliance Check</span>
                <span>✓ Risk Assessment</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Input Area */}
        <div className="space-y-4">
          {/* Upload Section */}
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
            <h3 className="text-lg font-bold mb-4 text-blue-400">Document Input</h3>

            <div className="space-y-4">
              {/* File Upload */}
              <div>
                <label className="block text-sm font-semibold mb-2">Upload Document</label>
                <label className="block cursor-pointer">
                  <div className="border-2 border-dashed border-gray-600 rounded-lg p-6 text-center hover:border-blue-500 transition-colors">
                    {uploadedDoc ? (
                      <div>
                        <div className="text-4xl mb-2">📄</div>
                        <p className="text-sm text-blue-400 font-semibold">{uploadedDoc.name}</p>
                        <p className="text-xs text-gray-500 mt-1">{(uploadedDoc.size / 1024).toFixed(2)} KB</p>
                      </div>
                    ) : (
                      <div>
                        <div className="text-4xl mb-2 opacity-50">📄</div>
                        <p className="text-gray-400 text-sm">Click to upload</p>
                        <p className="text-xs text-gray-600 mt-1">PDF, DOCX, TXT</p>
                      </div>
                    )}
                  </div>
                  <input type="file" onChange={handleFileUpload} accept=".pdf,.doc,.docx,.txt" className="hidden" />
                </label>
              </div>

              {/* Text Input */}
              <div>
                <label className="block text-sm font-semibold mb-2">Or Paste Text</label>
                <textarea
                  value={docText}
                  onChange={(e) => setDocText(e.target.value)}
                  placeholder="Wklej treść dokumentu prawnego..."
                  className="w-full bg-gray-800 text-white rounded-lg px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 min-h-[200px] font-mono"
                />
              </div>

              {/* Analyze Button */}
              <button
                onClick={handleAnalyze}
                disabled={isAnalyzing}
                className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 disabled:from-gray-700 disabled:to-gray-800 text-white py-3 rounded-lg font-bold transition-all disabled:cursor-not-allowed"
              >
                {isAnalyzing ? '⏳ Analyzing...' : '⚖️ Analyze Document'}
              </button>
            </div>
          </div>
        </div>

        {/* Analysis Results */}
        <div className="space-y-4">
          {isAnalyzing ? (
            <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6 h-full flex items-center justify-center">
              <div className="text-center">
                <div className="text-6xl mb-4 animate-pulse">⚖️</div>
                <p className="text-xl font-bold text-blue-400">Maat analizuje dokument...</p>
                <p className="text-sm text-gray-400 mt-2">Wykorzystuję XLM-RoBERTa i Donut</p>
              </div>
            </div>
          ) : analysis ? (
            <>
              {/* Document Info */}
              <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
                <h3 className="text-lg font-bold mb-4 text-blue-400">Document Overview</h3>
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <div className="text-gray-400 text-xs mb-1">Type</div>
                    <div className="font-semibold">{analysis.documentType}</div>
                  </div>
                  <div>
                    <div className="text-gray-400 text-xs mb-1">Language</div>
                    <div className="font-semibold">{analysis.language}</div>
                  </div>
                  <div>
                    <div className="text-gray-400 text-xs mb-1">Sentiment</div>
                    <div className="font-semibold text-green-400">{analysis.sentiment.label}</div>
                  </div>
                  <div>
                    <div className="text-gray-400 text-xs mb-1">Risk Level</div>
                    <div className="font-semibold text-yellow-400">Medium</div>
                  </div>
                </div>
              </div>

              {/* Risk Assessment */}
              <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
                <h3 className="text-lg font-bold mb-4 text-blue-400">Risk Assessment</h3>
                <div className="space-y-3">
                  {analysis.risks.map((risk: any, idx: number) => (
                    <div
                      key={idx}
                      className={`p-3 rounded-lg border ${
                        risk.type === 'High'
                          ? 'bg-red-900/20 border-red-500/30'
                          : risk.type === 'Medium'
                            ? 'bg-yellow-900/20 border-yellow-500/30'
                            : 'bg-green-900/20 border-green-500/30'
                      }`}
                    >
                      <div className="flex justify-between items-start mb-2">
                        <span
                          className={`text-xs px-2 py-1 rounded font-semibold ${
                            risk.type === 'High'
                              ? 'bg-red-600'
                              : risk.type === 'Medium'
                                ? 'bg-yellow-600'
                                : 'bg-green-600'
                          }`}
                        >
                          {risk.type} Risk
                        </span>
                        <span className="text-sm font-bold">{risk.severity}/10</span>
                      </div>
                      <p className="text-sm">{risk.description}</p>
                    </div>
                  ))}
                </div>
              </div>

              {/* Clauses */}
              <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
                <h3 className="text-lg font-bold mb-4 text-blue-400">Contract Clauses</h3>
                <div className="space-y-2">
                  {analysis.clauses.map((clause: any) => (
                    <div
                      key={clause.id}
                      className="bg-gray-800 rounded-lg p-3 border border-gray-700 flex justify-between items-center"
                    >
                      <div className="flex-1">
                        <div className="text-sm font-semibold">{clause.title}</div>
                      </div>
                      <div className="flex gap-2 items-center">
                        <span
                          className={`text-xs px-2 py-1 rounded ${
                            clause.status === 'complete'
                              ? 'bg-green-900/50 text-green-400'
                              : clause.status === 'incomplete'
                                ? 'bg-yellow-900/50 text-yellow-400'
                                : 'bg-red-900/50 text-red-400'
                          }`}
                        >
                          {clause.status}
                        </span>
                        <span
                          className={`w-2 h-2 rounded-full ${
                            clause.risk === 'high'
                              ? 'bg-red-500'
                              : clause.risk === 'medium'
                                ? 'bg-yellow-500'
                                : 'bg-green-500'
                          }`}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Compliance */}
              <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
                <h3 className="text-lg font-bold mb-4 text-blue-400">Compliance Check</h3>
                <div className="space-y-3">
                  {Object.entries(analysis.compliance).map(([key, val]: [string, any]) => (
                    <div key={key} className="bg-gray-800 rounded-lg p-3 border border-gray-700">
                      <div className="flex justify-between items-center mb-2">
                        <span className="text-sm font-semibold uppercase">{key}</span>
                        <span className="text-xl font-bold text-blue-400">{val.score}%</span>
                      </div>
                      <div className="w-full bg-gray-700 rounded-full h-2">
                        <div
                          className={`h-2 rounded-full ${
                            val.score >= 80
                              ? 'bg-gradient-to-r from-green-500 to-green-600'
                              : val.score >= 60
                                ? 'bg-gradient-to-r from-yellow-500 to-yellow-600'
                                : 'bg-gradient-to-r from-red-500 to-red-600'
                          }`}
                          style={{ width: `${val.score}%` }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Export */}
              <button className="w-full bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 text-white py-3 rounded-lg font-bold transition-all">
                📄 Export Legal Report
              </button>
            </>
          ) : (
            <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6 h-full flex items-center justify-center">
              <div className="text-center">
                <div className="text-6xl mb-4 opacity-50">⚖️</div>
                <p className="text-gray-400">Upload or paste a legal document</p>
                <p className="text-sm text-gray-600 mt-2">Maat będzie sędzią sprawiedliwości</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Footer */}
      <div className="max-w-7xl mx-auto mt-6 text-center text-xs text-gray-500">
        𓆄 Maat Demo Interface • Powered by XLM-RoBERTa & Donut • Demo Mode • Not legal advice
      </div>
    </div>
  );
}
