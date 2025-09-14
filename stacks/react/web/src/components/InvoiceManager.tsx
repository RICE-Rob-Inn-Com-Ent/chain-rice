import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useDropzone } from 'react-dropzone';
import { format } from 'date-fns';
import {
  Plus,
  Upload,
  FileText,
  Search,
  Filter,
  Eye,
  Edit,
  Trash2,
  Download,
  CheckCircle,
  Clock,
  AlertTriangle,
} from 'lucide-react';
import toast from 'react-hot-toast';
import { invoicesApi, categoriesApi, aiApi } from '../apis/accounting';
import { Invoice, Category } from '../types/accounting';
import InvoiceForm from './InvoiceForm';

const InvoiceManager: React.FC = () => {
  const [showForm, setShowForm] = useState(false);
  const [editingInvoice, setEditingInvoice] = useState<Invoice | null>(null);
  const [filters, setFilters] = useState({
    status: '',
    category: '',
    search: '',
    page: 1,
    page_size: 10,
  });

  const queryClient = useQueryClient();

  // Fetch invoices
  const { data: invoicesData, isLoading } = useQuery({
    queryKey: ['invoices', filters],
    queryFn: () => invoicesApi.list(filters),
  });

  // Fetch categories
  const { data: categories } = useQuery<Category[]>({
    queryKey: ['categories'],
    queryFn: () => categoriesApi.list(),
  });

  // Mutations
  const deleteInvoiceMutation = useMutation({
    mutationFn: (id: string) => invoicesApi.delete(id),
    onSuccess: () => {
      toast.success('Інвойс видалено успішно');
      queryClient.invalidateQueries({ queryKey: ['invoices'] });
    },
    onError: () => {
      toast.error('Помилка видалення інвойса');
    },
  });

  // File upload handler
  const onDrop = async (acceptedFiles: File[]) => {
    const file = acceptedFiles[0];
    if (!file) return;

    try {
      toast.loading('Обробка чеку...', { id: 'receipt-processing' });

      const result = await aiApi.processAndSaveReceipt(file);

      if (result.success) {
        toast.success('Чек оброблено та збережено!', {
          id: 'receipt-processing',
        });
        queryClient.invalidateQueries({ queryKey: ['invoices'] });
        queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      } else {
        toast.error('Помилка обробки чеку', { id: 'receipt-processing' });
      }
    } catch (error) {
      toast.error('Помилка завантаження файлу', { id: 'receipt-processing' });
    }
  };

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'image/*': ['.jpeg', '.jpg', '.png'],
      'application/pdf': ['.pdf'],
    },
    multiple: false,
  });

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'paid':
        return <CheckCircle className='h-4 w-4 text-green-500' />;
      case 'pending':
        return <Clock className='h-4 w-4 text-yellow-500' />;
      case 'overdue':
        return <AlertTriangle className='h-4 w-4 text-red-500' />;
      default:
        return <FileText className='h-4 w-4 text-gray-500' />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'paid':
        return 'bg-green-100 text-green-800';
      case 'pending':
        return 'bg-yellow-100 text-yellow-800';
      case 'overdue':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('uk-UA', {
      style: 'currency',
      currency: 'UAH',
      minimumFractionDigits: 0,
    }).format(value);

  return (
    <div className='space-y-6'>
      {/* Header */}
      <div className='flex items-center justify-between'>
        <div>
          <h1 className='text-3xl font-bold text-gray-900'>
            Управління інвойсами
          </h1>
          <p className='text-gray-600 mt-1'>
            Додавайте та керуйте рахунками-фактурами
          </p>
        </div>
        <div className='flex space-x-3'>
          <div
            {...getRootProps()}
            className='flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 cursor-pointer transition-colors'
          >
            <input {...getInputProps()} />
            <Upload className='h-4 w-4 mr-2' />
            {isDragActive ? 'Перетягніть файл сюди...' : 'Завантажити чек'}
          </div>
          <button
            onClick={() => setShowForm(true)}
            className='flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors'
          >
            <Plus className='h-4 w-4 mr-2' />
            Додати інвойс
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className='bg-white rounded-lg shadow-sm border border-gray-200 p-4'>
        <div className='grid grid-cols-1 md:grid-cols-4 gap-4'>
          <div>
            <label className='block text-sm font-medium text-gray-700 mb-1'>
              Пошук
            </label>
            <div className='relative'>
              <Search className='absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400' />
              <input
                type='text'
                placeholder='Номер інвойса або постачальник...'
                className='w-full pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
                value={filters.search}
                onChange={e =>
                  setFilters({ ...filters, search: e.target.value })
                }
              />
            </div>
          </div>

          <div>
            <label className='block text-sm font-medium text-gray-700 mb-1'>
              Статус
            </label>
            <select
              className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
              value={filters.status}
              onChange={e => setFilters({ ...filters, status: e.target.value })}
            >
              <option value=''>Всі статуси</option>
              <option value='pending'>Очікуючі</option>
              <option value='paid'>Сплачені</option>
              <option value='overdue'>Прострочені</option>
              <option value='cancelled'>Скасовані</option>
            </select>
          </div>

          <div>
            <label className='block text-sm font-medium text-gray-700 mb-1'>
              Категорія
            </label>
            <select
              className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
              value={filters.category}
              onChange={e =>
                setFilters({ ...filters, category: e.target.value })
              }
            >
              <option value=''>Всі категорії</option>
              {categories?.map(category => (
                <option key={category.id} value={category.name}>
                  {category.name}
                </option>
              ))}
            </select>
          </div>

          <div className='flex items-end'>
            <button
              onClick={() =>
                setFilters({
                  status: '',
                  category: '',
                  search: '',
                  page: 1,
                  page_size: 10,
                })
              }
              className='w-full flex items-center justify-center px-3 py-2 text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors'
            >
              <Filter className='h-4 w-4 mr-2' />
              Скинути
            </button>
          </div>
        </div>
      </div>

      {/* Invoices Table */}
      <div className='bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden'>
        {isLoading ? (
          <div className='flex items-center justify-center h-64'>
            <div className='animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600'></div>
          </div>
        ) : (
          <div className='overflow-x-auto'>
            <table className='min-w-full divide-y divide-gray-200'>
              <thead className='bg-gray-50'>
                <tr>
                  <th className='px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider'>
                    Інвойс
                  </th>
                  <th className='px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider'>
                    Постачальник
                  </th>
                  <th className='px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider'>
                    Дата
                  </th>
                  <th className='px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider'>
                    Сума
                  </th>
                  <th className='px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider'>
                    Статус
                  </th>
                  <th className='px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider'>
                    Категорія
                  </th>
                  <th className='px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider'>
                    Дії
                  </th>
                </tr>
              </thead>
              <tbody className='bg-white divide-y divide-gray-200'>
                {invoicesData?.invoices.map(invoice => (
                  <tr key={invoice.id} className='hover:bg-gray-50'>
                    <td className='px-6 py-4 whitespace-nowrap'>
                      <div>
                        <div className='text-sm font-medium text-gray-900'>
                          {invoice.invoice_number}
                        </div>
                        <div className='text-sm text-gray-500'>
                          ID: {invoice.id.slice(0, 8)}...
                        </div>
                      </div>
                    </td>
                    <td className='px-6 py-4 whitespace-nowrap'>
                      <div className='text-sm text-gray-900'>
                        {invoice.vendor_name}
                      </div>
                      {invoice.vendor_tax_id && (
                        <div className='text-sm text-gray-500'>
                          {invoice.vendor_tax_id}
                        </div>
                      )}
                    </td>
                    <td className='px-6 py-4 whitespace-nowrap text-sm text-gray-900'>
                      {format(new Date(invoice.date), 'dd.MM.yyyy')}
                    </td>
                    <td className='px-6 py-4 whitespace-nowrap'>
                      <div className='text-sm font-medium text-gray-900'>
                        {formatCurrency(invoice.total_amount)}
                      </div>
                      <div className='text-sm text-gray-500'>
                        ПДВ: {formatCurrency(invoice.tax_amount)}
                      </div>
                    </td>
                    <td className='px-6 py-4 whitespace-nowrap'>
                      <span
                        className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(invoice.status)}`}
                      >
                        {getStatusIcon(invoice.status)}
                        <span className='ml-1'>
                          {invoice.status === 'paid'
                            ? 'Сплачено'
                            : invoice.status === 'pending'
                              ? 'Очікує'
                              : invoice.status === 'overdue'
                                ? 'Прострочено'
                                : 'Скасовано'}
                        </span>
                      </span>
                    </td>
                    <td className='px-6 py-4 whitespace-nowrap text-sm text-gray-900'>
                      {invoice.category}
                    </td>
                    <td className='px-6 py-4 whitespace-nowrap text-right text-sm font-medium'>
                      <div className='flex items-center justify-end space-x-2'>
                        <button
                          onClick={() => setEditingInvoice(invoice)}
                          className='text-blue-600 hover:text-blue-900'
                          title='Редагувати'
                        >
                          <Edit className='h-4 w-4' />
                        </button>
                        <button
                          onClick={() =>
                            deleteInvoiceMutation.mutate(invoice.id)
                          }
                          className='text-red-600 hover:text-red-900'
                          title='Видалити'
                        >
                          <Trash2 className='h-4 w-4' />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Pagination */}
      {invoicesData && invoicesData.total_count > filters.page_size && (
        <div className='flex items-center justify-between bg-white px-4 py-3 border border-gray-200 rounded-lg'>
          <div className='text-sm text-gray-700'>
            Показано {(filters.page - 1) * filters.page_size + 1} -{' '}
            {Math.min(
              filters.page * filters.page_size,
              invoicesData.total_count
            )}{' '}
            з {invoicesData.total_count} інвойсів
          </div>
          <div className='flex space-x-2'>
            <button
              onClick={() =>
                setFilters({ ...filters, page: Math.max(1, filters.page - 1) })
              }
              disabled={filters.page === 1}
              className='px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed'
            >
              Попередня
            </button>
            <button
              onClick={() => setFilters({ ...filters, page: filters.page + 1 })}
              disabled={
                filters.page * filters.page_size >= invoicesData.total_count
              }
              className='px-3 py-1 text-sm border border-gray-300 rounded hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed'
            >
              Наступна
            </button>
          </div>
        </div>
      )}

      {/* Forms */}
      {showForm && (
        <InvoiceForm
          invoice={null}
          categories={categories || []}
          onClose={() => setShowForm(false)}
          onSave={() => {
            setShowForm(false);
            queryClient.invalidateQueries({ queryKey: ['invoices'] });
          }}
        />
      )}

      {editingInvoice && (
        <InvoiceForm
          invoice={editingInvoice}
          categories={categories || []}
          onClose={() => setEditingInvoice(null)}
          onSave={() => {
            setEditingInvoice(null);
            queryClient.invalidateQueries({ queryKey: ['invoices'] });
          }}
        />
      )}
    </div>
  );
};

export default InvoiceManager;
