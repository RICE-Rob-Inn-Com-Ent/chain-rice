// ============================================================================
// ACCOUNTING MODULE - UTILITIES
// ============================================================================

import { Invoice, Payment, InvoiceFilters, PaymentFilters, ValidationRule, InvoiceStatus, PaymentMethod, PaymentStatus } from './types';
import { MESSAGES } from './config';

// Validation
export const validateField = (value: string, rules: ValidationRule[]): string => {
  for (const rule of rules) {
    switch (rule.type) {
      case 'required':
        if (!value.trim()) return rule.message;
        break;
      case 'minLength':
        if (value.length < (rule.value as number)) return rule.message;
        break;
      case 'maxLength':
        if (value.length > (rule.value as number)) return rule.message;
        break;
      case 'pattern':
        if (!new RegExp(rule.value as string).test(value)) return rule.message;
        break;
      case 'custom':
        if (rule.custom && !rule.custom(value)) return rule.message;
        break;
    }
  }
  return '';
};

// Formatting
export const formatCurrency = (amount: number, currency = 'PLN'): string => {
  return new Intl.NumberFormat('pl-PL', { style: 'currency', currency }).format(amount);
};

export const formatDate = (date: string): string => {
  return new Date(date).toLocaleDateString('pl-PL');
};

export const formatDateTime = (date: string): string => {
  return new Date(date).toLocaleString('pl-PL');
};

// Filtering
export const filterInvoices = (invoices: Invoice[], filters: InvoiceFilters): Invoice[] => {
  return invoices.filter(invoice => {
    if (filters.startDate && invoice.issueDate < filters.startDate) return false;
    if (filters.endDate && invoice.issueDate > filters.endDate) return false;
    if (filters.clientSupplier && !invoice.clientSupplier.toLowerCase().includes(filters.clientSupplier.toLowerCase())) return false;
    if (filters.status !== 'all' && invoice.status !== filters.status) return false;
    if (filters.type !== 'all' && invoice.type !== filters.type) return false;
    return true;
  });
};

export const filterPayments = (payments: Payment[], filters: PaymentFilters): Payment[] => {
  return payments.filter(payment => {
    if (filters.startDate && payment.date < filters.startDate) return false;
    if (filters.endDate && payment.date > filters.endDate) return false;
    if (filters.method !== 'all' && payment.method !== filters.method) return false;
    if (filters.status !== 'all' && payment.status !== filters.status) return false;
    if (filters.amountMin && payment.amount < filters.amountMin) return false;
    if (filters.amountMax && payment.amount > filters.amountMax) return false;
    return true;
  });
};

// Sorting
export const sortBy = <T>(items: T[], key: keyof T, direction: 'asc' | 'desc' = 'asc'): T[] => {
  return [...items].sort((a, b) => {
    const aVal = a[key];
    const bVal = b[key];
    
    if (typeof aVal === 'string' && typeof bVal === 'string') {
      return direction === 'asc' ? aVal.localeCompare(bVal) : bVal.localeCompare(aVal);
    }
    
    if (typeof aVal === 'number' && typeof bVal === 'number') {
      return direction === 'asc' ? aVal - bVal : bVal - aVal;
    }
    
    return 0;
  });
};

// Pagination
export const paginate = <T>(items: T[], page: number, limit: number): T[] => {
  const start = (page - 1) * limit;
  return items.slice(start, start + limit);
};

// Calculations
export const calculateVAT = (netAmount: number, vatRate: number): number => {
  return (netAmount * vatRate) / 100;
};

export const calculateGross = (netAmount: number, vatAmount: number): number => {
  return netAmount + vatAmount;
};

export const calculateNet = (grossAmount: number, vatRate: number): number => {
  return grossAmount / (1 + vatRate / 100);
};

// API Helpers
export const makeApiCall = async (endpoint: string | { url: string; method: string; headers?: Record<string, string>; timeout?: number; retryAttempts?: number }, data?: any): Promise<any> => {
  try {
    let url: string;
    let method: string;
    let headers: Record<string, string>;
    
    if (typeof endpoint === 'string') {
      url = endpoint;
      method = data ? 'POST' : 'GET';
      headers = { 'Content-Type': 'application/json' };
    } else {
      url = endpoint.url;
      method = endpoint.method;
      headers = { 'Content-Type': 'application/json', ...endpoint.headers };
    }
    
    const response = await fetch(url, {
      method,
      headers,
      body: data ? JSON.stringify(data) : undefined,
    });
    
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return await response.json();
  } catch (error) {
    throw new Error(MESSAGES.error);
  }
};

// Error Handling
export const handleError = (error: any): string => {
  if (typeof error === 'string') return error;
  if (error?.message) return error.message;
  return MESSAGES.error;
};

// Mock Data Generators
export const generateMockInvoices = (count: number): Invoice[] => {
  return Array.from({ length: count }, (_, i) => ({
    id: `inv-${i + 1}`,
    number: `F/2024/${String(i + 1).padStart(3, '0')}`,
    invoiceNumber: `F/2024/${String(i + 1).padStart(3, '0')}`,
    type: i % 3 === 0 ? 'income' : 'expense',
    clientSupplier: `Firma ${i + 1}`,
    clientSupplierName: `Firma ${i + 1}`,
    clientSupplierVatId: `PL${Math.floor(Math.random() * 1000000000)}`,
    clientSupplierAddress: `ul. Przykładowa ${i + 1}, 00-000 Warszawa`,
    issueDate: new Date(2024, 0, i + 1).toISOString().split('T')[0],
    dueDate: new Date(2024, 1, i + 1).toISOString().split('T')[0],
    amount: Math.random() * 10000 + 100,
    netAmount: Math.random() * 10000 + 100,
    vatAmount: Math.random() * 2000 + 20,
    totalAmount: Math.random() * 12000 + 120,
    grossAmount: Math.random() * 12000 + 120,
    status: ['paid', 'unpaid', 'overdue'][i % 3] as InvoiceStatus,
    currency: 'PLN',
    description: `Opis faktury ${i + 1}`,
    items: [{
      name: `Produkt ${i + 1}`,
      quantity: Math.floor(Math.random() * 10) + 1,
      unitPrice: Math.random() * 1000 + 10,
      vatRate: 23,
      netAmount: Math.random() * 10000 + 100,
      vatAmount: Math.random() * 2000 + 20,
      grossAmount: Math.random() * 12000 + 120,
    }],
    paymentMethod: ['cash', 'bank_transfer', 'card'][i % 3] as PaymentMethod,
    notes: `Notatki do faktury ${i + 1}`,
    attachments: [],
    attachmentUrl: `https://example.com/attachments/invoice-${i + 1}.pdf`,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
  }));
};

export const generateMockPayments = (count: number): Payment[] => {
  return Array.from({ length: count }, (_, i) => ({
    id: `pay-${i + 1}`,
    invoiceId: i % 2 === 0 ? `inv-${i + 1}` : undefined,
    amount: Math.random() * 5000 + 50,
    method: ['cash', 'bank_transfer', 'card'][i % 3] as PaymentMethod,
    status: ['pending', 'completed', 'failed'][i % 3] as PaymentStatus,
    date: new Date(2024, 0, i + 1).toISOString().split('T')[0],
    description: `Płatność ${i + 1}`,
    reference: `REF-${i + 1}`,
    createdAt: new Date().toISOString(),
  }));
}; 