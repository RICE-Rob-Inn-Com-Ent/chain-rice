// ============================================================================
// ACCOUNTING MODULE - CONSOLIDATED TYPES
// ============================================================================

import React from 'react';

// API Types
export interface ApiEndpoint {
  url: string;
  method: string;
  headers: Record<string, string>;
  timeout: number;
  retryAttempts: number;
}

// Core Business Types
export interface Invoice {
  id: string;
  number: string;
  invoiceNumber: string;
  type: 'income' | 'expense';
  clientSupplier: string;
  clientSupplierName: string;
  clientSupplierVatId?: string;
  clientSupplierAddress?: string;
  issueDate: string;
  dueDate: string;
  amount: number;
  netAmount: number;
  vatAmount: number;
  totalAmount: number;
  grossAmount: number;
  status: InvoiceStatus;
  currency: string;
  description: string;
  items: InvoiceItem[];
  paymentMethod: PaymentMethod;
  notes?: string;
  attachments: string[];
  attachmentUrl?: string;
  createdAt: string;
  updatedAt: string;
}

export interface InvoiceItem {
  name: string;
  quantity: number;
  unitPrice: number;
  vatRate: number;
  netAmount: number;
  vatAmount: number;
  grossAmount: number;
}

export interface Payment {
  id: string;
  invoiceId?: string;
  amount: number;
  method: PaymentMethod;
  status: PaymentStatus;
  date: string;
  description: string;
  reference?: string;
  createdAt: string;
}

export interface BankAccount {
  id: string;
  name: string;
  number: string;
  type: AccountType;
  balance: number;
  currency: string;
  isActive: boolean;
}

export interface Category {
  id: string;
  name: string;
  type: 'income' | 'expense';
  icon: string;
  color: string;
}

export interface DashboardData {
  summary: {
    totalIncome: number;
    totalExpenses: number;
    netIncome: number;
    unpaidInvoices: number;
    overdueInvoices: number;
  };
  recentTransactions: Invoice[];
  topCategories: CategoryStats[];
  monthlyTrends: TrendData[];
}

export interface CategoryStats {
  category: string;
  amount: number;
  percentage: number;
  count: number;
}

export interface TrendData {
  month: string;
  income: number;
  expenses: number;
  profit: number;
}

// Enums
export type InvoiceStatus = 'paid' | 'unpaid' | 'overdue' | 'partially_paid';
export type PaymentStatus = 'pending' | 'completed' | 'failed' | 'cancelled';
export type PaymentMethod = 'cash' | 'bank_transfer' | 'card' | 'check' | 'paypal' | 'company_card';
export type AccountType = 'checking' | 'savings' | 'credit' | 'investment' | 'cash';
export type TransactionType = 'sale' | 'purchase' | 'income' | 'expense';

// Form Types
export interface TransactionForm {
  type: 'income' | 'expense';
  amount: string;
  description: string;
  category: string;
  date: string;
  account: string;
}

export interface DetailedAccountingForm {
  issueDate: string;
  salePurchaseDate: string;
  invoiceReceiptNumber: string;
  sellerCompanyName: string;
  sellerVatId: string;
  sellerAddress: string;
  productServiceName: string;
  quantity: string;
  netUnitPrice: string;
  vatRate: string;
  netAmount: string;
  vatAmount: string;
  grossAmount: string;
  purchaseDescription: string;
  costType: string;
  attachment: File | null;
  paymentMethod: string;
  shouldVatBeDeducted: boolean;
  transactionType: 'sale' | 'purchase';
  category: string;
  account: string;
}

// Filter Types
export interface InvoiceFilters {
  startDate: string;
  endDate: string;
  clientSupplier: string;
  status: InvoiceStatus | 'all';
  type: 'income' | 'expense' | 'all';
}

export interface PaymentFilters {
  startDate: string;
  endDate: string;
  method: PaymentMethod | 'all';
  status: PaymentStatus | 'all';
  amountMin?: number;
  amountMax?: number;
}

// Configuration Types
export interface AccountingConfig {
  defaultCurrency: string;
  enableBudgetAlerts: boolean;
  enableTransactionCategories: boolean;
  enableMultipleAccounts: boolean;
  enableReports: boolean;
  enableExport: boolean;
  fiscalYearStart: string;
  decimalPlaces: number;
}

export interface TransactionCategory {
  id: string;
  name: string;
  icon: string;
  color: string;
}

// Validation Types
export interface ValidationRule {
  type: 'required' | 'email' | 'minLength' | 'maxLength' | 'pattern' | 'custom';
  message: string;
  value?: number | string;
  custom?: (value: string) => boolean;
}

// Export Types
export interface ExportOptions {
  format: 'pdf' | 'csv' | 'excel';
  dateRange: { start: string; end: string };
  filters: InvoiceFilters | PaymentFilters;
  includeAttachments: boolean;
}

// Notification Types
export interface Notification {
  id: string;
  type: 'info' | 'success' | 'warning' | 'error';
  title: string;
  message: string;
  timestamp: string;
  read: boolean;
}

// Audit Types
export interface AuditLog {
  id: string;
  action: string;
  entityType: 'invoice' | 'payment' | 'account' | 'category';
  entityId: string;
  userId: string;
  changes: Record<string, any>;
  timestamp: string;
  ipAddress: string;
} 