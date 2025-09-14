import React, { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useForm, useFieldArray } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { format } from 'date-fns';
import { X, Plus, Save } from 'lucide-react';
import toast from 'react-hot-toast';
import { invoicesApi } from '../apis/accounting';
import { Invoice, InvoiceItem, Category } from '../types/accounting';

const invoiceSchema = z.object({
  invoice_number: z.string().min(1, "Номер інвойса обов'язковий"),
  vendor_name: z.string().min(1, "Назва постачальника обов'язкова"),
  vendor_tax_id: z.string().optional(),
  vendor_address: z.string().optional(),
  date: z.string().min(1, "Дата обов'язкова"),
  due_date: z.string().optional(),
  total_amount: z.number().min(0, 'Сума повинна бути більше 0'),
  tax_amount: z.number().min(0, "ПДВ не може бути від'ємним"),
  net_amount: z.number().min(0, "Чиста сума не може бути від'ємною"),
  currency: z.string().default('UAH'),
  description: z.string().optional(),
  category: z.string().min(1, "Категорія обов'язкова"),
  status: z
    .enum(['pending', 'paid', 'overdue', 'cancelled'])
    .default('pending'),
  items: z
    .array(
      z.object({
        name: z.string().min(1, "Назва товару обов'язкова"),
        description: z.string().optional(),
        quantity: z.number().min(1, 'Кількість повинна бути більше 0'),
        unit_price: z.number().min(0, "Ціна за одиницю не може бути від'ємною"),
        tax_rate: z.number().min(0).max(1).default(0.23),
        category: z.string().optional(),
      })
    )
    .default([]),
});

type InvoiceFormData = z.infer<typeof invoiceSchema>;

interface InvoiceFormProps {
  invoice?: Invoice | null;
  categories: Category[];
  onClose: () => void;
  onSave: () => void;
}

