// ===== KONTRAHENCI =====
export interface Contractor {
  id: string;
  companyVatId: string;
  companyName: string;
  nip: string;
  regon?: string;
  address: string;
  city: string;
  postalCode: string;
  email?: string;
  phone?: string;
  description?: string;
  createdAt: string;
  isActive: boolean;
}

// ===== FAKTURY VAT =====
export interface Invoice {
  id: string;
  invoiceNumber: string;
  issueDate: string;
  saleDate: string;
  paymentDate: string;
  paymentMethod: 'transfer' | 'cash' | 'card' | 'other';
  isPaid: boolean;

  // Sprzedawca
  seller: {
    vatId: string;
    companyName: string;
    address: string;
    city: string;
    postalCode: string;
    nip: string;
  };

  // Nabywca
  buyer: {
    vatId: string;
    companyName: string;
    address: string;
    city: string;
    postalCode: string;
    nip: string;
  };

  // Pozycje faktury
  items: InvoiceItem[];

  // Podsumowanie
  totalNet: number;
  totalVat: number;
  totalGross: number;

  // Typ faktury VAT
  vatType: 'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G';

  createdAt: string;
  updatedAt: string;
}

export interface InvoiceItem {
  id: string;
  name: string;
  description?: string;
  quantity: number;
  unit: string;
  unitPrice: number;
  netPrice: number;
  vatRate: number;
  vatAmount: number;
  grossPrice: number;
  expenseType: 'goods' | 'services' | 'other';
}

// ===== PRACOWNICY =====
export interface Employee {
  id: string;
  firstName: string;
  lastName: string;
  pesel: string;
  nip?: string;
  address: string;
  city: string;
  postalCode: string;
  phone: string;
  email: string;
  position: string;
  employmentType: 'full-time' | 'part-time' | 'contract' | 'intern';
  hourlyRate: number;
  monthlySalary: number;
  startDate: string;
  endDate?: string;
  isActive: boolean;
  createdAt: string;
}

// ===== CZAS PRACY =====
export interface WorkTime {
  id: string;
  employeeId: string;
  date: string;
  startTime: string;
  endTime: string;
  breakTime: number; // w minutach
  totalHours: number;
  hourlyRate: number;
  totalAmount: number;
  description?: string;
  isApproved: boolean;
  createdAt: string;
}

// ===== WYNAGRODZENIA =====
export interface Payroll {
  id: string;
  employeeId: string;
  month: number;
  year: number;
  grossSalary: number;
  netSalary: number;

  // Składki ZUS
  zus: {
    emerytalne: number;
    rentowe: number;
    chorobowe: number;
    zdrowotne: number;
    funduszPracy: number;
    fgsp: number;
  };

  // Podatki
  taxes: {
    pit: number;
    advancePit: number;
  };

  // Dodatki
  bonuses: {
    overtime: number;
    nightShift: number;
    weekend: number;
    other: number;
  };

  // Potrącenia
  deductions: {
    loan: number;
    advance: number;
    other: number;
  };

  createdAt: string;
}

// ===== PODATKI CIT =====
export interface CITCalculation {
  id: string;
  year: number;
  quarter: number;

  // Przychody
  revenue: {
    sales: number;
    services: number;
    other: number;
    total: number;
  };

  // Koszty
  costs: {
    materials: number;
    services: number;
    salaries: number;
    zus: number;
    depreciation: number;
    other: number;
    total: number;
  };

  // Wynik finansowy
  financialResult: {
    grossProfit: number;
    operatingProfit: number;
    netProfit: number;
  };

  // Podatek CIT
  cit: {
    taxBase: number;
    taxRate: number;
    taxAmount: number;
    advancePayments: number;
    toPay: number;
  };

  createdAt: string;
}

// ===== JPK VAT =====
export interface JPKVAT {
  id: string;
  period: string; // YYYY-MM
  status: 'draft' | 'sent' | 'accepted' | 'rejected';

  // Sprzedaż
  sales: {
    netAmount: number;
    vatAmount: number;
    grossAmount: number;
    records: JPKVATRecord[];
  };

  // Zakupy
  purchases: {
    netAmount: number;
    vatAmount: number;
    grossAmount: number;
    records: JPKVATRecord[];
  };

  // Podsumowanie
  summary: {
    netSales: number;
    vatSales: number;
    netPurchases: number;
    vatPurchases: number;
    vatToPay: number;
    vatToRefund: number;
  };

  createdAt: string;
  sentAt?: string;
}

export interface JPKVATRecord {
  id: string;
  invoiceNumber: string;
  issueDate: string;
  saleDate: string;
  buyerVatId: string;
  buyerName: string;
  netAmount: number;
  vatRate: number;
  vatAmount: number;
  grossAmount: number;
  vatType: string;
}

