/**
 * Komponent Szczegółów Faktury - Wyświetlanie i edycja faktury
 * 
 * Ten komponent zapewnia szczegółowy widok faktury z możliwością
 * edycji, zmiany statusu i zarządzania załącznikami.
 * 
 * Funkcjonalności:
 * - Pełny widok danych faktury
 * - Edycja faktury w trybie inline
 * - Zmiana statusu płatności
 * - Podgląd i pobieranie załączników
 * - Historia zmian i audit trail
 * - Powiązane płatności
 * - Generowanie PDF
 * 
 * @author Meowtopia Development Team
 * @version 1.0.0
 */

import React, { useState, useEffect } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { Icon } from '@iconify/react';
import Button from '@/components/Button';
import Card from '@/components/Card';
import Message from '@/components/Message';
import AdminOnly from '@/components/AdminOnly';
import { validateField, handleError, formatCurrency, formatDate, makeApiCall } from "../utils";
import { MESSAGES, PAYMENT_METHODS } from '../config';
import type { Invoice, Payment, InvoiceStatus, TransactionType, ValidationRule } from "../types";

// ============================================================================
// INTERFEJSY KOMPONENTU - Właściwości i stany lokalne
// ============================================================================

/**
 * Właściwości komponentu InvoiceDetails
 */
interface InvoiceDetailsProps {
  onStatusChange?: (invoiceId: string, status: InvoiceStatus) => void;
  onInvoiceUpdate?: (invoice: Invoice) => void;
}

// ============================================================================
// FUNKCJE POMOCNICZE - Walidacja pól
// ============================================================================

/**
 * Pobieranie reguł walidacji dla pola
 */
const getFieldValidationRules = (field: string): ValidationRule[] => ({
  clientSupplierName: [{ type: 'required' as const, message: 'Nazwa jest wymagana' }],
  amount: [{ type: 'custom' as const, message: 'Kwota musi być dodatnia', custom: (v: string) => !isNaN(Number(v)) && Number(v) > 0 }],
  description: [{ type: 'maxLength' as const, message: 'Maksymalnie 500 znaków', value: 500 }]
}[field] || []);

// ============================================================================
// KOMPONENT INVOICE DETAILS - Główny komponent szczegółów faktury
// ============================================================================

/**
 * Komponent szczegółów faktury
 * Wyświetla pełne informacje o fakturze z możliwością edycji
 */
