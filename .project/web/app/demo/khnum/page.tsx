"use client";
import { useState } from "react";

export default function KhnumDemoPage() {
  const [selectedPeriod, setSelectedPeriod] = useState<"day" | "week" | "month" | "year">("month");
  const [uploadedData, setUploadedData] = useState<File | null>(null);
  const [analysis, setAnalysis] = useState<any>({
    revenue: 125340.5,
    expenses: 89234.2,
    profit: 36106.3,
    profitMargin: 28.8,
    trend: "up",
    forecasts: [
      { month: "Jan", actual: 120000, forecast: 115000 },
      { month: "Feb", actual: 125000, forecast: 128000 },
      { month: "Mar", actual: 130000, forecast: 132000 },
      { month: "Apr", actual: null, forecast: 135000 },
      { month: "May", actual: null, forecast: 140000 },
    ],
    categories: [
      { name: "Products", value: 45000, percentage: 36, color: "from-green-500 to-green-600" },
      { name: "Services", value: 38000, percentage: 30, color: "from-blue-500 to-blue-600" },
      { name: "Subscriptions", value: 28000, percentage: 22, color: "from-purple-500 to-purple-600" },
      { name: "Other", value: 14340, percentage: 12, color: "from-gray-500 to-gray-600" },
    ],
    recommendations: [
      { title: "Increase marketing budget", impact: "High", confidence: 85 },
      { title: "Optimize operational costs", impact: "Medium", confidence: 72 },
      { title: "Diversify revenue streams", impact: "High", confidence: 90 },
      { title: "Review pricing strategy", impact: "Medium", confidence: 68 },
    ],
    anomalies: [
      { date: "2025-03-15", description: "Unusual spike in expenses", severity: "medium" },
      { date: "2025-03-20", description: "Revenue below forecast", severity: "low" },
    ],
  });

  const handleFileUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files[0]) {
      setUploadedData(e.target.files[0]);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-green-900/20 via-black to-emerald-900/20 text-white p-4">
      {/* Header */}
      <div className="max-w-7xl mx-auto mb-6">
        <div className="bg-gradient-to-r from-green-900/30 to-emerald-900/30 rounded-2xl p-6 border border-green-500/30">
          <div className="flex items-center gap-4">
            <div className="text-6xl">💰</div>
            <div>
              <h1 className="text-3xl font-bold bg-gradient-to-r from-green-400 via-emerald-500 to-teal-600 bg-clip-text text-transparent">
                Khnum - Bóg Bogactwa
              </h1>
              <p className="text-sm text-gray-400 mt-1">Mistral-13B • PlotGPT-7B • RecBole</p>
              <div className="flex gap-4 mt-2 text-xs text-green-400">
                <span>✓ Financial Analysis</span>
                <span>✓ Forecasting</span>
                <span>✓ Anomaly Detection</span>
                <span>✓ Recommendations</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Dashboard */}
      <div className="max-w-7xl mx-auto space-y-6">
        {/* Controls */}
        <div className="flex justify-between items-center">
          <div className="flex gap-2">
            {(["day", "week", "month", "year"] as const).map((period) => (
              <button
                key={period}
                onClick={() => setSelectedPeriod(period)}
                className={`px-4 py-2 rounded-lg text-sm font-semibold transition-all ${
                  selectedPeriod === period
                    ? "bg-gradient-to-r from-green-600 to-emerald-600 text-white"
                    : "bg-gray-800 text-gray-400 hover:bg-gray-700"
                }`}
              >
                {period.charAt(0).toUpperCase() + period.slice(1)}
              </button>
            ))}
          </div>
          <label className="cursor-pointer">
            <div className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg font-semibold text-sm transition-all flex items-center gap-2">
              <span>📤</span>
              <span>Import Data</span>
            </div>
            <input type="file" onChange={handleFileUpload} accept=".csv,.xlsx,.json" className="hidden" />
          </label>
        </div>

        {/* Key Metrics */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            {
              label: "Revenue",
              value: `${analysis.revenue.toLocaleString()} PLN`,
              icon: "📈",
              color: "from-green-600 to-green-700",
              trend: "+12.5%",
            },
            {
              label: "Expenses",
              value: `${analysis.expenses.toLocaleString()} PLN`,
              icon: "📉",
              color: "from-red-600 to-red-700",
              trend: "+8.2%",
            },
            {
              label: "Profit",
              value: `${analysis.profit.toLocaleString()} PLN`,
              icon: "💵",
              color: "from-blue-600 to-blue-700",
              trend: "+23.1%",
            },
            {
              label: "Margin",
              value: `${analysis.profitMargin}%`,
              icon: "📊",
              color: "from-purple-600 to-purple-700",
              trend: "+2.3%",
            },
          ].map((metric, idx) => (
            <div key={idx} className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
              <div className="flex justify-between items-start mb-3">
                <span className="text-4xl">{metric.icon}</span>
                <span className="text-xs text-green-400 font-semibold">{metric.trend}</span>
              </div>
              <div className="text-sm text-gray-400 mb-1">{metric.label}</div>
              <div className={`text-2xl font-bold bg-gradient-to-r ${metric.color} bg-clip-text text-transparent`}>
                {metric.value}
              </div>
            </div>
          ))}
        </div>

        {/* Charts Row */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Forecast Chart */}
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
            <h3 className="text-lg font-bold mb-4 text-green-400">Revenue Forecast</h3>
            <div className="space-y-3">
              {analysis.forecasts.map((item: any, idx: number) => (
                <div key={idx} className="space-y-1">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-400">{item.month}</span>
                    <div className="flex gap-4">
                      {item.actual && <span className="text-green-400">{(item.actual / 1000).toFixed(0)}K</span>}
                      <span className="text-blue-400">{(item.forecast / 1000).toFixed(0)}K (forecast)</span>
                    </div>
                  </div>
                  <div className="flex gap-2">
                    {item.actual && (
                      <div className="flex-1 bg-gray-700 rounded-full h-2">
                        <div
                          className="bg-gradient-to-r from-green-500 to-green-600 h-2 rounded-full"
                          style={{ width: `${(item.actual / 150000) * 100}%` }}
                        />
                      </div>
                    )}
                    <div className="flex-1 bg-gray-700 rounded-full h-2">
                      <div
                        className="bg-gradient-to-r from-blue-500 to-blue-600 h-2 rounded-full"
                        style={{ width: `${(item.forecast / 150000) * 100}%` }}
                      />
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Category Breakdown */}
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
            <h3 className="text-lg font-bold mb-4 text-green-400">Revenue by Category</h3>
            <div className="space-y-4">
              {analysis.categories.map((cat: any, idx: number) => (
                <div key={idx}>
                  <div className="flex justify-between text-sm mb-2">
                    <span className="font-semibold">{cat.name}</span>
                    <span className="text-gray-400">
                      {cat.value.toLocaleString()} PLN ({cat.percentage}%)
                    </span>
                  </div>
                  <div className="w-full bg-gray-700 rounded-full h-3">
                    <div
                      className={`bg-gradient-to-r ${cat.color} h-3 rounded-full transition-all`}
                      style={{ width: `${cat.percentage}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Recommendations & Anomalies */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* AI Recommendations */}
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
            <h3 className="text-lg font-bold mb-4 text-green-400">💡 AI Recommendations</h3>
            <div className="space-y-3">
              {analysis.recommendations.map((rec: any, idx: number) => (
                <div key={idx} className="bg-gray-800 rounded-lg p-4 border border-gray-700">
                  <div className="flex justify-between items-start mb-2">
                    <div className="font-semibold text-sm">{rec.title}</div>
                    <span
                      className={`text-xs px-2 py-1 rounded font-semibold ${
                        rec.impact === "High"
                          ? "bg-green-600"
                          : rec.impact === "Medium"
                          ? "bg-yellow-600"
                          : "bg-gray-600"
                      }`}
                    >
                      {rec.impact}
                    </span>
                  </div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs text-gray-400">Confidence:</span>
                    <div className="flex-1 bg-gray-700 rounded-full h-1.5">
                      <div
                        className="bg-gradient-to-r from-green-500 to-emerald-500 h-1.5 rounded-full"
                        style={{ width: `${rec.confidence}%` }}
                      />
                    </div>
                    <span className="text-xs text-green-400 font-semibold">{rec.confidence}%</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Anomaly Detection */}
          <div className="bg-gray-900/80 backdrop-blur rounded-xl border border-gray-700 p-6">
            <h3 className="text-lg font-bold mb-4 text-yellow-400">⚠️ Anomaly Detection</h3>
            <div className="space-y-3">
              {analysis.anomalies.map((anomaly: any, idx: number) => (
                <div
                  key={idx}
                  className={`rounded-lg p-4 border ${
                    anomaly.severity === "high"
                      ? "bg-red-900/20 border-red-500/30"
                      : anomaly.severity === "medium"
                      ? "bg-yellow-900/20 border-yellow-500/30"
                      : "bg-blue-900/20 border-blue-500/30"
                  }`}
                >
                  <div className="flex justify-between items-start mb-2">
                    <span className="text-xs text-gray-400">{anomaly.date}</span>
                    <span
                      className={`text-xs px-2 py-1 rounded font-semibold ${
                        anomaly.severity === "high"
                          ? "bg-red-600"
                          : anomaly.severity === "medium"
                          ? "bg-yellow-600"
                          : "bg-blue-600"
                      }`}
                    >
                      {anomaly.severity}
                    </span>
                  </div>
                  <p className="text-sm">{anomaly.description}</p>
                </div>
              ))}
              <div className="text-center pt-2">
                <button className="text-sm text-green-400 hover:text-green-300 transition-colors font-semibold">
                  View All Anomalies →
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Export & Actions */}
        <div className="flex gap-4">
          <button className="flex-1 bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white py-3 rounded-lg font-bold transition-all">
            📊 Generate Full Report
          </button>
          <button className="flex-1 bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 text-white py-3 rounded-lg font-bold transition-all">
            💾 Export to Excel
          </button>
          <button className="flex-1 bg-gradient-to-r from-purple-600 to-purple-700 hover:from-purple-700 hover:to-purple-800 text-white py-3 rounded-lg font-bold transition-all">
            🔮 Run AI Analysis
          </button>
        </div>
      </div>

      {/* Footer */}
      <div className="max-w-7xl mx-auto mt-6 text-center text-xs text-gray-500">
        𓎛 Khnum Demo Interface • Powered by Mistral-13B & PlotGPT • Demo Mode • Not financial advice
      </div>
    </div>
  );
}