// ===== DEKLARACJE PODATKOWE =====
export interface TaxDeclaration {
  id: string;
  type:
    | 'PIT-4'
    | 'PIT-8'
    | 'CIT-8'
    | 'VAT-7'
    | 'JPK-VAT'
    | 'ZUS-DRA'
    | 'ZUS-RSA';
  period: string;
  year: number;
  month?: number;
  quarter?: number;
  status: 'draft' | 'ready' | 'sent' | 'accepted' | 'rejected';

  data: Record<string, unknown>; // Dane specyficzne dla typu deklaracji
  xmlContent?: string;
  pdfContent?: string;

  createdAt: string;
  sentAt?: string;
  responseAt?: string;
}

// ===== FIRMA =====
export interface Company {
  id: string;
  name: string;
  nip: string;
  regon: string;
  vatId: string;
  address: string;
  city: string;
  postalCode: string;
  phone: string;
  email: string;
  website?: string;

  // Dane księgowe
  accounting: {
    taxOffice: string;
    accountingPeriod: 'monthly' | 'quarterly' | 'yearly';
    vatRate: number;
    citRate: number;
    accountingMethod: 'cash' | 'accrual';
  };

  // Dane bankowe
  bankAccount: {
    accountNumber: string;
    bankName: string;
    swift: string;
  };

  createdAt: string;
  updatedAt: string;
}

// ===== RAPORTY =====
export interface FinancialReport {
  id: string;
  type:
    | 'income-statement'
    | 'balance-sheet'
    | 'cash-flow'
    | 'vat-summary'
    | 'payroll-summary';
  period: string;
  year: number;
  month?: number;
  quarter?: number;

  data: Record<string, unknown>;
  generatedAt: string;
  generatedBy: string;
}

// ===== API FUNKCJE =====
export interface AccountingAPI {
  // Kontrahenci
  getContractors: () => Promise<Contractor[]>;
  createContractor: (
    contractor: Omit<Contractor, 'id' | 'createdAt'>
  ) => Promise<Contractor>;
  updateContractor: (
    id: string,
    contractor: Partial<Contractor>
  ) => Promise<Contractor>;
  deleteContractor: (id: string) => Promise<void>;

  // Faktury
  getInvoices: () => Promise<Invoice[]>;
  createInvoice: (
    invoice: Omit<Invoice, 'id' | 'createdAt' | 'updatedAt'>
  ) => Promise<Invoice>;
  updateInvoice: (id: string, invoice: Partial<Invoice>) => Promise<Invoice>;
  deleteInvoice: (id: string) => Promise<void>;

  // Pracownicy
  getEmployees: () => Promise<Employee[]>;
  createEmployee: (
    employee: Omit<Employee, 'id' | 'createdAt'>
  ) => Promise<Employee>;
  updateEmployee: (
    id: string,
    employee: Partial<Employee>
  ) => Promise<Employee>;
  deleteEmployee: (id: string) => Promise<void>;

  // Czas pracy
  getWorkTimes: (
    employeeId?: string,
    month?: number,
    year?: number
  ) => Promise<WorkTime[]>;
  createWorkTime: (
    workTime: Omit<WorkTime, 'id' | 'createdAt'>
  ) => Promise<WorkTime>;
  updateWorkTime: (
    id: string,
    workTime: Partial<WorkTime>
  ) => Promise<WorkTime>;
  deleteWorkTime: (id: string) => Promise<void>;

  // Wynagrodzenia
  getPayrolls: (month?: number, year?: number) => Promise<Payroll[]>;
  createPayroll: (
    payroll: Omit<Payroll, 'id' | 'createdAt'>
  ) => Promise<Payroll>;
  calculatePayroll: (
    employeeId: string,
    month: number,
    year: number
  ) => Promise<Payroll>;

  // CIT
  getCITCalculations: (year?: number) => Promise<CITCalculation[]>;
  createCITCalculation: (
    cit: Omit<CITCalculation, 'id' | 'createdAt'>
  ) => Promise<CITCalculation>;
  calculateCIT: (year: number, quarter: number) => Promise<CITCalculation>;

  // JPK VAT
  getJPKVAT: (period?: string) => Promise<JPKVAT[]>;
  createJPKVAT: (jpk: Omit<JPKVAT, 'id' | 'createdAt'>) => Promise<JPKVAT>;
  generateJPKVAT: (period: string) => Promise<JPKVAT>;
  sendJPKVAT: (id: string) => Promise<void>;

  // Deklaracje
  getDeclarations: (type?: string, year?: number) => Promise<TaxDeclaration[]>;
  createDeclaration: (
    declaration: Omit<TaxDeclaration, 'id' | 'createdAt'>
  ) => Promise<TaxDeclaration>;
  generateDeclaration: (
    type: string,
    period: string
  ) => Promise<TaxDeclaration>;
  sendDeclaration: (id: string) => Promise<void>;

  // Firma
  getCompany: () => Promise<Company>;
  updateCompany: (company: Partial<Company>) => Promise<Company>;

  // Raporty
  getReports: (type?: string, year?: number) => Promise<FinancialReport[]>;
  generateReport: (type: string, period: string) => Promise<FinancialReport>;
}
