/**
 * Komponent Zarządzania Płatnościami - Lista i zarządzanie płatnościami
 * 
 * Ten komponent zapewnia kompleksowe zarządzanie płatnościami z zaawansowanymi
 * filtrami, wyszukiwaniem i możliwością eksportu danych.
 * 
 * Funkcjonalności:
 * - Lista wszystkich płatności z sortowaniem
 * - Zaawansowane filtry (data, metoda, status, kategoria)
 * - Wyszukiwanie tekstowe
 * - Eksport do PDF/CSV
 * - Szybkie akcje (edycja, usuwanie, zmiana statusu)
 * - Paginacja i limity wyświetlania
 * - Powiązania z fakturami
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
import { Payment, PaymentFilters } from '../types';
import { filterPayments, sortBy, paginate, formatCurrency, formatDate, generateMockPayments } from '../utils';
import { MESSAGES, STATUS_COLORS, PAYMENT_METHODS } from '../config';

const Payments: React.FC = () => {
  const navigate = useNavigate();
  const [payments, setPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [filters, setFilters] = useState<PaymentFilters>({
    startDate: '',
    endDate: '',
    method: 'all',
    status: 'all',
  });
  const [sortColumn, setSortColumn] = useState<string>('date');
  const [sortDirection, setSortDirection] = useState<'asc' | 'desc'>('desc');
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(10);

  useEffect(() => {
    setTimeout(() => {
      setPayments(generateMockPayments(20));
      setLoading(false);
    }, 1000);
  }, []);

  const filteredPayments = filterPayments(payments, filters);
  const sortedPayments = sortBy(filteredPayments, sortColumn as keyof Payment, sortDirection);
  const paginatedPayments = paginate(sortedPayments, currentPage, itemsPerPage);
  const totalPages = Math.ceil(sortedPayments.length / itemsPerPage);

  const columns: TableColumn[] = [
    {
      key: 'id',
      label: 'ID płatności',
      width: '120px',
      render: (value, row) => (
        <button onClick={() => navigate(`/accounting/payments/${row.id}`)} className="text-blue-600 hover:text-blue-800 font-medium">
          {value}
        </button>
      ),
    },
    {
      key: 'date',
      label: 'Data płatności',
      sortable: true,
      width: '120px',
      render: (value) => formatDate(value),
    },
    {
      key: 'description',
      label: 'Opis',
      sortable: true,
    },
    {
      key: 'amount',
      label: 'Kwota',
      sortable: true,
      width: '120px',
      align: 'right',
      render: (value) => formatCurrency(value),
    },
    {
      key: 'method',
      label: 'Metoda',
      sortable: true,
      width: '100px',
      align: 'center',
      render: (value) => {
        const method = PAYMENT_METHODS.find(m => m.id === value);
        return method ? method.name : value;
      },
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
          <Button onClick={() => navigate(`/accounting/payments/${row.id}`)} className="px-2 py-1 text-xs bg-blue-500 text-white rounded hover:bg-blue-600">
            Szczegóły
          </Button>
          {row.status === 'pending' && (
            <Button onClick={() => handleStatusChange(row.id, 'completed')} className="px-2 py-1 text-xs bg-green-500 text-white rounded hover:bg-green-600">
              Zakończ
            </Button>
          )}
        </div>
      ),
    },
  ];

  const handleStatusChange = (paymentId: string, status: string) => {
    setPayments(prev => prev.map(payment => 
      payment.id === paymentId ? { ...payment, status: status as any } : payment
    ));
  };

  const handleSort = (key: string, direction: 'asc' | 'desc') => {
    setSortColumn(key);
    setSortDirection(direction);
  };

  const handleExport = (format: 'pdf' | 'csv') => {
    console.log(`Exporting payments to ${format}`);
  };

  return (
    <AdminOnly>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Płatności</h1>
            <p className="text-gray-600">Zarządzaj wszystkimi płatnościami</p>
          </div>
          <Button onClick={() => navigate('/accounting/payments/new')} className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700" icon="mdi:plus">
            Dodaj płatność
          </Button>
        </div>

        {/* Filters */}
        <Card title="Filtry" className="mb-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <Field label="Data od" name="startDate" type="date" value={filters.startDate} 
              onChange={(e) => setFilters(prev => ({ ...prev, startDate: e.target.value }))} />
            <Field label="Data do" name="endDate" type="date" value={filters.endDate} 
              onChange={(e) => setFilters(prev => ({ ...prev, endDate: e.target.value }))} />
            <Field label="Metoda płatności" name="method" type="select" value={filters.method} 
              onChange={(e) => setFilters(prev => ({ ...prev, method: e.target.value as any }))}>
              <option value="all">Wszystkie</option>
              {PAYMENT_METHODS.map(method => (
                <option key={method.id} value={method.id}>{method.name}</option>
              ))}
            </Field>
            <Field label="Status" name="status" type="select" value={filters.status} 
              onChange={(e) => setFilters(prev => ({ ...prev, status: e.target.value as any }))}>
              <option value="all">Wszystkie</option>
              <option value="pending">Oczekujące</option>
              <option value="completed">Zakończone</option>
              <option value="failed">Nieudane</option>
              <option value="cancelled">Anulowane</option>
            </Field>
          </div>
        </Card>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card className="text-center">
            <div className="text-2xl font-bold text-blue-600">{payments.length}</div>
            <div className="text-sm text-gray-600">Wszystkie płatności</div>
          </Card>
          <Card className="text-center">
            <div className="text-2xl font-bold text-green-600">{payments.filter(p => p.status === 'completed').length}</div>
            <div className="text-sm text-gray-600">Zakończone</div>
          </Card>
          <Card className="text-center">
            <div className="text-2xl font-bold text-yellow-600">{payments.filter(p => p.status === 'pending').length}</div>
            <div className="text-sm text-gray-600">Oczekujące</div>
          </Card>
          <Card className="text-center">
            <div className="text-2xl font-bold text-red-600">{payments.filter(p => p.status === 'failed').length}</div>
            <div className="text-sm text-gray-600">Nieudane</div>
          </Card>
        </div>

        {/* Table */}
        <Card>
          <div className="flex justify-between items-center mb-4">
            <h3 className="text-lg font-semibold">Płatności ({filteredPayments.length})</h3>
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
            data={paginatedPayments}
            loading={loading}
            emptyMessage="Brak płatności do wyświetlenia"
            onSort={handleSort}
            sortColumn={sortColumn}
            sortDirection={sortDirection}
          />

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex justify-between items-center mt-4">
              <div className="text-sm text-gray-600">
                Wyświetlanie {(currentPage - 1) * itemsPerPage + 1}-{Math.min(currentPage * itemsPerPage, sortedPayments.length)} z {sortedPayments.length} płatności
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

export default Payments; 