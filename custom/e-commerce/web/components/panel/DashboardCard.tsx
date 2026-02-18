"use client";

import { LucideIcon } from "lucide-react";
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";

interface ChartDataPoint {
  date: string;
  value: number;
  comparisonValue?: number;
}

interface DashboardCardProps {
  title: string;
  value: string | number;
  icon: LucideIcon;
  color: string;
  link?: string;
  chartData: ChartDataPoint[];
  chartType?: "line" | "area" | "bar";
  showComparison?: boolean;
  period: "day" | "month" | "year";
  subtitle?: string;
  isUsersCard?: boolean;
  usersStats?: {
    total: number;
    subscribed: number;
    socialAccounts: {
      youtube: number;
      facebook: number;
      instagram: number;
      meta: number;
      google: number;
      twitter: number;
      other: number;
    };
  };
}

export default function DashboardCard({
  title,
  value,
  icon: Icon,
  color,
  link,
  chartData,
  chartType = "area",
  showComparison = false,
  period,
  subtitle,
  isUsersCard = false,
  usersStats,
}: DashboardCardProps) {
  const formatXAxis = (date: string) => {
    if (period === "day") {
      return new Date(date).toLocaleDateString("pl-PL", { day: "2-digit", month: "2-digit" });
    } else if (period === "month") {
      return new Date(date).toLocaleDateString("pl-PL", { month: "short", year: "2-digit" });
    } else {
      return new Date(date).toLocaleDateString("pl-PL", { year: "numeric" });
    }
  };

  const ChartComponent = chartType === "line" ? LineChart : chartType === "bar" ? BarChart : AreaChart;
  const DataComponent = chartType === "line" ? Line : chartType === "bar" ? Bar : Area;

  // Map color classes to hex values
  const getColorHex = (colorClass: string): string => {
    const colorMap: Record<string, string> = {
      "bg-blue-600": "#2563eb",
      "bg-green-600": "#16a34a",
      "bg-purple-600": "#9333ea",
      "bg-yellow-600": "#ca8a04",
      "bg-red-600": "#dc2626",
      "bg-indigo-600": "#4f46e5",
      "bg-pink-600": "#db2777",
      "bg-orange-600": "#ea580c",
      "bg-teal-600": "#0d9488",
      "bg-amber-600": "#d97706",
      "bg-pink-500": "#ec4899",
      "bg-orange-500": "#f97316",
      "bg-teal-500": "#14b8a6",
    };
    return colorMap[colorClass] || "#6b7280";
  };

  const colorHex = getColorHex(color);

  return (
    <div className="bg-white rounded-xl p-6 shadow-sm hover:shadow-md transition-all duration-300 border border-gray-200">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className={`${color} p-3 rounded-lg text-white`}>
          <Icon className="w-6 h-6" />
        </div>
        {link && (
          <a
            href={link}
            className="text-sm text-gray-500 hover:text-gray-700 transition-colors"
          >
            View →
          </a>
        )}
      </div>

      {/* Value */}
      <div className="mb-4">
        <h3 className="text-2xl font-bold text-gray-900 mb-1">{value}</h3>
        <p className="text-gray-600 text-sm">{title}</p>
        {subtitle && (
          <p className="text-gray-500 text-xs mt-2">{subtitle}</p>
        )}
        {isUsersCard && usersStats && (
          <div className="mt-3 space-y-2">
            <div className="flex items-center justify-between text-xs">
              <span className="text-gray-600">Subskrybuje:</span>
              <span className="font-semibold text-gray-900">{usersStats.subscribed}</span>
            </div>
            <div className="grid grid-cols-2 gap-2 text-xs">
              {usersStats.socialAccounts.youtube > 0 && (
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">YouTube:</span>
                  <span className="font-semibold text-gray-900">{usersStats.socialAccounts.youtube}</span>
                </div>
              )}
              {usersStats.socialAccounts.meta > 0 && (
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">Meta/Facebook:</span>
                  <span className="font-semibold text-gray-900">{usersStats.socialAccounts.meta}</span>
                </div>
              )}
              {usersStats.socialAccounts.instagram > 0 && (
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">Instagram:</span>
                  <span className="font-semibold text-gray-900">{usersStats.socialAccounts.instagram}</span>
                </div>
              )}
              {usersStats.socialAccounts.twitter > 0 && (
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">Twitter:</span>
                  <span className="font-semibold text-gray-900">{usersStats.socialAccounts.twitter}</span>
                </div>
              )}
              {usersStats.socialAccounts.google > 0 && (
                <div className="flex items-center justify-between">
                  <span className="text-gray-600">Google:</span>
                  <span className="font-semibold text-gray-900">{usersStats.socialAccounts.google}</span>
                </div>
              )}
            </div>
          </div>
        )}
      </div>

      {/* Chart */}
      <div className="h-48 mt-4">
        <ResponsiveContainer width="100%" height="100%">
          <ChartComponent data={chartData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
            <XAxis
              dataKey="date"
              tickFormatter={formatXAxis}
              stroke="#6b7280"
              style={{ fontSize: "10px" }}
            />
            <YAxis
              stroke="#6b7280"
              style={{ fontSize: "10px" }}
              tickFormatter={(value) => {
                if (value >= 1000) return `${(value / 1000).toFixed(1)}k`;
                return value.toString();
              }}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: "#fff",
                border: "1px solid #e5e7eb",
                borderRadius: "8px",
                fontSize: "12px",
              }}
              labelFormatter={(label) => formatXAxis(label)}
              formatter={(value: number) => [
                value.toLocaleString("pl-PL"),
                title,
              ]}
            />
            <DataComponent
              type="monotone"
              dataKey="value"
              stroke={colorHex}
              fill={colorHex}
              fillOpacity={chartType === "area" ? 0.3 : 1}
              strokeWidth={2}
            />
            {showComparison && (
              <DataComponent
                type="monotone"
                dataKey="comparisonValue"
                stroke="#9ca3af"
                fill="#9ca3af"
                fillOpacity={0.2}
                strokeWidth={2}
                strokeDasharray="5 5"
              />
            )}
          </ChartComponent>
        </ResponsiveContainer>
      </div>
    </div>
  );
}

