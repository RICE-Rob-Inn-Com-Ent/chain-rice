/**
 * Komponent Dashboard Finansowy - Przegląd finansów
 * 
 * Ten komponent zapewnia kompleksowy przegląd finansów z wykresami,
 * statystykami i informacjami o nadchodzących płatnościach.
 * 
 * Funkcjonalności:
 * - Podstawowe statystyki finansowe
 * - Wykresy przychodów i wydatków
 * - Analiza kategorii
 * - Nadchodzące płatności
 * - Powiadomienia
 * - Szybkie akcje
 * 
 * @author Meowtopia Development Team
 * @version 1.0.0
 */

import React, { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Icon } from '@iconify/react';
import Button from '@/components/Button';
import Card from '@/components/Card';
import Table, { TableColumn } from '@/components/Table';
import { validateField, makeApiCall, formatCurrency, generateMockInvoices } from "../utils";
import type { Invoice, Payment, DashboardData, CategoryStats, TrendData } from "../types";
import AdminOnly from "../../../components/AdminOnly";
import { MESSAGES, STATUS_COLORS, PAYMENT_METHODS } from '../config';

// ============================================================================
// INTERFEJSY KOMPONENTU - Właściwości i stany lokalne
// ============================================================================

/**
 * Właściwości komponentu Dashboard
 */
interface DashboardProps {
  onInvoiceSelect?: (invoice: Invoice) => void;
  onPaymentSelect?: (payment: Payment) => void;
}

/**
 * Stan wykresów - które wykresy są wyświetlane
 */
interface ChartState {
  showIncomeChart: boolean;
  showExpenseChart: boolean;
  showCategoryChart: boolean;
  showPaymentMethodsChart: boolean;
}

// ============================================================================
// KOMPONENT DASHBOARD - Główny komponent dashboardu
// ============================================================================

/**
 * Komponent dashboardu finansowego
 * Wyświetla przegląd finansów z wykresami i statystykami
 */
