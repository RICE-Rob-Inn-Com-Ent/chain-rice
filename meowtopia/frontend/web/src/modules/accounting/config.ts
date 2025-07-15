// ============================================================================
// ACCOUNTING MODULE - CONSOLIDATED CONFIGURATION
// ============================================================================

import { ApiEndpoint, AccountingConfig, TransactionCategory } from './types';

// API Endpoints
export const API_ENDPOINTS: Record<string, ApiEndpoint> = {
  invoices: { url: '/api/accounting/invoices', method: 'GET', headers: {}, timeout: 10000, retryAttempts: 3 },
  payments: { url: '/api/accounting/payments', method: 'GET', headers: {}, timeout: 10000, retryAttempts: 3 },
  dashboard: { url: '/api/accounting/dashboard', method: 'GET', headers: {}, timeout: 10000, retryAttempts: 3 },
  export: { url: '/api/accounting/export', method: 'POST', headers: {}, timeout: 30000, retryAttempts: 3 },
};

// Main Configuration
export const CONFIG: AccountingConfig = {
  defaultCurrency: 'PLN',
  enableBudgetAlerts: true,
  enableTransactionCategories: true,
  enableMultipleAccounts: true,
  enableReports: true,
  enableExport: true,
  fiscalYearStart: '01-01',
  decimalPlaces: 2,
};

// Categories
export const CATEGORIES: TransactionCategory[] = [
  { id: 'salary', name: 'Wynagrodzenia', icon: '💰', color: 'bg-green-100 text-green-800' },
  { id: 'investment', name: 'Inwestycje', icon: '📈', color: 'bg-indigo-100 text-indigo-800' },
  { id: 'freelance', name: 'Freelance', icon: '💼', color: 'bg-blue-100 text-blue-800' },
  { id: 'food', name: 'Żywność', icon: '🍽️', color: 'bg-red-100 text-red-800' },
  { id: 'transport', name: 'Transport', icon: '🚗', color: 'bg-blue-100 text-blue-800' },
  { id: 'entertainment', name: 'Rozrywka', icon: '🎬', color: 'bg-purple-100 text-purple-800' },
  { id: 'utilities', name: 'Media', icon: '💡', color: 'bg-yellow-100 text-yellow-800' },
  { id: 'shopping', name: 'Zakupy', icon: '🛒', color: 'bg-pink-100 text-pink-800' },
  { id: 'health', name: 'Zdrowie', icon: '🏥', color: 'bg-red-100 text-red-800' },
  { id: 'education', name: 'Edukacja', icon: '📚', color: 'bg-blue-100 text-blue-800' },
];

// Messages
export const MESSAGES = {
  // General
  loading: 'Ładowanie...',
  error: 'Wystąpił błąd',
  success: 'Operacja zakończona pomyślnie',
  confirm: 'Czy na pewno chcesz kontynuować?',
  
  // Invoices
  invoiceCreated: 'Faktura została utworzona',
  invoiceUpdated: 'Faktura została zaktualizowana',
  invoiceDeleted: 'Faktura została usunięta',
  invoicePaid: 'Faktura została oznaczona jako opłacona',
  
  // Payments
  paymentCreated: 'Płatność została utworzona',
  paymentUpdated: 'Płatność została zaktualizowana',
  paymentDeleted: 'Płatność została usunięta',
  
  // Validation
  required: 'To pole jest wymagane',
  invalidAmount: 'Nieprawidłowy format kwoty',
  invalidDate: 'Nieprawidłowy format daty',
  invalidEmail: 'Nieprawidłowy format email',
  
  // Status
  paid: 'Opłacona',
  unpaid: 'Nieopłacona',
  overdue: 'Przeterminowana',
  pending: 'Oczekująca',
  completed: 'Zakończona',
  failed: 'Nieudana',
};

// Status Colors
export const STATUS_COLORS = {
  paid: 'bg-green-100 text-green-800',
  unpaid: 'bg-yellow-100 text-yellow-800',
  overdue: 'bg-red-100 text-red-800',
  pending: 'bg-blue-100 text-blue-800',
  completed: 'bg-green-100 text-green-800',
  failed: 'bg-red-100 text-red-800',
};

// Payment Methods
export const PAYMENT_METHODS = [
  { id: 'cash', name: 'Gotówka', icon: '💵' },
  { id: 'bank_transfer', name: 'Przelew', icon: '🏦' },
  { id: 'card', name: 'Karta', icon: '💳' },
  { id: 'check', name: 'Czek', icon: '📄' },
  { id: 'paypal', name: 'PayPal', icon: '🔵' },
  { id: 'company_card', name: 'Karta firmowa', icon: '🏢' },
];

// Account Types
export const ACCOUNT_TYPES = [
  { id: 'checking', name: 'Konto rozliczeniowe', icon: '🏦' },
  { id: 'savings', name: 'Konto oszczędnościowe', icon: '💰' },
  { id: 'credit', name: 'Karta kredytowa', icon: '💳' },
  { id: 'investment', name: 'Konto inwestycyjne', icon: '📈' },
  { id: 'cash', name: 'Gotówka', icon: '💵' },
];

// VAT Rates
export const VAT_RATES = [
  { id: '0', name: '0%', value: 0 },
  { id: '5', name: '5%', value: 5 },
  { id: '8', name: '8%', value: 8 },
  { id: '23', name: '23%', value: 23 },
];

// Navigation Items
export const NAV_ITEMS = [
  { id: 'dashboard', label: 'Dashboard', icon: 'mdi:view-dashboard', path: '/accounting' },
  { id: 'invoices', label: 'Faktury', icon: 'mdi:file-document', path: '/accounting/invoices' },
  { id: 'payments', label: 'Płatności', icon: 'mdi:cash-multiple', path: '/accounting/payments' },
  { id: 'detailed', label: 'Szczegółowe wpisy', icon: 'mdi:calculator', path: '/accounting/detailed' },
  { id: 'reports', label: 'Raporty', icon: 'mdi:chart-line', path: '/accounting/reports' },
  { id: 'accounts', label: 'Konta bankowe', icon: 'mdi:bank', path: '/accounting/accounts' },
  { id: 'categories', label: 'Kategorie', icon: 'mdi:tag-multiple', path: '/accounting/categories' },
  { id: 'taxes', label: 'Podatki', icon: 'mdi:calculator-variant', path: '/accounting/taxes' },
]; 