const InvoiceDetails: React.FC<InvoiceDetailsProps> = ({
  onStatusChange,
  onInvoiceUpdate
}) => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  
  // ============================================================================
  // STANY KOMPONENTU - Zarządzanie stanem aplikacji
  // ============================================================================
  
  /**
   * Dane faktury - pobierane z API
   */
  const [invoice, setInvoice] = useState<Invoice | null>(null);
  
  /**
   * Powiązane płatności - lista płatności powiązanych z fakturą
   */
  const [linkedPayments, setLinkedPayments] = useState<Payment[]>([]);
  
  /**
   * Stan edycji - które pola są aktualnie edytowane
   */
  const [editState, setEditState] = useState<Record<string, boolean>>({});
  
  /**
   * Tymczasowe dane edycji - przechowuje zmiany przed zapisem
   */
  const [editData, setEditData] = useState<Partial<Invoice>>({});
  
  /**
   * Stany interfejsu użytkownika
   */
  const [loadingStates, setLoadingStates] = useState({
    invoice: false,
    payments: false,
    saving: false
  });
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  
  // ============================================================================
  // POBIERANIE DANYCH - Ładowanie faktury i powiązanych danych
  // ============================================================================
  
  /**
   * Pobieranie faktury z API przy montowaniu komponentu
   */
  useEffect(() => {
    if (id) {
      fetchInvoice();
      fetchLinkedPayments();
    }
  }, [id]);
  
  /**
   * Pobieranie faktury z API
   */
  const fetchInvoice = async () => {
    if (!id) return;
    
    setLoadingStates(prev => ({ ...prev, invoice: true }));
    setError("");
    
    try {
      const response = await makeApiCall({
        url: `/api/v1/accounting/invoices/${id}`,
        method: "GET",
        headers: {
          "Content-Type": "application/json"
        },
        timeout: 10000,
        retryAttempts: 3
      });
      
      setInvoice(response.invoice);
      
    } catch (err: any) {
      setError(handleError(err));
    } finally {
      setLoadingStates(prev => ({ ...prev, invoice: false }));
    }
  };
  
  /**
   * Pobieranie powiązanych płatności
   */
  const fetchLinkedPayments = async () => {
    if (!id) return;
    
    try {
      const response = await makeApiCall({
        url: `/api/v1/accounting/invoices/${id}/payments`,
        method: "GET",
        headers: {
          "Content-Type": "application/json"
        },
        timeout: 10000,
        retryAttempts: 3
      });
      
      setLinkedPayments(response.payments);
      
    } catch (err: any) {
      // Log error but don't show to user as it's not critical
      console.warn("Błąd pobierania powiązanych płatności:", err);
    }
  };
  
  // ============================================================================
  // OBSŁUGA EDYCJI - Zarządzanie trybem edycji i zapisem zmian
  // ============================================================================
  
  /**
   * Włączenie trybu edycji dla pola
   */
  const startEditing = (field: string) => {
    setEditState(prev => ({ ...prev, [field]: true }));
    setEditData(prev => ({ ...prev, [field]: invoice?.[field as keyof Invoice] }));
  };
  
  /**
   * Wyłączenie trybu edycji dla pola
   */
  const cancelEditing = (field: string) => {
    setEditState(prev => ({ ...prev, [field]: false }));
    setEditData(prev => {
      const newData = { ...prev };
      delete newData[field as keyof Invoice];
      return newData;
    });
  };
  
  /**
   * Obsługa zmiany wartości w trybie edycji
   */
  const handleEditChange = (field: string, value: any) => {
    const validationResult = validateField(value, getFieldValidationRules(field));
    if (validationResult) {
      setError(validationResult);
      return;
    }
    setEditData(prev => ({ ...prev, [field]: value }));
    setError('');
  };
  
  /**
   * Zapisanie zmian w polu
   */
  const saveField = async (field: string) => {
    if (!invoice || !editData[field as keyof Invoice]) return;
    
    setLoadingStates(prev => ({ ...prev, saving: true }));
    
    try {
      const response = await makeApiCall({
        url: `/api/v1/accounting/invoices/${invoice.id}`,
        method: "PATCH",
        headers: {
          "Content-Type": "application/json"
        },
        timeout: 10000,
        retryAttempts: 3
      }, {
        [field]: editData[field as keyof Invoice]
      });
      
      // Aktualizacja lokalnego stanu
      setInvoice(prev => prev ? { ...prev, [field]: editData[field as keyof Invoice] } : null);
      setEditState(prev => ({ ...prev, [field]: false }));
      setEditData(prev => {
        const newData = { ...prev };
        delete newData[field as keyof Invoice];
        return newData;
      });
      
      setSuccess("Zmiany zostały zapisane");
      onInvoiceUpdate?.(response.invoice);
      
    } catch (err: any) {
      setError(handleError(err));
    } finally {
      setLoadingStates(prev => ({ ...prev, saving: false }));
    }
  };
  
  // ============================================================================
  // AKCJE NA FAKTURZE - Zmiana statusu, usuwanie, generowanie PDF
  // ============================================================================
  
  /**
   * Zmiana statusu faktury
   */
  const changeStatus = async (newStatus: InvoiceStatus) => {
    if (!invoice) return;
    
    const oldStatus = invoice.status;
    
    // Optymistyczna aktualizacja
    setInvoice(prev => prev ? { ...prev, status: newStatus } : null);
    
    try {
      await makeApiCall({
        url: `/api/v1/accounting/invoices/${invoice.id}/status`,
        method: "PATCH",
        headers: {
          "Content-Type": "application/json"
        },
        timeout: 5000,
        retryAttempts: 2
      }, { status: newStatus });
      
      setSuccess(`Status zmieniony na: ${getStatusText(newStatus)}`);
      onStatusChange?.(invoice.id, newStatus);
      
    } catch (error) {
      // Rollback w przypadku błędu
      setInvoice(prev => prev ? { ...prev, status: oldStatus } : null);
      setError(handleError(error));
    }
  };
  
  /**
   * Usuwanie faktury
   */
  const deleteInvoice = async () => {
    if (!invoice) return;
    
    setLoadingStates(prev => ({ ...prev, saving: true }));
    
    try {
      await makeApiCall({
        url: `/api/v1/accounting/invoices/${invoice.id}`,
        method: "DELETE",
        headers: {
          "Content-Type": "application/json"
        },
        timeout: 5000,
        retryAttempts: 2
      });
      
      setSuccess("Faktura została usunięta");
      navigate("/accounting/invoices");
      
    } catch (err: any) {
      setError(handleError(err));
    } finally {
      setLoadingStates(prev => ({ ...prev, saving: false }));
      setShowDeleteConfirm(false);
    }
  };
  
  /**
   * Generowanie PDF faktury
   */
  const generatePDF = async () => {
    if (!invoice) return;
    
    setLoadingStates(prev => ({ ...prev, saving: true }));
    
    try {
      const response = await makeApiCall({
        url: `/api/v1/accounting/invoices/${invoice.id}/pdf`,
        method: "GET",
        headers: {
          "Content-Type": "application/json"
        },
        timeout: 15000,
        retryAttempts: 2
      });
      
      // Pobieranie pliku PDF
      const link = document.createElement("a");
      link.href = response.downloadUrl;
      link.download = `faktura_${invoice.invoiceNumber}.pdf`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
      setSuccess("PDF faktury został wygenerowany");
      
    } catch (err: any) {
      setError(handleError(err));
    } finally {
      setLoadingStates(prev => ({ ...prev, saving: false }));
    }
  };
  
  /**
   * Pobieranie załącznika
   */
  const downloadAttachment = () => {
    if (!invoice?.attachmentUrl) return;
    
    const link = document.createElement("a");
    link.href = invoice.attachmentUrl;
    link.download = `załącznik_${invoice.invoiceNumber}`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };
  
  // ============================================================================
  // FUNKCJE POMOCNICZE - Formatowanie i walidacja
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
   * Pobieranie koloru statusu
   */
  const getStatusColor = (status: InvoiceStatus): string => {
    switch (status) {
      case "paid": return "text-green-600 bg-green-100";
      case "unpaid": return "text-yellow-600 bg-yellow-100";
      case "overdue": return "text-red-600 bg-red-100";
      case "partially_paid": return "text-blue-600 bg-blue-100";
      default: return "text-gray-600 bg-gray-100";
    }
  };
  
  /**
   * Pobieranie tekstu statusu
   */
  const getStatusText = (status: InvoiceStatus): string => {
    switch (status) {
      case "paid": return "Opłacona";
      case "unpaid": return "Nieopłacona";
      case "overdue": return "Przeterminowana";
      case "partially_paid": return "Częściowo opłacona";
      default: return "Nieznany";
    }
  };
  
  /**
   * Pobieranie tekstu typu transakcji
   */
  const getTransactionTypeText = (type: TransactionType): string => {
    return type === "income" ? "Przychód" : "Wydatek";
  };
  
  /**
   * Sprawdzenie czy faktura jest przeterminowana
   */
  const isOverdue = (): boolean => {
    if (!invoice) return false;
    return invoice.status === "unpaid" && new Date(invoice.dueDate) < new Date();
  };
  
  // ============================================================================
  // RENDER - Wyświetlanie komponentu
  // ============================================================================
  
  if (loadingStates.invoice) {
    return (
      <div className="flex justify-center items-center py-12">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
        <span className="ml-2 text-gray-600">{MESSAGES.loading}</span>
      </div>
    );
  }
  
  if (!invoice) {
    return <Message message="Faktura nie została znaleziona" />;
  }
  
  const basicInfo = [
    { label: "Numer faktury", value: invoice.invoiceNumber },
    { label: "Typ", value: <span className={`px-2 py-1 rounded-full text-xs font-medium ${invoice.type === 'income' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}`}>{getTransactionTypeText(invoice.type)}</span> },
    { label: "Status", value: <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(invoice.status)}`}>{getStatusText(invoice.status)}</span> },
    { label: "Data wystawienia", value: formatDate(invoice.issueDate) },
    { label: "Termin płatności", value: formatDate(invoice.dueDate) },
    { label: "Metoda płatności", value: PAYMENT_METHODS.find(m => m.id === invoice.paymentMethod)?.name || invoice.paymentMethod }
  ];

  const clientInfo = [
    { label: "Nazwa", value: invoice.clientSupplierName },
    ...(invoice.clientSupplierVatId ? [{ label: "NIP", value: invoice.clientSupplierVatId }] : []),
    ...(invoice.clientSupplierAddress ? [{ label: "Adres", value: invoice.clientSupplierAddress }] : [])
  ];

  const headers = ["Nazwa", "Ilość", "Cena jednostkowa", "VAT %", "Kwota netto", "VAT", "Kwota brutto"];
  const summaryData = [
    { label: "Kwota netto", value: formatCurrency(invoice.netAmount), className: "text-gray-900" },
    { label: "VAT", value: formatCurrency(invoice.vatAmount), className: "text-gray-900" },
    { label: "Kwota brutto", value: formatCurrency(invoice.grossAmount), className: "text-blue-600" }
  ];

  const actions = [
    { condition: invoice.status === 'unpaid', text: "Oznacz jako opłaconą", onClick: () => changeStatus('paid'), className: "bg-green-600 hover:bg-green-700" },
    { condition: invoice.status === 'paid', text: "Oznacz jako nieopłaconą", onClick: () => changeStatus('unpaid'), className: "bg-yellow-600 hover:bg-yellow-700" },
    { condition: true, text: "Edytuj", onClick: () => navigate(`/accounting/invoices/${invoice.id}/edit`), className: "bg-blue-600 hover:bg-blue-700" },
    { condition: true, text: "Dodaj płatność", onClick: () => navigate('/accounting/payments/new', { state: { invoiceId: invoice.id } }), className: "bg-purple-600 hover:bg-purple-700" }
  ];

  return (
    <AdminOnly>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Szczegóły faktury</h1>
            <p className="text-gray-600">Faktura {invoice.invoiceNumber}</p>
          </div>
          <div className="flex space-x-3">
            <Button onClick={() => navigate('/accounting/invoices')} className="bg-gray-600 text-white px-4 py-2 rounded-lg hover:bg-gray-700">
              Powrót
            </Button>
            <Button onClick={generatePDF} className="bg-red-600 text-white px-4 py-2 rounded-lg hover:bg-red-700" icon="mdi:file-pdf">
              PDF
            </Button>
          </div>
        </div>

        {/* Invoice Details */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Basic Information */}
          <Card title="Podstawowe informacje">
            <div className="space-y-4">
              {basicInfo.map(({ label, value }) => (
                <div key={label} className="flex justify-between">
                  <span className="text-gray-600">{label}:</span>
                  <span className="font-medium">{value}</span>
                </div>
              ))}
            </div>
          </Card>

          {/* Client/Supplier Information */}
          <Card title="Klient/Dostawca">
            <div className="space-y-4">
              {clientInfo.map(({ label, value }) => (
                <div key={label}>
                  <span className="text-gray-600">{label}:</span>
                  <p className="font-medium">{value}</p>
                </div>
              ))}
            </div>
          </Card>
        </div>

        {/* Invoice Items */}
        <Card title="Pozycje faktury">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  {headers.map(header => <th key={header} className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">{header}</th>)}
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {invoice.items.map((item, index) => (
                  <tr key={index}>
                    {[item.name, item.quantity, formatCurrency(item.unitPrice), `${item.vatRate}%`, formatCurrency(item.netAmount), formatCurrency(item.vatAmount), formatCurrency(item.grossAmount)].map((value, i) => <td key={i} className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">{value}</td>)}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>

        {/* Summary */}
        <Card title="Podsumowanie">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {summaryData.map(({ label, value, className }) => (
              <div key={label} className="text-center">
                <div className={`text-2xl font-bold ${className}`}>{value}</div>
                <div className="text-sm text-gray-600">{label}</div>
              </div>
            ))}
          </div>
        </Card>

        {/* Actions */}
        <Card title="Akcje">
          <div className="flex flex-wrap gap-3">
            {actions.filter(action => action.condition).map(({ text, onClick, className }) => (
              <Button key={text} onClick={onClick} className={`${className} text-white px-4 py-2 rounded`}>
                {text}
              </Button>
            ))}
          </div>
        </Card>

        {error && <Message message={error} />}
      </div>
    </AdminOnly>
  );
};



export default InvoiceDetails; 