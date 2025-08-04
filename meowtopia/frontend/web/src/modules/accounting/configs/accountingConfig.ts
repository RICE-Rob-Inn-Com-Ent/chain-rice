import type { TextConfig } from "@/components/Text";
import type { FieldConfig } from "@/components/Field";
import type { ClickConfig } from "@/components/Click";
import { useNavigate } from "react-router-dom";
import { useState } from "react";

export interface InvoiceFormData {
  clientName: string;
  amount: number;
  description: string;
  dueDate: string;
}

export interface PaymentFormData {
  invoiceId: string;
  amount: number;
  method: string;
  date: string;
}

export function useAccountingConfig() {
  const navigate = useNavigate();
  
  // Invoice form state
  const [invoiceData, setInvoiceData] = useState<InvoiceFormData>({
    clientName: "",
    amount: 0,
    description: "",
    dueDate: "",
  });
  
  // Payment form state
  const [paymentData, setPaymentData] = useState<PaymentFormData>({
    invoiceId: "",
    amount: 0,
    method: "bank_transfer",
    date: "",
  });
  
  // UI states
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  const clearMessages = () => {
    setError("");
    setSuccess("");
  };

  const setLoadingState = (isLoading: boolean) => {
    setLoading(isLoading);
    if (isLoading) clearMessages();
  };

  // Invoice handlers
  const handleInvoiceInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value, type } = e.target;
    setInvoiceData(prev => ({
      ...prev,
      [name]: type === "number" ? parseFloat(value) || 0 : value,
    }));
  };

  const handleInvoiceSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoadingState(true);

    try {
      if (!invoiceData.clientName || !invoiceData.amount || !invoiceData.dueDate) {
        setError("Wszystkie pola są wymagane");
        return;
      }

      if (invoiceData.amount <= 0) {
        setError("Kwota musi być większa od 0");
        return;
      }

      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 2000));
      
      setSuccess("Faktura została pomyślnie utworzona");
      setInvoiceData({
        clientName: "",
        amount: 0,
        description: "",
        dueDate: "",
      });

    } catch (err: any) {
      setError("Błąd podczas tworzenia faktury");
    } finally {
      setLoadingState(false);
    }
  };

  // Payment handlers
  const handlePaymentInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value, type } = e.target;
    setPaymentData(prev => ({
      ...prev,
      [name]: type === "number" ? parseFloat(value) || 0 : value,
    }));
  };

  const handlePaymentSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoadingState(true);

    try {
      if (!paymentData.invoiceId || !paymentData.amount || !paymentData.date) {
        setError("Wszystkie pola są wymagane");
        return;
      }

      if (paymentData.amount <= 0) {
        setError("Kwota musi być większa od 0");
        return;
      }

      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1500));
      setSuccess("Płatność została pomyślnie zarejestrowana");

    } catch (err: any) {
      setError("Błąd podczas rejestrowania płatności");
    } finally {
      setLoadingState(false);
    }
  };

  return {
    // Data states
    invoiceData,
    paymentData,
    loading,
    error,
    success,

    // Handlers
    handleInvoiceInputChange,
    handleInvoiceSubmit,
    handlePaymentInputChange,
    handlePaymentSubmit,

    // Navigation
    navigate,

    // Page configs
    pageTitle: {
      tag: "h2" as const,
      variant: "title-2",
      children: "Moduł Księgowy",
    } as TextConfig,

    pageDescription: {
      tag: "p" as const,
      variant: "title-2"
      children: "Zarządzanie finansami, fakturami i płatnościami",
    } as TextConfig,

    // Dashboard cards
    dashboardCard: {
      tag: "button",
      type: "button",
      children: "Dashboard finansowy",
      ariaLabel: "Przejdź do dashboardu finansowego",
      className: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500",
      onClick: () => navigate("/admin/accounting/dashboard"),
    } as ClickConfig,

    invoicesCard: {
      tag: "button",
      type: "button",
      children: "Zarządzaj fakturami",
      ariaLabel: "Przejdź do zarządzania fakturami",
      className: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500",
      onClick: () => navigate("/admin/accounting/invoices"),
    } as ClickConfig,

    paymentsCard: {
      tag: "button",
      type: "button",
      children: "Zarządzaj płatnościami",
      ariaLabel: "Przejdź do zarządzania płatnościami",
      className: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500",
      onClick: () => navigate("/admin/accounting/payments"),
    } as ClickConfig,

    reportsCard: {
      tag: "button",
      type: "button",
      children: "Raporty finansowe",
      ariaLabel: "Przejdź do raportów finansowych",
      className: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-yellow-600 hover:bg-yellow-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-yellow-500",
      onClick: () => navigate("/admin/accounting/reports"),
    } as ClickConfig,

    // Invoice form config
    invoiceTitle: {
      tag: "h3" as const,
      children: "Utwórz nową fakturę",
      className: "text-lg font-medium text-gray-900 mb-4",
    } as TextConfig,

    clientNameField: {
      tag: "input",
      type: "text",
      name: "clientName",
      label: "Nazwa klienta",
      placeholder: "Wprowadź nazwę klienta",
      className: "mb-4",
      value: invoiceData.clientName,
      onChange: handleInvoiceInputChange,
    } as FieldConfig,

    amountField: {
      tag: "input",
      type: "number",
      name: "amount",
      label: "Kwota (PLN)",
      placeholder: "0.00",
      className: "mb-4",
      value: invoiceData.amount.toString(),
      onChange: handleInvoiceInputChange,
    } as FieldConfig,

    descriptionField: {
      tag: "textarea",
      name: "description",
      label: "Opis",
      placeholder: "Opis usług lub produktów...",
      className: "mb-4",
      value: invoiceData.description,
      onChange: handleInvoiceInputChange,
    } as FieldConfig,

    dueDateField: {
      tag: "input",
      type: "date",
      name: "dueDate",
      label: "Termin płatności",
      className: "mb-4",
      value: invoiceData.dueDate,
      onChange: handleInvoiceInputChange,
    } as FieldConfig,

    createInvoiceButton: {
      tag: "button",
      type: "submit",
      children: loading ? "Tworzenie..." : "Utwórz fakturę",
      ariaLabel: "Utwórz fakturę",
      className: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 disabled:opacity-50",
      disabled: loading,
    } as ClickConfig,

    // Payment form config
    paymentTitle: {
      tag: "h3" as const,
      children: "Zarejestruj płatność",
      className: "text-lg font-medium text-gray-900 mb-4",
    } as TextConfig,

    invoiceIdField: {
      tag: "input",
      type: "text",
      name: "invoiceId",
      label: "ID faktury",
      placeholder: "Wprowadź ID faktury",
      className: "mb-4",
      value: paymentData.invoiceId,
      onChange: handlePaymentInputChange,
    } as FieldConfig,

    paymentAmountField: {
      tag: "input",
      type: "number",
      name: "amount",
      label: "Kwota płatności (PLN)",
      placeholder: "0.00",
      className: "mb-4",
      value: paymentData.amount.toString(),
      onChange: handlePaymentInputChange,
    } as FieldConfig,

    paymentMethodField: {
      tag: "select",
      name: "method",
      label: "Metoda płatności",
      className: "mb-4",
      value: paymentData.method,
      onChange: handlePaymentInputChange,
    } as FieldConfig,

    paymentDateField: {
      tag: "input",
      type: "date",
      name: "date",
      label: "Data płatności",
      className: "mb-4",
      value: paymentData.date,
      onChange: handlePaymentInputChange,
    } as FieldConfig,

    registerPaymentButton: {
      tag: "button",
      type: "submit",
      children: loading ? "Rejestrowanie..." : "Zarejestruj płatność",
      ariaLabel: "Zarejestruj płatność",
      className: "w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-purple-500 disabled:opacity-50",
      disabled: loading,
    } as ClickConfig,

    // Navigation buttons
    backButton: {
      tag: "button",
      type: "button",
      children: "Powrót",
      ariaLabel: "Powrót do księgowości",
      className: "w-full flex justify-center py-2 px-4 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500",
      onClick: () => navigate("/admin/accounting"),
    } as ClickConfig,

    // Error and success messages
    errorText: error ? {
      tag: "span" as const,
      className: "text-sm text-red-600",
      children: error,
    } as TextConfig : null,

    successText: success ? {
      tag: "span" as const,
      className: "text-sm text-green-600",
      children: success,
    } as TextConfig : null,
  };
}
