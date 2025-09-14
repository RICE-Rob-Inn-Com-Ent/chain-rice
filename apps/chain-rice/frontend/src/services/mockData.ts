import type { Contractor, Invoice, InvoiceItem } from '../api/types/accounting';

// Mock contractors data
export const mockContractors: Contractor[] = [
  {
    id: '1',
    name: 'ABC Sp. z o.o.',
    nip: '1234567890',
    regon: '123456789',
    address: 'ul. Przykładowa 123',
    city: 'Warszawa',
    postal_code: '00-001',
    phone: '+48 123 456 789',
    email: 'kontakt@abc.pl',
    description: 'Firma informatyczna',
    created_at: '2024-01-15T10:00:00Z',
  },
  {
    id: '2',
    name: 'XYZ Sp. z o.o.',
    nip: '0987654321',
    regon: '987654321',
    address: 'ul. Testowa 456',
    city: 'Kraków',
    postal_code: '30-001',
    phone: '+48 987 654 321',
    email: 'biuro@xyz.pl',
    description: 'Firma budowlana',
    created_at: '2024-01-20T14:30:00Z',
  },
  {
    id: '3',
    name: 'DEF Sp. z o.o.',
    nip: '1122334455',
    regon: '112233445',
    address: 'ul. Próbna 789',
    city: 'Gdańsk',
    postal_code: '80-001',
    phone: '+48 112 233 445',
    email: 'info@def.pl',
    description: 'Firma handlowa',
    created_at: '2024-02-01T09:15:00Z',
  },
];

// Mock invoice items
export const mockInvoiceItems: InvoiceItem[] = [
  {
    id: '1',
    position_name: 'Usługi programistyczne',
    gross_amount: 5000.0,
    tax_rate: '23',
    expense_type: 'sprzedaż towarów i usług',
  },
  {
    id: '2',
    position_name: 'Konsultacje techniczne',
    gross_amount: 2500.0,
    tax_rate: '23',
    expense_type: 'sprzedaż towarów i usług',
  },
  {
    id: '3',
    position_name: 'Materiały biurowe',
    gross_amount: 500.0,
    tax_rate: '23',
    expense_type: 'sprzedaż towarów i usług',
  },
];

// Mock invoices data
export const mockInvoices: Invoice[] = [
  {
    id: '1',
    contractor: mockContractors[0],
    items: [mockInvoiceItems[0], mockInvoiceItems[1]],
    sale_date: '2024-01-15',
    issue_date: '2024-01-15',
    payment_method: 'przelew bankowy',
    bank_account: 'PL12 3456 7890 1234 5678 9012 3456',
    is_paid: true,
    total_gross: 7500.0,
    total_net: 6097.56,
    total_tax: 1402.44,
    created_at: '2024-01-15T10:00:00Z',
  },
  {
    id: '2',
    contractor: mockContractors[1],
    items: [mockInvoiceItems[2]],
    sale_date: '2024-01-20',
    issue_date: '2024-01-20',
    payment_method: 'gotówka',
    bank_account: 'PL12 3456 7890 1234 5678 9012 3456',
    is_paid: false,
    total_gross: 500.0,
    total_net: 406.5,
    total_tax: 93.5,
    created_at: '2024-01-20T14:30:00Z',
  },
  {
    id: '3',
    contractor: mockContractors[2],
    items: [mockInvoiceItems[0], mockInvoiceItems[2]],
    sale_date: '2024-02-01',
    issue_date: '2024-02-01',
    payment_method: 'karta płatnicza',
    bank_account: 'PL12 3456 7890 1234 5678 9012 3456',
    is_paid: true,
    total_gross: 5500.0,
    total_net: 4471.55,
    total_tax: 1028.45,
    created_at: '2024-02-01T09:15:00Z',
  },
];

// Helper function to simulate API delay
export const simulateApiDelay = (ms: number = 500): Promise<void> => {
  return new Promise(resolve => setTimeout(resolve, ms));
};
