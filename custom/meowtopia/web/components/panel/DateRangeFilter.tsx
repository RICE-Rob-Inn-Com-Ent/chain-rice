"use client";

import { useState } from "react";
import { Calendar, CalendarDays, X } from "lucide-react";

interface DateRangeFilterProps {
  onDateRangeChange: (range: {
    start: Date;
    end: Date;
    comparisonStart?: Date;
    comparisonEnd?: Date;
  }) => void;
  onPeriodChange: (period: "day" | "month" | "year") => void;
  defaultPeriod?: "day" | "month" | "year";
}

export default function DateRangeFilter({
  onDateRangeChange,
  onPeriodChange,
  defaultPeriod = "month",
}: DateRangeFilterProps) {
  const [period, setPeriod] = useState<"day" | "month" | "year">(defaultPeriod);
  const [startDate, setStartDate] = useState<string>(
    new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString().split("T")[0]
  );
  const [endDate, setEndDate] = useState<string>(
    new Date().toISOString().split("T")[0]
  );
  const [showComparison, setShowComparison] = useState(false);
  const [comparisonStartDate, setComparisonStartDate] = useState<string>("");
  const [comparisonEndDate, setComparisonEndDate] = useState<string>("");

  const handlePeriodChange = (newPeriod: "day" | "month" | "year") => {
    setPeriod(newPeriod);
    onPeriodChange(newPeriod);
    updateDateRange();
  };

  const updateDateRange = () => {
    const start = new Date(startDate);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    const range: {
      start: Date;
      end: Date;
      comparisonStart?: Date;
      comparisonEnd?: Date;
    } = {
      start,
      end,
    };

    if (showComparison && comparisonStartDate && comparisonEndDate) {
      range.comparisonStart = new Date(comparisonStartDate);
      range.comparisonEnd = new Date(comparisonEndDate);
      range.comparisonEnd.setHours(23, 59, 59, 999);
    }

    onDateRangeChange(range);
  };

  const handleStartDateChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setStartDate(e.target.value);
    setTimeout(updateDateRange, 100);
  };

  const handleEndDateChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setEndDate(e.target.value);
    setTimeout(updateDateRange, 100);
  };

  const handleComparisonToggle = (checked: boolean) => {
    setShowComparison(checked);
    if (!checked) {
      setComparisonStartDate("");
      setComparisonEndDate("");
    }
    setTimeout(updateDateRange, 100);
  };

  const handleComparisonStartChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setComparisonStartDate(e.target.value);
    setTimeout(updateDateRange, 100);
  };

  const handleComparisonEndChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setComparisonEndDate(e.target.value);
    setTimeout(updateDateRange, 100);
  };

  return (
    <div className="bg-white rounded-xl p-4 shadow-sm border border-gray-200 mb-6">
      <div className="flex flex-col lg:flex-row gap-4 items-start lg:items-center">
        {/* Period Selector */}
        <div className="flex items-center gap-2">
          <CalendarDays className="w-5 h-5 text-gray-500" />
          <select
            value={period}
            onChange={(e) => handlePeriodChange(e.target.value as "day" | "month" | "year")}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white text-gray-800 cursor-pointer"
          >
            <option value="day">Dzień</option>
            <option value="month">Miesiąc</option>
            <option value="year">Rok</option>
          </select>
        </div>

        {/* Main Date Range */}
        <div className="flex items-center gap-2">
          <Calendar className="w-5 h-5 text-gray-500" />
          <input
            type="date"
            value={startDate}
            onChange={handleStartDateChange}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white text-gray-800"
          />
          <span className="text-gray-500">-</span>
          <input
            type="date"
            value={endDate}
            onChange={handleEndDateChange}
            min={startDate}
            className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white text-gray-800"
          />
        </div>

        {/* Comparison Range Toggle */}
        <div className="flex items-center gap-2">
          <label className="flex items-center gap-2 cursor-pointer">
            <input
              type="checkbox"
              checked={showComparison}
              onChange={(e) => handleComparisonToggle(e.target.checked)}
              className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
            />
            <span className="text-sm text-gray-700">Zakres porównawczy</span>
          </label>
        </div>

        {/* Comparison Date Range */}
        {showComparison && (
          <div className="flex items-center gap-2">
            <span className="text-sm text-gray-500">Porównaj:</span>
            <input
              type="date"
              value={comparisonStartDate}
              onChange={handleComparisonStartChange}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white text-gray-800"
            />
            <span className="text-gray-500">-</span>
            <input
              type="date"
              value={comparisonEndDate}
              onChange={handleComparisonEndChange}
              min={comparisonStartDate}
              className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white text-gray-800"
            />
          </div>
        )}
      </div>
    </div>
  );
}





