const Dashboard: React.FC<DashboardProps> = ({
  onInvoiceSelect,
  onPaymentSelect
}) => {
  const navigate = useNavigate();
  
  // ============================================================================
  // STANY KOMPONENTU - Zarządzanie stanem aplikacji
  // ============================================================================
  
  /**
   * Dane dashboardu - pobierane z API
   */
  const [data, setData] = useState<DashboardData | null>(null);
  
  /**
   * Stany interfejsu użytkownika
   */
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [selectedPeriod, setSelectedPeriod] = useState<"month" | "quarter" | "year">("month");
  
  // ============================================================================
  // POBIERANIE DANYCH - Ładowanie danych dashboardu
  // ============================================================================
  
  /**
   * Pobieranie danych dashboardu przy montowaniu komponentu
   */
  useEffect(() => {
    // Simulate API call
    setTimeout(() => {
      const mockInvoices = generateMockInvoices(10);
      setData({
        summary: {
          totalIncome: 45230,
          totalExpenses: 23450,
          netIncome: 21780,
          unpaidInvoices: 8,
          overdueInvoices: 3,
        },
        recentTransactions: mockInvoices.slice(0, 5),
        topCategories: [
          { category: 'Żywność', amount: 8500, percentage: 25, count: 45 },
          { category: 'Transport', amount: 6200, percentage: 18, count: 32 },
          { category: 'Rozrywka', amount: 4800, percentage: 14, count: 28 },
          { category: 'Media', amount: 3200, percentage: 9, count: 12 },
        ],
        monthlyTrends: [
          { month: 'Sty', income: 42000, expenses: 38000, profit: 4000 },
          { month: 'Lut', income: 45000, expenses: 41000, profit: 4000 },
          { month: 'Mar', income: 48000, expenses: 44000, profit: 4000 },
          { month: 'Kwi', income: 52000, expenses: 46000, profit: 6000 },
        ],
      });
      setLoading(false);
    }, 1000);
  }, []);
  
  // ============================================================================
  // FUNKCJE POMOCNICZE - Formatowanie i obliczenia
  // ============================================================================
  
  /**
   * Formatowanie kwoty w PLN
   */
  const formatAmount = (amount: number): string => {
    return new Intl.NumberFormat("pl-PL", {
      style: "currency",
      currency: "PLN"
    }).format(amount);
  };
  
  /**
   * Formatowanie daty
   */
  const formatDate = (date: string): string => {
    return new Date(date).toLocaleDateString("pl-PL");
  };
  
  /**
   * Obliczenie procentu zmiany
   */
  const calculatePercentageChange = (current: number, previous: number): number => {
    if (previous === 0) return current > 0 ? 100 : 0;
    return ((current - previous) / previous) * 100;
  };
  
  /**
   * Pobieranie koloru dla trendu
   */
  const getTrendColor = (percentage: number): string => {
    if (percentage > 0) return "text-green-600";
    if (percentage < 0) return "text-red-600";
    return "text-gray-600";
  };
  
  /**
   * Pobieranie ikony trendu
   */
  const getTrendIcon = (percentage: number): string => {
    if (percentage > 0) return "↗";
    if (percentage < 0) return "↘";
    return "→";
  };
  
  /**
   * Pobieranie koloru dla statusu powiadomienia
   */
  const getNotificationColor = (priority: string): string => {
    switch (priority) {
      case "urgent": return "border-red-500 bg-red-50";
      case "high": return "border-orange-500 bg-orange-50";
      case "medium": return "border-yellow-500 bg-yellow-50";
      case "low": return "border-blue-500 bg-blue-50";
      default: return "border-gray-500 bg-gray-50";
    }
  };
  
  const recentColumns: TableColumn[] = [
    { key: 'number', label: 'Numer', render: (_, row) => (
      <button onClick={() => navigate(`/accounting/invoices/${row.id}`)} className="text-blue-600 hover:text-blue-800 font-medium">
        {row.number}
      </button>
    )},
    { key: 'clientSupplier', label: 'Klient/Dostawca' },
    { key: 'totalAmount', label: 'Kwota', align: 'right', render: (value) => formatCurrency(value) },
    { key: 'status', label: 'Status', align: 'center', render: (value) => (
      <span className={`px-2 py-1 rounded-full text-xs font-medium ${STATUS_COLORS[value as keyof typeof STATUS_COLORS]}`}>
        {MESSAGES[value as keyof typeof MESSAGES]}
      </span>
    )},
  ];
  
  // ============================================================================
  // RENDER - Wyświetlanie komponentu
  // ============================================================================
  
  if (loading && !data) {
    return (
      <AdminOnly>
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
            <p className="text-gray-600">Ładowanie dashboardu...</p>
          </div>
        </div>
      </AdminOnly>
    );
  }
  
  if (!data) {
    return (
      <AdminOnly>
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <div className="text-center">
            <h2 className="text-2xl font-bold text-gray-900 mb-2">Błąd ładowania danych</h2>
            <p className="text-gray-600 mb-4">Nie udało się załadować danych dashboardu.</p>
            <button
              onClick={() => {
                // Simulate API call
                setTimeout(() => {
                  const mockInvoices = generateMockInvoices(10);
                  setData({
                    summary: {
                      totalIncome: 45230,
                      totalExpenses: 23450,
                      netIncome: 21780,
                      unpaidInvoices: 8,
                      overdueInvoices: 3,
                    },
                    recentTransactions: mockInvoices.slice(0, 5),
                    topCategories: [
                      { category: 'Żywność', amount: 8500, percentage: 25, count: 45 },
                      { category: 'Transport', amount: 6200, percentage: 18, count: 32 },
                      { category: 'Rozrywka', amount: 4800, percentage: 14, count: 28 },
                      { category: 'Media', amount: 3200, percentage: 9, count: 12 },
                    ],
                    monthlyTrends: [
                      { month: 'Sty', income: 42000, expenses: 38000, profit: 4000 },
                      { month: 'Lut', income: 45000, expenses: 41000, profit: 4000 },
                      { month: 'Mar', income: 48000, expenses: 44000, profit: 4000 },
                      { month: 'Kwi', income: 52000, expenses: 46000, profit: 6000 },
                    ],
                  });
                  setLoading(false);
                }, 1000);
              }}
              className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700"
            >
              Spróbuj ponownie
            </button>
          </div>
        </div>
      </AdminOnly>
    );
  }
  
  return (
    <AdminOnly 
      fallbackMessage="Dashboard finansowy jest dostępny tylko dla administratorów."
      shouldRedirect={false}
    >
      <div className="min-h-screen bg-gray-50 py-8">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          {/* Nagłówek */}
          <div className="mb-8">
            <div className="flex justify-between items-center">
              <div>
                <h1 className="text-3xl font-bold text-gray-900">
                  Dashboard Finansowy
                </h1>
                <p className="mt-2 text-gray-600">
                  Przegląd finansów i statystyk
                </p>
              </div>
              <div className="flex space-x-3">
                <select
                  value={selectedPeriod}
                  onChange={(e) => setSelectedPeriod(e.target.value as "month" | "quarter" | "year")}
                  className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                >
                  <option value="month">Miesiąc</option>
                  <option value="quarter">Kwartał</option>
                  <option value="year">Rok</option>
                </select>
                <Button onClick={() => navigate("/accounting/invoices/new")} className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500" icon="mdi:plus">
                  Nowa Faktura
                </Button>
              </div>
            </div>
          </div>
          
          {/* Komunikaty */}
          {(error || success) && (
            <div className="mb-6">
              {error && (
                <div className="bg-red-50 border border-red-200 rounded-md p-4">
                  <div className="flex">
                    <div className="flex-shrink-0">
                      <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                      </svg>
                    </div>
                    <div className="ml-3">
                      <p className="text-sm text-red-800">{error}</p>
                    </div>
                  </div>
                </div>
              )}
              {success && (
                <div className="bg-green-50 border border-green-200 rounded-md p-4">
                  <div className="flex">
                    <div className="flex-shrink-0">
                      <svg className="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                      </svg>
                    </div>
                    <div className="ml-3">
                      <p className="text-sm text-green-800">{success}</p>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}
          
          {/* Podstawowe statystyki */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
            {/* Przychody */}
            <Card className="text-center">
              <div className="text-2xl font-bold text-green-600">{formatCurrency(data.summary.totalIncome)}</div>
              <div className="text-sm text-gray-600">Przychody (miesiąc)</div>
            </Card>
            
            {/* Wydatki */}
            <Card className="text-center">
              <div className="text-2xl font-bold text-red-600">{formatCurrency(data.summary.totalExpenses)}</div>
              <div className="text-sm text-gray-600">Wydatki (miesiąc)</div>
            </Card>
            
            {/* Zysk netto */}
            <Card className="text-center">
              <div className="text-2xl font-bold text-blue-600">{formatCurrency(data.summary.netIncome)}</div>
              <div className="text-sm text-gray-600">Zysk netto</div>
            </Card>
            
            {/* Faktury nieopłacone */}
            <Card className="text-center">
              <div className="text-2xl font-bold text-yellow-600">{data.summary.unpaidInvoices}</div>
              <div className="text-sm text-gray-600">Nieopłacone faktury</div>
            </Card>
          </div>
          
          {/* Wykresy i analizy */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
            {/* Ostatnie transakcje */}
            <Card title="Ostatnie transakcje">
              <Table columns={recentColumns} data={data.recentTransactions} emptyMessage="Brak transakcji" />
              <div className="mt-4 text-center">
                <Button onClick={() => navigate('/accounting/invoices')} className="text-blue-600 hover:text-blue-800">
                  Zobacz wszystkie faktury →
                </Button>
              </div>
            </Card>
            
            {/* Top Categories */}
            <Card title="Top kategorie wydatków">
              <div className="space-y-3">
                {data.topCategories.map((category, index) => (
                  <div key={index} className="flex items-center justify-between">
                    <div className="flex items-center">
                      <div className="w-3 h-3 bg-blue-500 rounded-full mr-3"></div>
                      <span className="text-sm font-medium">{category.category}</span>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-semibold">{formatCurrency(category.amount)}</div>
                      <div className="text-xs text-gray-500">{category.percentage}%</div>
                    </div>
                  </div>
                ))}
              </div>
            </Card>
          </div>
          
          {/* Monthly Trends */}
          <Card title="Trendy miesięczne">
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              {data.monthlyTrends.map((trend, index) => (
                <div key={index} className="text-center p-4 bg-gray-50 rounded-lg">
                  <div className="text-lg font-semibold text-gray-900">{trend.month}</div>
                  <div className="text-sm text-green-600">{formatCurrency(trend.income)}</div>
                  <div className="text-sm text-red-600">{formatCurrency(trend.expenses)}</div>
                  <div className="text-sm font-medium text-blue-600">{formatCurrency(trend.profit)}</div>
                </div>
              ))}
            </div>
          </Card>
        </div>
      </div>
    </AdminOnly>
  );
};

export default Dashboard; 