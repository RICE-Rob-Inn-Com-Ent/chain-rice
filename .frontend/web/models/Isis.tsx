'use client';
import { useState } from 'react';

export default function IsisUI() {
  const [uploadedImage, setUploadedImage] = useState<string | null>(null);
  const [analysis, setAnalysis] = useState<any>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [activeTab, setActiveTab] = useState<'upload' | 'dicom' | 'xray' | 'mri'>('upload');

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      const reader = new FileReader();
      reader.onload = (event) => {
        setUploadedImage(event.target?.result as string);
      };
      reader.readAsDataURL(e.target.files[0]);
    }
  };

  const handleAnalyze = async () => {
    if (!uploadedImage) {
      alert('Najpierw wgraj obraz medyczny!');
      return;
    }

    setIsAnalyzing(true);
    try {
      // Symulacja analizy
      await new Promise((resolve) => setTimeout(resolve, 2500));
      setAnalysis({
        confidence: 87.5,
        findings: [
          { type: 'Normal', probability: 65, severity: 'low' },
          { type: 'Potential anomaly', probability: 25, severity: 'medium' },
          { type: 'Artifact detected', probability: 10, severity: 'low' },
        ],
        recommendations: [
          'Image quality is good for analysis',
          'Consider follow-up scan in 6 months',
          'No immediate concerns detected',
        ],
        regions: [
          { name: 'Region A', status: 'Normal', confidence: 92 },
          { name: 'Region B', status: 'Attention', confidence: 78 },
          { name: 'Region C', status: 'Normal', confidence: 95 },
        ],
      });
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setIsAnalyzing(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-purple-900/20 via-black to-pink-900/20 text-white p-4">
      {/* Header */}
      <div className="max-w-7xl mx-auto mb-6">
        <div className="bg-gradient-to-r from-purple-900/30 to-pink-900/30 rounded-2xl p-6 border border-purple-500/30">
          <div className="flex items-center gap-4">
            <div className="text-6xl">✨</div>
            <div>
              <h1 className="text-3xl font-bold bg-gradient-to-r from-purple-400 via-pink-500 to-rose-600 bg-clip-text text-transparent">
                Isis - Bogini Uzdrawiania
              </h1>
              <p className="text-sm text-gray-400 mt-1">Monai • Mistral-13B • LLaVa-13B</p>
              <div className="flex gap-4 mt-2 text-xs text-purple-400">
                <span>✓ Medical Image Analysis</span>
                <span>✓ DICOM Support</span>
                <span>✓ AI Diagnosis Support</span>
                <span>✓ Report Generation</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="max-w-7xl mx-auto grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Upload & Preview */}
        <div className="space-y-4">
          {/* Image Type Selector */}
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-4">
            <h3 className="text-lg font-bold mb-3 text-purple-400">Image Type</h3>
            <div className="grid grid-cols-4 gap-2">
              {[
                { id: 'upload', label: 'Upload', icon: '📤' },
                { id: 'dicom', label: 'DICOM', icon: '🏥' },
                { id: 'xray', label: 'X-Ray', icon: '🦴' },
                { id: 'mri', label: 'MRI', icon: '🧠' },
              ].map((tab) => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id as any)}
                  className={`p-2 rounded-lg text-xs font-semibold transition-all ${
                    activeTab === tab.id
                      ? 'bg-gradient-to-r from-purple-600 to-pink-600 text-white'
                      : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
                  }`}
                >
                  {tab.icon} {tab.label}
                </button>
              ))}
            </div>
          </div>

          {/* Image Preview */}
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
            <h3 className="text-lg font-bold mb-4 text-purple-400">Medical Image</h3>

            {uploadedImage ? (
              <div className="space-y-4">
                <div className="bg-black rounded-lg overflow-hidden border-2 border-purple-500/30">
                  <img src={uploadedImage} alt="Medical" className="w-full h-96 object-contain" />
                </div>
                <div className="flex gap-2">
                  <button
                    onClick={handleAnalyze}
                    disabled={isAnalyzing}
                    className="flex-1 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 disabled:from-gray-700 disabled:to-gray-800 text-white py-3 rounded-lg font-bold transition-all disabled:cursor-not-allowed"
                  >
                    {isAnalyzing ? '⏳ Analyzing...' : '🔬 Analyze'}
                  </button>
                  <button
                    onClick={() => setUploadedImage(null)}
                    className="px-4 bg-red-600 hover:bg-red-700 text-white rounded-lg font-semibold transition-all"
                  >
                    🗑️
                  </button>
                </div>
              </div>
            ) : (
              <label className="block cursor-pointer">
                <div className="border-2 border-dashed border-gray-600 rounded-lg p-12 text-center hover:border-purple-500 transition-colors">
                  <div className="text-6xl mb-4 opacity-50">✨</div>
                  <p className="text-gray-400 mb-2">Click to upload medical image</p>
                  <p className="text-xs text-gray-600">Supports: JPG, PNG, DICOM</p>
                </div>
                <input type="file" onChange={handleImageUpload} accept="image/*,.dcm" className="hidden" />
              </label>
            )}
          </div>
        </div>

        {/* Analysis Results */}
        <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
          <h3 className="text-lg font-bold mb-4 text-purple-400">Analysis Results</h3>

          {isAnalyzing ? (
            <div className="flex items-center justify-center h-full">
              <div className="text-center">
                <div className="text-6xl mb-4 animate-pulse">✨</div>
                <p className="text-xl font-bold text-purple-400">Isis analizuje obraz...</p>
                <p className="text-sm text-gray-400 mt-2">Wykorzystuję Monai i LLaVa</p>
              </div>
            </div>
          ) : analysis ? (
            <div className="space-y-6">
              {/* Confidence Score */}
              <div className="bg-gradient-to-r from-purple-900/30 to-pink-900/30 rounded-lg p-4 border border-purple-500/30">
                <div className="flex justify-between items-center mb-2">
                  <span className="text-sm font-semibold">Confidence Score</span>
                  <span className="text-2xl font-bold text-purple-400">{analysis.confidence}%</span>
                </div>
                <div className="w-full bg-gray-700 rounded-full h-2">
                  <div
                    className="bg-gradient-to-r from-purple-500 to-pink-500 h-2 rounded-full transition-all"
                    style={{ width: `${analysis.confidence}%` }}
                  />
                </div>
              </div>

              {/* Findings */}
              <div>
                <h4 className="text-sm font-bold mb-3 text-purple-400">Findings</h4>
                <div className="space-y-2">
                  {analysis.findings.map((finding: any, idx: number) => (
                    <div key={idx} className="bg-gray-800 rounded-lg p-3 border border-gray-700">
                      <div className="flex justify-between items-center mb-1">
                        <span className="text-sm font-semibold">{finding.type}</span>
                        <span
                          className={`text-xs px-2 py-1 rounded ${
                            finding.severity === 'high'
                              ? 'bg-red-900/50 text-red-400'
                              : finding.severity === 'medium'
                                ? 'bg-yellow-900/50 text-yellow-400'
                                : 'bg-green-900/50 text-green-400'
                          }`}
                        >
                          {finding.severity}
                        </span>
                      </div>
                      <div className="w-full bg-gray-700 rounded-full h-1">
                        <div className="bg-purple-500 h-1 rounded-full" style={{ width: `${finding.probability}%` }} />
                      </div>
                      <div className="text-xs text-gray-400 mt-1">Probability: {finding.probability}%</div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Regions */}
              <div>
                <h4 className="text-sm font-bold mb-3 text-purple-400">Region Analysis</h4>
                <div className="space-y-2">
                  {analysis.regions.map((region: any, idx: number) => (
                    <div
                      key={idx}
                      className="flex justify-between items-center bg-gray-800 rounded-lg p-3 border border-gray-700"
                    >
                      <div>
                        <div className="text-sm font-semibold">{region.name}</div>
                        <div className="text-xs text-gray-400">{region.confidence}% confidence</div>
                      </div>
                      <span
                        className={`text-xs px-3 py-1 rounded-full font-semibold ${
                          region.status === 'Normal'
                            ? 'bg-green-900/50 text-green-400'
                            : 'bg-yellow-900/50 text-yellow-400'
                        }`}
                      >
                        {region.status}
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Recommendations */}
              <div>
                <h4 className="text-sm font-bold mb-3 text-purple-400">Recommendations</h4>
                <div className="space-y-2">
                  {analysis.recommendations.map((rec: string, idx: number) => (
                    <div key={idx} className="flex gap-2 text-sm text-gray-300">
                      <span className="text-purple-400">•</span>
                      <span>{rec}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Export Button */}
              <button className="w-full bg-gradient-to-r from-green-600 to-green-700 hover:from-green-700 hover:to-green-800 text-white py-3 rounded-lg font-bold transition-all">
                📄 Export Report
              </button>
            </div>
          ) : (
            <div className="flex items-center justify-center h-full text-center">
              <div>
                <div className="text-6xl mb-4 opacity-50">✨</div>
                <p className="text-gray-400">Upload and analyze a medical image</p>
                <p className="text-sm text-gray-600 mt-2">Isis czeka na Twój obraz</p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Footer */}
      <div className="max-w-7xl mx-auto mt-6 text-center text-xs text-gray-500">
        𓇋𓇋 Isis Demo Interface • Powered by Monai & LLaVa • Demo Mode • Not for medical diagnosis
      </div>
    </div>
  );
}
