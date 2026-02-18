"use client";

import { useEffect, useState } from "react";
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import { TrendingUp, DollarSign, Calendar, FileText } from "lucide-react";

interface ChartData {
  monthlyRevenue: Array<{ month: string; revenue: number }>;
  dailyRevenue: Array<{ date: string; revenue: number }>;
  paymentMethods: Array<{ name: string; value: number }>;
  statusDistribution: Array<{ name: string; value: number }>;
}

const COLORS = ["#eb520a", "#f6823c", "#fdb076", "#fed0a8", "#f8f3e7"];

export default function AccountingCharts() {
  const [data, setData] = useState<ChartData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchChartData();
  }, []);

  const fetchChartData = async () => {
    try {
      const res = await fetch("/api/accounting/charts");
      const chartData = await res.json();
      setData(chartData);
    } catch (error) {
      console.error("Error fetching chart data:", error);
    } finally {
      setLoading(false);
    }
  };

  if (loading || !data) {
    return (
      <div className="marble-card p-6">
        <div className="text-center text-ivory-100/60">Ładowanie wykresów...</div>
      </div>
    );
  }

  return (
    <div className="space-y-6 mb-8">
      {/* Revenue Trends */}
      <div className="grid gap-6 md:grid-cols-2">
        <div className="marble-card p-6">
          <div className="flex items-center gap-2 mb-4">
            <TrendingUp className="h-5 w-5 text-ember-400" />
            <h3 className="text-lg font-semibold text-ivory-100">Przychód miesięczny</h3>
          </div>
          <ResponsiveContainer width="100%" height={300}>
            <LineChart data={data.monthlyRevenue}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f8f3e7/20" />
              <XAxis
                dataKey="month"
                stroke="#f8f3e7/60"
                style={{ fontSize: "12px" }}
              />
              <YAxis
                stroke="#f8f3e7/60"
                style={{ fontSize: "12px" }}
                tickFormatter={(value) => `${(value / 1000).toFixed(0)}k`}
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: "#171717",
                  border: "1px solid #f8f3e7/20",
                  borderRadius: "8px",
                  color: "#f8f3e7",
                }}
                formatter={(value: number) => [
                  `${value.toLocaleString("pl-PL", {
                    style: "currency",
                    currency: "PLN",
                  })}`,
                  "Przychód",
                ]}
              />
              <Line
                type="monotone"
                dataKey="revenue"
                stroke="#eb520a"
                strokeWidth={2}
                dot={{ fill: "#eb520a", r: 4 }}
                activeDot={{ r: 6 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

        <div className="marble-card p-6">
          <div className="flex items-center gap-2 mb-4">
            <Calendar className="h-5 w-5 text-ember-400" />
            <h3 className="text-lg font-semibold text-ivory-100">Przychód dzienny (ostatnie 30 dni)</h3>
          </div>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={data.dailyRevenue}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f8f3e7/20" />
              <XAxis
                dataKey="date"
                stroke="#f8f3e7/60"
                style={{ fontSize: "11px" }}
                angle={-45}
                textAnchor="end"
                height={80}
              />
              <YAxis
                stroke="#f8f3e7/60"
                style={{ fontSize: "12px" }}
                tickFormatter={(value) => `${(value / 1000).toFixed(0)}k`}
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: "#171717",
                  border: "1px solid #f8f3e7/20",
                  borderRadius: "8px",
                  color: "#f8f3e7",
                }}
                formatter={(value: number) => [
                  `${value.toLocaleString("pl-PL", {
                    style: "currency",
                    currency: "PLN",
                  })}`,
                  "Przychód",
                ]}
              />
              <Bar dataKey="revenue" fill="#eb520a" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Payment Methods & Status Distribution */}
      <div className="grid gap-6 md:grid-cols-2">
        <div className="marble-card p-6">
          <div className="flex items-center gap-2 mb-4">
            <DollarSign className="h-5 w-5 text-ember-400" />
            <h3 className="text-lg font-semibold text-ivory-100">Metody płatności</h3>
          </div>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={data.paymentMethods}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) =>
                  `${name} ${((percent ?? 0) * 100).toFixed(0)}%`
                }
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {data.paymentMethods.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip
                contentStyle={{
                  backgroundColor: "#171717",
                  border: "1px solid #f8f3e7/20",
                  borderRadius: "8px",
                  color: "#f8f3e7",
                }}
                formatter={(value: number) => [
                  `${value.toLocaleString("pl-PL", {
                    style: "currency",
                    currency: "PLN",
                  })}`,
                  "Kwota",
                ]}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>

        <div className="marble-card p-6">
          <div className="flex items-center gap-2 mb-4">
            <FileText className="h-5 w-5 text-ember-400" />
            <h3 className="text-lg font-semibold text-ivory-100">Status faktur</h3>
          </div>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={data.statusDistribution}
                cx="50%"
                cy="50%"
                labelLine={false}
                label={({ name, percent }) =>
                  `${name} ${((percent ?? 0) * 100).toFixed(0)}%`
                }
                outerRadius={80}
                fill="#8884d8"
                dataKey="value"
              >
                {data.statusDistribution.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip
                contentStyle={{
                  backgroundColor: "#171717",
                  border: "1px solid #f8f3e7/20",
                  borderRadius: "8px",
                  color: "#f8f3e7",
                }}
                formatter={(value: number) => [`${value}`, "Liczba"]}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}