const InvoiceForm: React.FC<InvoiceFormProps> = ({
  invoice,
  categories,
  onClose,
  onSave,
}) => {
  const queryClient = useQueryClient();
  const [isCalculating, setIsCalculating] = useState(false);

  const {
    register,
    control,
    handleSubmit,
    watch,
    setValue,
    formState: { errors },
  } = useForm<InvoiceFormData>({
    resolver: zodResolver(invoiceSchema),
    defaultValues: {
      invoice_number: invoice?.invoice_number || '',
      vendor_name: invoice?.vendor_name || '',
      vendor_tax_id: invoice?.vendor_tax_id || '',
      vendor_address: invoice?.vendor_address || '',
      date: invoice?.date
        ? format(new Date(invoice.date), 'yyyy-MM-dd')
        : format(new Date(), 'yyyy-MM-dd'),
      due_date: invoice?.due_date
        ? format(new Date(invoice.due_date), 'yyyy-MM-dd')
        : '',
      total_amount: invoice?.total_amount || 0,
      tax_amount: invoice?.tax_amount || 0,
      net_amount: invoice?.net_amount || 0,
      currency: invoice?.currency || 'UAH',
      description: invoice?.description || '',
      category: invoice?.category || '',
      status: invoice?.status || 'pending',
      items: invoice?.items || [],
    },
  });

  const { fields, append, remove } = useFieldArray({
    control,
    name: 'items',
  });

  const watchedItems = watch('items');

  // Calculate totals when items change
  React.useEffect(() => {
    if (watchedItems.length > 0) {
      setIsCalculating(true);

      let totalNet = 0;
      let totalTax = 0;

      watchedItems.forEach(item => {
        const itemTotal = item.quantity * item.unit_price;
        const itemTax = itemTotal * item.tax_rate;
        totalNet += itemTotal;
        totalTax += itemTax;
      });

      const totalAmount = totalNet + totalTax;

      setValue('net_amount', Number(totalNet.toFixed(2)));
      setValue('tax_amount', Number(totalTax.toFixed(2)));
      setValue('total_amount', Number(totalAmount.toFixed(2)));

      setIsCalculating(false);
    }
  }, [watchedItems, setValue]);

  const createMutation = useMutation({
    mutationFn: (data: InvoiceFormData) => invoicesApi.create(data),
    onSuccess: () => {
      toast.success('Інвойс створено успішно');
      onSave();
    },
    onError: () => {
      toast.error('Помилка створення інвойса');
    },
  });

  const updateMutation = useMutation({
    mutationFn: (data: InvoiceFormData) =>
      invoicesApi.update(invoice!.id, data),
    onSuccess: () => {
      toast.success('Інвойс оновлено успішно');
      onSave();
    },
    onError: () => {
      toast.error('Помилка оновлення інвойса');
    },
  });

  const onSubmit = (data: InvoiceFormData) => {
    if (invoice) {
      updateMutation.mutate(data);
    } else {
      createMutation.mutate(data);
    }
  };

  const addItem = () => {
    append({
      name: '',
      description: '',
      quantity: 1,
      unit_price: 0,
      tax_rate: 0.23,
      category: '',
    });
  };

  return (
    <div className='fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4'>
      <div className='bg-white rounded-lg shadow-xl max-w-4xl w-full max-h-[90vh] overflow-y-auto'>
        <div className='flex items-center justify-between p-6 border-b border-gray-200'>
          <h2 className='text-xl font-semibold text-gray-900'>
            {invoice ? 'Редагувати інвойс' : 'Створити новий інвойс'}
          </h2>
          <button
            onClick={onClose}
            className='text-gray-400 hover:text-gray-600'
          >
            <X className='h-6 w-6' />
          </button>
        </div>

        <form onSubmit={handleSubmit(onSubmit)} className='p-6 space-y-6'>
          {/* Basic Information */}
          <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
            <div>
              <label className='block text-sm font-medium text-gray-700 mb-1'>
                Номер інвойса *
              </label>
              <input
                {...register('invoice_number')}
                className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
                placeholder='INV-2024-001'
              />
              {errors.invoice_number && (
                <p className='text-red-500 text-sm mt-1'>
                  {errors.invoice_number.message}
                </p>
              )}
            </div>

            <div>
              <label className='block text-sm font-medium text-gray-700 mb-1'>
                Статус
              </label>
              <select
                {...register('status')}
                className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
              >
                <option value='pending'>Очікує</option>
                <option value='paid'>Сплачено</option>
                <option value='overdue'>Прострочено</option>
                <option value='cancelled'>Скасовано</option>
              </select>
            </div>

            <div>
              <label className='block text-sm font-medium text-gray-700 mb-1'>
                Назва постачальника *
              </label>
              <input
                {...register('vendor_name')}
                className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
                placeholder='ТОВ Приклад'
              />
              {errors.vendor_name && (
                <p className='text-red-500 text-sm mt-1'>
                  {errors.vendor_name.message}
                </p>
              )}
            </div>

            <div>
              <label className='block text-sm font-medium text-gray-700 mb-1'>
                Податковий номер
              </label>
              <input
                {...register('vendor_tax_id')}
                className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
                placeholder='12345678'
              />
            </div>

            <div>
              <label className='block text-sm font-medium text-gray-700 mb-1'>
                Дата *
              </label>
              <input
                type='date'
                {...register('date')}
                className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
              />
              {errors.date && (
                <p className='text-red-500 text-sm mt-1'>
                  {errors.date.message}
                </p>
              )}
            </div>

            <div>
              <label className='block text-sm font-medium text-gray-700 mb-1'>
                Термін оплати
              </label>
              <input
                type='date'
                {...register('due_date')}
                className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
              />
            </div>

            <div>
              <label className='block text-sm font-medium text-gray-700 mb-1'>
                Категорія *
              </label>
              <select
                {...register('category')}
                className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
              >
                <option value=''>Оберіть категорію</option>
                {categories.map(category => (
                  <option key={category.id} value={category.name}>
                    {category.name}
                  </option>
                ))}
              </select>
              {errors.category && (
                <p className='text-red-500 text-sm mt-1'>
                  {errors.category.message}
                </p>
              )}
            </div>

            <div>
              <label className='block text-sm font-medium text-gray-700 mb-1'>
                Валюта
              </label>
              <select
                {...register('currency')}
                className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
              >
                <option value='UAH'>UAH</option>
                <option value='USD'>USD</option>
                <option value='EUR'>EUR</option>
                <option value='PLN'>PLN</option>
              </select>
            </div>
          </div>

          <div>
            <label className='block text-sm font-medium text-gray-700 mb-1'>
              Адреса постачальника
            </label>
            <textarea
              {...register('vendor_address')}
              rows={2}
              className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
              placeholder='вул. Прикладна, 123, Київ'
            />
          </div>

          <div>
            <label className='block text-sm font-medium text-gray-700 mb-1'>
              Опис
            </label>
            <textarea
              {...register('description')}
              rows={3}
              className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
              placeholder='Додатковий опис інвойса...'
            />
          </div>

          {/* Items */}
          <div>
            <div className='flex items-center justify-between mb-4'>
              <h3 className='text-lg font-medium text-gray-900'>
                Товари/Послуги
              </h3>
              <button
                type='button'
                onClick={addItem}
                className='flex items-center px-3 py-1 text-sm bg-blue-600 text-white rounded-lg hover:bg-blue-700'
              >
                <Plus className='h-4 w-4 mr-1' />
                Додати товар
              </button>
            </div>

            {fields.length === 0 ? (
              <div className='text-center py-8 text-gray-500'>
                <p>Немає товарів. Натисніть "Додати товар" щоб почати.</p>
              </div>
            ) : (
              <div className='space-y-4'>
                {fields.map((field, index) => (
                  <div
                    key={field.id}
                    className='border border-gray-200 rounded-lg p-4'
                  >
                    <div className='flex items-center justify-between mb-3'>
                      <h4 className='font-medium text-gray-900'>
                        Товар {index + 1}
                      </h4>
                      <button
                        type='button'
                        onClick={() => remove(index)}
                        className='text-red-600 hover:text-red-800'
                      >
                        <X className='h-4 w-4' />
                      </button>
                    </div>

                    <div className='grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4'>
                      <div className='md:col-span-2'>
                        <label className='block text-sm font-medium text-gray-700 mb-1'>
                          Назва *
                        </label>
                        <input
                          {...register(`items.${index}.name`)}
                          className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
                          placeholder='Назва товару або послуги'
                        />
                        {errors.items?.[index]?.name && (
                          <p className='text-red-500 text-sm mt-1'>
                            {errors.items[index]?.name?.message}
                          </p>
                        )}
                      </div>

                      <div>
                        <label className='block text-sm font-medium text-gray-700 mb-1'>
                          Кількість *
                        </label>
                        <input
                          type='number'
                          min='1'
                          step='0.01'
                          {...register(`items.${index}.quantity`, {
                            valueAsNumber: true,
                          })}
                          className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
                        />
                        {errors.items?.[index]?.quantity && (
                          <p className='text-red-500 text-sm mt-1'>
                            {errors.items[index]?.quantity?.message}
                          </p>
                        )}
                      </div>

                      <div>
                        <label className='block text-sm font-medium text-gray-700 mb-1'>
                          Ціна за одиницю *
                        </label>
                        <input
                          type='number'
                          min='0'
                          step='0.01'
                          {...register(`items.${index}.unit_price`, {
                            valueAsNumber: true,
                          })}
                          className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
                        />
                        {errors.items?.[index]?.unit_price && (
                          <p className='text-red-500 text-sm mt-1'>
                            {errors.items[index]?.unit_price?.message}
                          </p>
                        )}
                      </div>

                      <div>
                        <label className='block text-sm font-medium text-gray-700 mb-1'>
                          Ставка ПДВ
                        </label>
                        <select
                          {...register(`items.${index}.tax_rate`, {
                            valueAsNumber: true,
                          })}
                          className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
                        >
                          <option value={0}>Без ПДВ</option>
                          <option value={0.2}>20%</option>
                          <option value={0.23}>23%</option>
                        </select>
                      </div>

                      <div className='md:col-span-2'>
                        <label className='block text-sm font-medium text-gray-700 mb-1'>
                          Опис
                        </label>
                        <input
                          {...register(`items.${index}.description`)}
                          className='w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent'
                          placeholder='Додатковий опис товару'
                        />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Totals */}
          <div className='bg-gray-50 rounded-lg p-4'>
            <div className='grid grid-cols-1 md:grid-cols-3 gap-4'>
              <div>
                <label className='block text-sm font-medium text-gray-700 mb-1'>
                  Чиста сума
                </label>
                <input
                  type='number'
                  step='0.01'
                  {...register('net_amount', { valueAsNumber: true })}
                  readOnly
                  className='w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-100'
                />
              </div>

              <div>
                <label className='block text-sm font-medium text-gray-700 mb-1'>
                  Сума ПДВ
                </label>
                <input
                  type='number'
                  step='0.01'
                  {...register('tax_amount', { valueAsNumber: true })}
                  readOnly
                  className='w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-100'
                />
              </div>

              <div>
                <label className='block text-sm font-medium text-gray-700 mb-1'>
                  Загальна сума
                </label>
                <input
                  type='number'
                  step='0.01'
                  {...register('total_amount', { valueAsNumber: true })}
                  readOnly
                  className='w-full px-3 py-2 border border-gray-300 rounded-lg bg-gray-100 font-semibold'
                />
              </div>
            </div>
          </div>

          {/* Form Actions */}
          <div className='flex items-center justify-end space-x-3 pt-6 border-t border-gray-200'>
            <button
              type='button'
              onClick={onClose}
              className='px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors'
            >
              Скасувати
            </button>
            <button
              type='submit'
              disabled={
                createMutation.isPending ||
                updateMutation.isPending ||
                isCalculating
              }
              className='flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors'
            >
              {isCalculating ? (
                <>
                  <div className='animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2'></div>
                  Розрахунок...
                </>
              ) : (
                <>
                  <Save className='h-4 w-4 mr-2' />
                  {invoice ? 'Оновити' : 'Створити'}
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default InvoiceForm;
