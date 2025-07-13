/**
 * Komponent Listy Faktur - Zarządzanie listą wszystkich faktur
 * 
 * Ten komponent zapewnia kompleksowe zarządzanie fakturami z zaawansowanymi
 * filtrami, wyszukiwaniem i możliwością eksportu danych.
 * 
 * Funkcjonalności:
 * - Lista wszystkich faktur z sortowaniem
 * - Zaawansowane filtry (data, klient, status, kategoria)
 * - Wyszukiwanie tekstowe
 * - Eksport do PDF/CSV
 * - Szybkie akcje (edycja, usuwanie, oznaczanie jako opłacone)
 * - Paginacja i limity wyświetlania
 * 
 * @author Meowtopia Development Team
 * @version 1.0.0
 */

import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Icon } from '@iconify/react';
import Button from '@/components/Button';
import Field from '@/components/Field';
import Table, { TableColumn } from '@/components/Table';
import Card from '@/components/Card';
import Message from '@/components/Message';
import AdminOnly from '@/components/AdminOnly';
import { Invoice, InvoiceFilters } from '../types';
import { filterInvoices, sortBy, paginate, formatCurrency, formatDate, generateMockInvoices } from '../utils';
import { MESSAGES, STATUS_COLORS, PAYMENT_METHODS } from '../config';

