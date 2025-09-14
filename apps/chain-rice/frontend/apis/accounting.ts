import axios from 'axios';
import {
  Invoice,
  DashboardStats,
  Category,
  ReceiptProcessResponse,
} from '../types/accounting';

const API_BASE_URL = 'http://localhost:8004/api/v1';
const AI_API_BASE_URL = 'http://localhost:8005';

// Create axios instance
const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

const aiApiClient = axios.create({
  baseURL: AI_API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Dashboard API
export const dashboardApi = {
  getStats: async (
    startDate?: string,
    endDate?: string
  ): Promise<DashboardStats> => {
    const params = new URLSearchParams();
    if (startDate) params.append('start_date', startDate);
    if (endDate) params.append('end_date', endDate);

    const response = await apiClient.get(
      `/dashboard/stats?${params.toString()}`
    );
    return response.data.data;
  },
};

// Invoices API
export const invoicesApi = {
  list: async (params?: {
    page?: number;
    page_size?: number;
    status?: string;
    category?: string;
    start_date?: string;
    end_date?: string;
  }): Promise<{
    invoices: Invoice[];
    total_count: number;
    page: number;
    page_size: number;
  }> => {
    const response = await apiClient.get('/invoices', { params });
    return response.data.data;
  },

  get: async (id: string): Promise<Invoice> => {
    const response = await apiClient.get(`/invoices/${id}`);
    return response.data.data;
  },

  create: async (invoice: Partial<Invoice>): Promise<Invoice> => {
    const response = await apiClient.post('/invoices', invoice);
    return response.data.data;
  },

  update: async (id: string, invoice: Partial<Invoice>): Promise<Invoice> => {
    const response = await apiClient.put(`/invoices/${id}`, invoice);
    return response.data.data;
  },

  delete: async (id: string): Promise<void> => {
    await apiClient.delete(`/invoices/${id}`);
  },
};

// Categories API
export const categoriesApi = {
  list: async (): Promise<Category[]> => {
    const response = await aiApiClient.get('/categories');
    return response.data.data;
  },
};

// File upload and AI processing
export const aiApi = {
  processReceipt: async (file: File): Promise<ReceiptProcessResponse> => {
    const formData = new FormData();
    formData.append('file', file);

    const response = await aiApiClient.post('/process-receipt', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  },

  processAndSaveReceipt: async (
    file: File
  ): Promise<ReceiptProcessResponse> => {
    const formData = new FormData();
    formData.append('file', file);

    const response = await aiApiClient.post(
      '/process-receipt-and-save',
      formData,
      {
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      }
    );
    return response.data;
  },

  uploadFile: async (
    file: File
  ): Promise<{ file_path: string; file_id: string }> => {
    const formData = new FormData();
    formData.append('file', file);

    const response = await apiClient.post('/upload', formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
    return response.data;
  },
};
