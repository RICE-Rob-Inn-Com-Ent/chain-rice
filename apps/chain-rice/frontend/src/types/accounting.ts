export interface InvoiceItem {
  id: string;
  name: string;
  description?: string;
  quantity: number;
  unit_price: number;
  total_price: number;
  tax_rate: number;
  category?: string;
}

export interface Invoice {
  id: string;
  invoice_number: string;
  vendor_name: string;
  vendor_tax_id?: string;
  vendor_address?: string;
  date: string;
  due_date?: string;
  total_amount: number;
  tax_amount: number;
  net_amount: number;
  currency: string;
  description?: string;
  category: string;
  status: 'pending' | 'paid' | 'overdue' | 'cancelled';
  items: InvoiceItem[];
  receipt_image_path?: string;
  created_at: string;
  updated_at: string;
}

export interface MonthlyData {
  month: string;
  revenue: number;
  expenses: number;
  profit: number;
}

export interface CategoryExpense {
  category: string;
  amount: number;
  percentage: number;
}

export interface DashboardStats {
  total_revenue: number;
  total_expenses: number;
  net_profit: number;
  total_invoices: number;
  pending_invoices: number;
  overdue_invoices: number;
  monthly_revenue: number;
  monthly_expenses: number;
  monthly_data: MonthlyData[];
  category_expenses: CategoryExpense[];
}

export interface Category {
  id: string;
  name: string;
  color: string;
  description?: string;
}

export interface ReceiptProcessResponse {
  success: boolean;
  message: string;
  data: {
    vendor_name: string;
    total_amount: number;
    tax_amount: number;
    net_amount: number;
    currency: string;
    category: string;
    status: string;
    description: string;
    invoice_number: string;
    date: string;
    confidence_score?: number;
  };
}