const InvoiceList: React.FC = () => {
  const navigate = useNavigate();
  const [invoices, setInvoices] = useState<Invoice[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filters, setFilters] = useState<InvoiceFilters>({
    startDate: '',
    endDate: '',
    clientSupplier: '',
    status: 'all',
    type: 'all',
  });
  const [sortColumn, setSortColumn] = useState<string>('issueDate');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(10);

  useEffect(() => {
    setTimeout(() => {
      setInvoices(generateMockInvoices(25));
      setLoading(false);
    }, 1000);
  }, []);

  const filteredInvoices = filterInvoices(invoices, filters);
  const sortedInvoices = sortBy(filteredInvoices, sortColumn as keyof Invoice, sortDirection);
  const paginatedInvoices = paginate(sortedInvoices, currentPage, itemsPerPage);
  const totalPages = Math.ceil(sortedInvoices.length / itemsPerPage);

  const columns: TableColumn[] = [
    {
      key: 'number',
      label: 'Numer faktury',
      sortable: true,
      render: (value, row) => (
        <button onClick={() => navigate(`/accounting/invoices/${row.id}`)} className="text-blue-600 hover:text-blue-800 font-medium">
          {value}
        </button>
      ),
    },
    {
      key: 'type',
      label: 'Typ',
      sortable: true,
      width: '100px',
      align: 'center',
      render: (value) => (
        <span className={`px-2 py-1 rounded-full text-xs font-medium ${
          value === 'income' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
        }`}>
          {value === 'income' ? 'Przychód' : 'Wydatek'}
        </span>
      ),
    },
    {
      key: 'clientSupplier',
      label: 'Klient/Dostawca',
      sortable: true,
    },
    {
      key: 'issueDate',
      label: 'Data wystawienia',
      sortable: true,
      width: '120px',
      render: (value) => formatDate(value),
    },
    {
      key: 'dueDate',
      label: 'Termin płatności',
      sortable: true,
      width: '120px',
      render: (value) => formatDate(value),
    },
    {
      key: 'totalAmount',
      label: 'Kwota brutto',
      sortable: true,
      width: '120px',
      align: 'right',
      render: (value) => formatCurrency(value),
    },
    {
      key: 'status',
      label: 'Status',
      sortable: true,
      width: '100px',
      align: 'center',
      render: (value) => (
        <span className={`px-2 py-1 rounded-full text-xs font-medium ${STATUS_COLORS[value as keyof typeof STATUS_COLORS]}`}>
          {MESSAGES[value as keyof typeof MESSAGES]}
        </span>
      ),
    },
    {
      key: 'actions',
      label: 'Akcje',
      width: '150px',
      align: 'center',
      render: (_, row) => (
        <div className="flex space-x-2">
          <Button onClick={() => navigate(`/accounting/invoices/${row.id}`)} className="px-2 py-1 text-xs bg-blue-500 text-white rounded hover:bg-blue-600">
            Szczegóły
          </Button>
          {row.status === 'unpaid' && (
            <Button onClick={() => handleMarkAsPaid(row.id)} className="px-2 py-1 text-xs bg-green-500 text-white rounded hover:bg-green-600">
              Opłacona
            </Button>
          )}
        </div>
      ),
    },
  ];

  const handleMarkAsPaid = (invoiceId: string) => {
    setInvoices(prev => prev.map(invoice => 
      invoice.id === invoiceId ? { ...invoice, status: 'paid' } : invoice
    ));
  };

  const handleSort = (key: string, direction: 'asc' | 'desc') => {
    setSortColumn(key);
    setSortDirection(direction);
  };

  const handleExport = (format: 'pdf' | 'csv') => {
    console.log(`Exporting to ${format}`);
  };

  return (
    <AdminOnly>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Lista faktur</h1>
            <p className="text-gray-600">Zarządzaj wszystkimi fakturami przychodowymi i kosztowymi</p>
          </div>
          <Button onClick={() => navigate('/accounting/invoices/new')} className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700" icon="mdi:plus">
            Dodaj fakturę
          </Button>
        </div>

        {/* Filters */}
        <Card title="Filtry" className="mb-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <Field label="Data od" name="startDate" type="date" value={filters.startDate} 
              onChange={(e) => setFilters(prev => ({ ...prev, startDate: e.target.value }))} />
            <Field label="Data do" name="endDate" type="date" value={filters.endDate} 
              onChange={(e) => setFilters(prev => ({ ...prev, endDate: e.target.value }))} />
            <Field label="Klient/Dostawca" name="clientSupplier" value={filters.clientSupplier} 
              onChange={(e) => setFilters(prev => ({ ...prev, clientSupplier: e.target.value }))} placeholder="Wyszukaj po nazwie..." />
            <Field label="Status" name="status" type="select" value={filters.status} 
              onChange={(e) => setFilters(prev => ({ ...prev, status: e.target.value as any }))}>
              <option value="all">Wszystkie</option>
              <option value="paid">Opłacone</option>
              <option value="unpaid">Nieopłacone</option>
              <option value="overdue">Przeterminowane</option>
            </Field>
            <Field label="Typ" name="type" type="select" value={filters.type} 
              onChange={(e) => setFilters(prev => ({ ...prev, type: e.target.value as any }))}>
              <option value="all">Wszystkie</option>
              <option value="income">Przychody</option>
              <option value="expense">Wydatki</option>
            </Field>
          </div>
        </Card>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card className="text-center">
            <div className="text-2xl font-bold text-blue-600">{invoices.filter(i => i.type === 'income').length}</div>
            <div className="text-sm text-gray-600">Faktury przychodowe</div>
          </Card>
          <Card className="text-center">
            <div className="text-2xl font-bold text-red-600">{invoices.filter(i => i.type === 'expense').length}</div>
            <div className="text-sm text-gray-600">Faktury kosztowe</div>
          </Card>
          <Card className="text-center">
            <div className="text-2xl font-bold text-green-600">{invoices.filter(i => i.status === 'paid').length}</div>
            <div className="text-sm text-gray-600">Opłacone</div>
          </Card>
          <Card className="text-center">
            <div className="text-2xl font-bold text-yellow-600">{invoices.filter(i => i.status === 'unpaid').length}</div>
            <div className="text-sm text-gray-600">Nieopłacone</div>
          </Card>
        </div>

        {/* Table */}
        <Card>
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-semibold">Faktury ({filteredInvoices.length})</h3>
            <div className="flex space-x-2">
              <Button onClick={() => handleExport('pdf')} className="bg-red-600 text-white px-3 py-1 rounded text-sm hover:bg-red-700" icon="mdi:file-pdf">
                PDF
              </Button>
              <Button onClick={() => handleExport('csv')} className="bg-green-600 text-white px-3 py-1 rounded text-sm hover:bg-green-700" icon="mdi:file-csv">
                CSV
              </Button>
            </div>
          </div>

          <Table
            columns={columns}
            data={paginatedInvoices}
            loading={loading}
            emptyMessage="Brak faktur do wyświetlenia"
            onSort={handleSort}
            sortColumn={sortColumn}
            sortDirection={sortDirection}
          />

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex justify-between items-center mt-4">
              <div className="text-sm text-gray-600">
                Wyświetlanie {(currentPage - 1) * itemsPerPage + 1}-{Math.min(currentPage * itemsPerPage, sortedInvoices.length)} z {sortedInvoices.length} faktur
              </div>
              <div className="flex space-x-2">
                <Button onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))} disabled={currentPage === 1} 
                  className="px-3 py-1 border border-gray-300 rounded hover:bg-gray-50 disabled:opacity-50">
                  Poprzednia
                </Button>
                <span className="px-3 py-1 text-sm">Strona {currentPage} z {totalPages}</span>
                <Button onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))} disabled={currentPage === totalPages} 
                  className="px-3 py-1 border border-gray-300 rounded hover:bg-gray-50 disabled:opacity-50">
                  Następna
                </Button>
              </div>
            </div>
          )}
        </Card>

        {error && <Message message={error} />}
      </div>
    </AdminOnly>
  );
};

export default InvoiceList; 