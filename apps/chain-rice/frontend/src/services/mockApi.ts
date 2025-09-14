import { mockContractors, mockInvoices, simulateApiDelay } from './mockData';
import type {
  Contractor,
  Invoice,
  InvoiceItem,
  TaxCalculationRequest,
  TaxCalculationResult,
} from '../api/types/accounting';

// Mock API functions that simulate real API calls
export const mockGetContractors = async (): Promise<Contractor[]> => {
  await simulateApiDelay();
  return [...mockContractors];
};

export const mockSearchContractors = async (
  query: string
): Promise<Contractor[]> => {
  await simulateApiDelay();
  const filtered = mockContractors.filter(
    contractor =>
      contractor.name.toLowerCase().includes(query.toLowerCase()) ||
      contractor.nip.includes(query)
  );
  return filtered;
};

export const mockCreateContractor = async (
  contractor: Omit<Contractor, 'id' | 'created_at'>
): Promise<Contractor> => {
  await simulateApiDelay();
  const newContractor: Contractor = {
    ...contractor,
    id: Date.now().toString(),
    created_at: new Date().toISOString(),
  };
  mockContractors.push(newContractor);
  return newContractor;
};

export const mockGetInvoices = async (): Promise<Invoice[]> => {
  await simulateApiDelay();
  return [...mockInvoices];
};

export const mockCreateInvoice = async (
  invoice: Omit<Invoice, 'id' | 'created_at'>
): Promise<Invoice> => {
  await simulateApiDelay();
  const newInvoice: Invoice = {
    ...invoice,
    id: Date.now().toString(),
    created_at: new Date().toISOString(),
  };
  mockInvoices.push(newInvoice);
  return newInvoice;
};

export const mockDeleteInvoice = async (id: string): Promise<void> => {
  await simulateApiDelay();
  const index = mockInvoices.findIndex(invoice => invoice.id === id);
  if (index > -1) {
    mockInvoices.splice(index, 1);
  }
};

export const mockCalculateTax = async (
  request: TaxCalculationRequest
): Promise<TaxCalculationResult> => {
  await simulateApiDelay();

  const taxRate = parseFloat(request.tax_rate);
  const grossAmount = request.gross_amount;
  const netAmount = grossAmount / (1 + taxRate / 100);
  const taxAmount = grossAmount - netAmount;

  return {
    gross_amount: grossAmount,
    net_amount: Math.round(netAmount * 100) / 100,
    tax_amount: Math.round(taxAmount * 100) / 100,
    tax_rate: request.tax_rate,
  };
};

export const mockCalculateInvoiceTotal = async (
  items: InvoiceItem[]
): Promise<{
  totalGross: number;
  totalNet: number;
  totalTax: number;
}> => {
  await simulateApiDelay();

  let totalGross = 0;
  let totalNet = 0;
  let totalTax = 0;

  items.forEach(item => {
    const taxRate = parseFloat(item.tax_rate);
    const grossAmount = item.gross_amount;
    const netAmount = grossAmount / (1 + taxRate / 100);
    const taxAmount = grossAmount - netAmount;

    totalGross += grossAmount;
    totalNet += netAmount;
    totalTax += taxAmount;
  });

  return {
    totalGross: Math.round(totalGross * 100) / 100,
    totalNet: Math.round(totalNet * 100) / 100,
    totalTax: Math.round(totalTax * 100) / 100,
  };
};

// Mock health check
export const mockGetTaxApiHealth = async (): Promise<unknown> => {
  await simulateApiDelay(200);
  return {
    status: 'ok',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  };
};

export const mockGetBlockchainInfo = async (): Promise<unknown> => {
  await simulateApiDelay(200);
  return {
    node_info: {
      network: 'chainrice-testnet',
      version: '0.1.0',
    },
  };
};
