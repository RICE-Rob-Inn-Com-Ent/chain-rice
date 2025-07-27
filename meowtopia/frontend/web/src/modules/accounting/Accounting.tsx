import React from "react";
import { Routes, Route } from "react-router-dom";
import { Text } from "@/components/Text";
import { Field } from "@/components/Field";
import { Click } from "@/components/Click";
import { useAccountingConfig } from "./configs/accountingConfig";

const Accounting: React.FC = () => {
  const config = useAccountingConfig();

  const AccountingMain: React.FC = () => (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <Text {...config.pageTitle} />
        <Text {...config.pageDescription} />
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          <div className="space-y-4">
            <Click {...config.dashboardCard} />
            <Click {...config.invoicesCard} />
            <Click {...config.paymentsCard} />
            <Click {...config.reportsCard} />
          </div>
        </div>
      </div>
    </div>
  );

  const DashboardPage: React.FC = () => (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-2xl">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          <Text
            tag="h2"
            className="text-2xl font-bold text-gray-900 mb-6 text-center"
          >
            Dashboard Finansowy
          </Text>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
            <div className="bg-green-50 border border-green-200 rounded-lg p-6">
              <Text tag="h3" className="text-lg font-semibold text-green-800 mb-2">
                Przychody
              </Text>
              <Text tag="p" className="text-2xl font-bold text-green-600">
                15,230 PLN
              </Text>
              <Text tag="p" className="text-sm text-green-600">
                +12% od poprzedniego miesiąca
              </Text>
            </div>
            
            <div className="bg-red-50 border border-red-200 rounded-lg p-6">
              <Text tag="h3" className="text-lg font-semibold text-red-800 mb-2">
                Wydatki
              </Text>
              <Text tag="p" className="text-2xl font-bold text-red-600">
                8,450 PLN
              </Text>
              <Text tag="p" className="text-sm text-red-600">
                +5% od poprzedniego miesiąca
              </Text>
            </div>
            
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
              <Text tag="h3" className="text-lg font-semibold text-blue-800 mb-2">
                Zysk netto
              </Text>
              <Text tag="p" className="text-2xl font-bold text-blue-600">
                6,780 PLN
              </Text>
              <Text tag="p" className="text-sm text-blue-600">
                +18% od poprzedniego miesiąca
              </Text>
            </div>
            
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6">
              <Text tag="h3" className="text-lg font-semibold text-yellow-800 mb-2">
                Faktury oczekujące
              </Text>
              <Text tag="p" className="text-2xl font-bold text-yellow-600">
                5
              </Text>
              <Text tag="p" className="text-sm text-yellow-600">
                Do opłacenia w tym miesiącu
              </Text>
            </div>
          </div>

          <div className="text-center">
            <Click {...config.backButton} />
          </div>
        </div>
      </div>
    </div>
  );

  const InvoicesPage: React.FC = () => (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <Text {...config.pageTitle} />
        <Text {...config.pageDescription} />
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          <form onSubmit={config.handleInvoiceSubmit} className="space-y-6">
            <Text {...config.invoiceTitle} />
            
            <div>
              <Field {...config.clientNameField} />
            </div>
            
            <div>
              <Field {...config.amountField} />
            </div>
            
            <div>
              <Field {...config.descriptionField} />
            </div>
            
            <div>
              <Field {...config.dueDateField} />
            </div>

            <div>
              <Click {...config.createInvoiceButton} />
            </div>

            <div>
              <Click {...config.backButton} />
            </div>

            {config.errorText && (
              <div className="mt-4 bg-red-50 border border-red-200 rounded-md p-4">
                <Text {...config.errorText} />
              </div>
            )}

            {config.successText && (
              <div className="mt-4 bg-green-50 border border-green-200 rounded-md p-4">
                <Text {...config.successText} />
              </div>
            )}
          </form>
        </div>
      </div>
    </div>
  );

  const PaymentsPage: React.FC = () => (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <Text {...config.pageTitle} />
        <Text {...config.pageDescription} />
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          <form onSubmit={config.handlePaymentSubmit} className="space-y-6">
            <Text {...config.paymentTitle} />
            
            <div>
              <Field {...config.invoiceIdField} />
            </div>
            
            <div>
              <Field {...config.paymentAmountField} />
            </div>

            <div>
              <Field {...config.paymentMethodField}>
                <option value="bank_transfer">Przelew bankowy</option>
                <option value="cash">Gotówka</option>
                <option value="card">Karta płatnicza</option>
                <option value="blik">BLIK</option>
              </Field>
            </div>
            
            <div>
              <Field {...config.paymentDateField} />
            </div>

            <div>
              <Click {...config.registerPaymentButton} />
            </div>

            <div>
              <Click {...config.backButton} />
            </div>

            {config.errorText && (
              <div className="mt-4 bg-red-50 border border-red-200 rounded-md p-4">
                <Text {...config.errorText} />
              </div>
            )}

            {config.successText && (
              <div className="mt-4 bg-green-50 border border-green-200 rounded-md p-4">
                <Text {...config.successText} />
              </div>
            )}
          </form>
        </div>
      </div>
    </div>
  );

  const ReportsPage: React.FC = () => (
    <div className="min-h-screen bg-gray-50 flex flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div className="sm:mx-auto sm:w-full sm:max-w-md">
        <div className="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          <div className="text-center">
            <Text
              tag="h2"
              className="text-2xl font-bold text-gray-900 mb-4"
            >
              Raporty Finansowe
            </Text>
            
            <Text
              tag="p"
              className="text-gray-600 mb-6"
            >
              Funkcja raportów będzie dostępna wkrótce
            </Text>

            <div className="space-y-4">
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                <Text tag="h3" className="text-lg font-semibold text-blue-800 mb-2">
                  Raport miesięczny
                </Text>
                <Text tag="p" className="text-sm text-blue-600">
                  Przegląd przychodów i wydatków
                </Text>
              </div>
              
              <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                <Text tag="h3" className="text-lg font-semibold text-green-800 mb-2">
                  Raport roczny
                </Text>
                <Text tag="p" className="text-sm text-green-600">
                  Analiza finansowa za cały rok
                </Text>
              </div>
              
              <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
                <Text tag="h3" className="text-lg font-semibold text-purple-800 mb-2">
                  Raport podatkowy
                </Text>
                <Text tag="p" className="text-sm text-purple-600">
                  Przygotowanie dokumentów do urzędu skarbowego
                </Text>
              </div>
            </div>

            <div className="mt-6">
              <Click {...config.backButton} />
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  return (
    <Routes>
      <Route path="/" element={<AccountingMain />} />
      <Route path="/dashboard" element={<DashboardPage />} />
      <Route path="/invoices" element={<InvoicesPage />} />
      <Route path="/payments" element={<PaymentsPage />} />
      <Route path="/reports" element={<ReportsPage />} />
    </Routes>
  );
};

export default Accounting; 