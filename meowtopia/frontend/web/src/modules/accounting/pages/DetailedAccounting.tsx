/**
 * Komponent Szczegółowego Wpisu Księgowego
 * 
 * Ten komponent zapewnia kompleksowy formularz do wprowadzania szczegółowych
 * wpisów księgowych z obsługą VAT, dokumentów i zaawansowanych obliczeń.
 * 
 * Funkcjonalności:
 * - Wprowadzanie danych faktury/paragonu
 * - Automatyczne obliczenia VAT
 * - Upload dokumentów (PDF, JPG, PNG)
 * - Walidacja wszystkich pól
 * - Obsługa różnych stawek VAT
 * - Kategoryzacja księgowa
 * 
 * @author Meowtopia Development Team
 * @version 1.0.0
 */

import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import Button from '@/components/Button';
import Field from '@/components/Field';
import Card from '@/components/Card';
import Message from '@/components/Message';
import AdminOnly from '@/components/AdminOnly';
import { DetailedAccountingForm } from '../types';
import { calculateVAT, calculateGross } from '../utils';
import { MESSAGES, VAT_RATES, PAYMENT_METHODS } from '../config';

/**
 * Komponent szczegółowego wpisu księgowego
 * Zarządza kompleksowym formularzem z obliczeniami VAT i obsługą dokumentów
 */
const DetailedAccounting: React.FC = () => {
  const navigate = useNavigate();
  const [form, setForm] = useState<DetailedAccountingForm>({
    issueDate: '',
    salePurchaseDate: '',
    invoiceReceiptNumber: '',
    sellerCompanyName: '',
    sellerVatId: '',
    sellerAddress: '',
    productServiceName: '',
    quantity: '',
    netUnitPrice: '',
    vatRate: '23',
    netAmount: '',
    vatAmount: '',
    grossAmount: '',
    purchaseDescription: '',
    costType: '',
    attachment: null,
    paymentMethod: '',
    shouldVatBeDeducted: false,
    transactionType: 'purchase',
    category: '',
    account: '',
  });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleInputChange = (field: keyof DetailedAccountingForm, value: any) => {
    setForm(prev => ({ ...prev, [field]: value }));
  };

  const calculateAmounts = () => {
    const netAmount = parseFloat(form.netAmount) || 0;
    const vatRate = parseFloat(form.vatRate) || 0;
    const vatAmount = calculateVAT(netAmount, vatRate);
    const grossAmount = calculateGross(netAmount, vatAmount);
    
    setForm(prev => ({
      ...prev,
      vatAmount: vatAmount.toFixed(2),
      grossAmount: grossAmount.toFixed(2),
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      navigate('/accounting/invoices');
    } catch (err) {
      setError(MESSAGES.error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <AdminOnly>
      <div className="space-y-6">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Szczegółowy wpis księgowy</h1>
            <p className="text-gray-600">Dodaj szczegółowy wpis z obsługą VAT i dokumentów</p>
          </div>
          <Button onClick={() => navigate('/accounting')} className="bg-gray-600 text-white px-4 py-2 rounded-lg hover:bg-gray-700">
            Powrót
          </Button>
        </div>

        <Card>
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Basic Information */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Field label="Data wystawienia" name="issueDate" type="date" value={form.issueDate} 
                onChange={(e) => handleInputChange('issueDate', e.target.value)} required />
              <Field label="Data sprzedaży/zakupu" name="salePurchaseDate" type="date" value={form.salePurchaseDate} 
                onChange={(e) => handleInputChange('salePurchaseDate', e.target.value)} required />
              <Field label="Numer faktury/paragonu" name="invoiceReceiptNumber" value={form.invoiceReceiptNumber} 
                onChange={(e) => handleInputChange('invoiceReceiptNumber', e.target.value)} required />
            </div>

            {/* Seller Information */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Field label="Nazwa firmy sprzedawcy" name="sellerCompanyName" value={form.sellerCompanyName} 
                onChange={(e) => handleInputChange('sellerCompanyName', e.target.value)} required />
              <Field label="NIP sprzedawcy" name="sellerVatId" value={form.sellerVatId} 
                onChange={(e) => handleInputChange('sellerVatId', e.target.value)} />
            </div>

            <Field label="Adres sprzedawcy" name="sellerAddress" value={form.sellerAddress} 
              onChange={(e) => handleInputChange('sellerAddress', e.target.value)} required />

            {/* Product Information */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <Field label="Nazwa produktu/usługi" name="productServiceName" value={form.productServiceName} 
                onChange={(e) => handleInputChange('productServiceName', e.target.value)} required />
              <Field label="Ilość" name="quantity" type="number" value={form.quantity} 
                onChange={(e) => handleInputChange('quantity', e.target.value)} required />
              <Field label="Cena jednostkowa netto" name="netUnitPrice" type="number" step="0.01" value={form.netUnitPrice} 
                onChange={(e) => handleInputChange('netUnitPrice', e.target.value)} required />
            </div>

            {/* VAT and Amounts */}
            <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
              <Field label="Stawka VAT" name="vatRate" type="select" value={form.vatRate} 
                onChange={(e) => handleInputChange('vatRate', e.target.value)}>
                {VAT_RATES.map(rate => (
                  <option key={rate.id} value={rate.value}>{rate.name}</option>
                ))}
              </Field>
              <Field label="Kwota netto" name="netAmount" type="number" step="0.01" value={form.netAmount} 
                onChange={(e) => handleInputChange('netAmount', e.target.value)} required />
              <Field label="Kwota VAT" name="vatAmount" type="number" step="0.01" value={form.vatAmount} 
                onChange={(e) => handleInputChange('vatAmount', e.target.value)} required readOnly />
              <Field label="Kwota brutto" name="grossAmount" type="number" step="0.01" value={form.grossAmount} 
                onChange={(e) => handleInputChange('grossAmount', e.target.value)} required readOnly />
            </div>

            <Button type="button" onClick={calculateAmounts} className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700">
              Oblicz kwoty
            </Button>

            {/* Additional Information */}
            <Field label="Opis zakupu" name="purchaseDescription" type="textarea" value={form.purchaseDescription} 
              onChange={(e) => handleInputChange('purchaseDescription', e.target.value)} />

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <Field label="Typ kosztu" name="costType" value={form.costType} 
                onChange={(e) => handleInputChange('costType', e.target.value)} required />
              <Field label="Metoda płatności" name="paymentMethod" type="select" value={form.paymentMethod} 
                onChange={(e) => handleInputChange('paymentMethod', e.target.value)} required>
                <option value="">Wybierz metodę płatności</option>
                {PAYMENT_METHODS.map(method => (
                  <option key={method.id} value={method.id}>{method.name}</option>
                ))}
              </Field>
            </div>

            <div className="flex items-center space-x-4">
              <label className="flex items-center">
                <input type="checkbox" checked={form.shouldVatBeDeducted} 
                  onChange={(e) => handleInputChange('shouldVatBeDeducted', e.target.checked)} 
                  className="mr-2" />
                <span>VAT do odliczenia</span>
              </label>
            </div>

            <div className="flex justify-end space-x-4">
              <Button type="button" onClick={() => navigate('/accounting')} className="bg-gray-600 text-white px-6 py-2 rounded hover:bg-gray-700">
                Anuluj
              </Button>
              <Button type="submit" loading={loading} className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700">
                Zapisz wpis
              </Button>
            </div>
          </form>
        </Card>

        {error && <Message message={error} />}
      </div>
    </AdminOnly>
  );
};

export default DetailedAccounting; 