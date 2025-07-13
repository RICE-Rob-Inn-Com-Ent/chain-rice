/**
 * Komponent Główny Modułu Księgowego - Centralne zarządzanie finansami
 * 
 * Ten komponent jest głównym punktem wejścia do modułu księgowego,
 * zapewniając nawigację do wszystkich funkcji finansowych.
 * 
 * Funkcjonalności:
 * - Dashboard finansowy z przeglądem
 * - Zarządzanie fakturami (lista, szczegóły, tworzenie)
 * - Zarządzanie płatnościami
 * - Raporty finansowe
 * - Zarządzanie kontami bankowymi
 * - Kategoryzacja transakcji
 * - Analizy podatkowe
 * 
 * @author Meowtopia Development Team
 * @version 2.0.0
 */

import React, { useState } from 'react';
import { Routes, Route, useNavigate, useLocation } from 'react-router-dom';
import { Icon } from '@iconify/react';
import Button from '@/components/Button';
import Card from '@/components/Card';
import AdminOnly from '@/components/AdminOnly';
import { NAV_ITEMS } from './config';
import Dashboard from './pages/Dashboard';
import InvoiceList from './pages/InvoiceList';
import InvoiceDetails from './pages/InvoiceDetails';
import Payments from './pages/Payments';
import DetailedAccounting from './pages/DetailedAccounting';

/**
 * Główny komponent modułu księgowości
 * Zawiera nawigację i routing dla wszystkich funkcji księgowych
 * Dostępny tylko dla administratorów
 */
const Accounting: React.FC = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const isActiveRoute = (path: string) => 
    location.pathname === path || location.pathname.startsWith(path + '/');

  const PlaceholderPage = ({ title, icon, description }: { title: string; icon: string; description: string }) => (
    <Card title={title} className="text-center py-12">
      <Icon icon={icon} className="w-16 h-16 text-gray-400 mx-auto mb-4" />
      <h3 className="text-lg font-medium text-gray-900 mb-2">{title}</h3>
      <p className="text-gray-600">{description}</p>
    </Card>
  );

  return (
    <AdminOnly>
      <div className="min-h-screen bg-gray-50">
        {/* Sidebar */}
        <div className={`fixed inset-y-0 left-0 z-50 w-64 bg-white shadow-lg transform transition-transform duration-300 ease-in-out ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        } lg:translate-x-0 lg:static lg:inset-0`}>
          <div className="flex items-center justify-between h-16 px-6 border-b border-gray-200">
            <h1 className="text-xl font-semibold text-gray-900">Księgowość</h1>
            <button onClick={() => setSidebarOpen(false)} className="lg:hidden p-2 rounded-md text-gray-400 hover:text-gray-600">
              <Icon icon="mdi:close" className="w-6 h-6" />
            </button>
          </div>

          <nav className="mt-6 px-3">
            <div className="space-y-1">
              {NAV_ITEMS.map((item) => (
                <button
                  key={item.id}
                  onClick={() => { navigate(item.path); setSidebarOpen(false); }}
                  className={`w-full flex items-center px-3 py-2 text-sm font-medium rounded-md transition-colors ${
                    isActiveRoute(item.path) ? 'bg-blue-100 text-blue-700' : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                  }`}
                >
                  <Icon icon={item.icon} className="mr-3 w-5 h-5" />
                  <span>{item.label}</span>
                </button>
              ))}
            </div>
          </nav>
        </div>

        {/* Main Content */}
        <div className="lg:pl-64">
          {/* Top Bar */}
          <div className="sticky top-0 z-40 bg-white shadow-sm border-b border-gray-200">
            <div className="flex items-center justify-between h-16 px-4 sm:px-6 lg:px-8">
              <button onClick={() => setSidebarOpen(true)} className="lg:hidden p-2 rounded-md text-gray-400 hover:text-gray-600">
                <Icon icon="mdi:menu" className="w-6 h-6" />
              </button>
              
              <h2 className="text-lg font-medium text-gray-900">
                {NAV_ITEMS.find(item => isActiveRoute(item.path))?.label || 'Księgowość'}
              </h2>

              <div className="flex items-center space-x-3">
                <Button onClick={() => navigate('/accounting/invoices/new')} className="bg-blue-600 text-white px-3 py-2 rounded-md hover:bg-blue-700 text-sm" icon="mdi:plus">
                  Nowa faktura
                </Button>
                <Button onClick={() => navigate('/accounting/detailed')} className="bg-green-600 text-white px-3 py-2 rounded-md hover:bg-green-700 text-sm" icon="mdi:calculator">
                  Wpis księgowy
                </Button>
              </div>
            </div>
          </div>

          {/* Page Content */}
          <main className="p-4 sm:p-6 lg:p-8">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/invoices" element={<InvoiceList />} />
              <Route path="/invoices/:id" element={<InvoiceDetails />} />
              <Route path="/payments" element={<Payments />} />
              <Route path="/detailed" element={<DetailedAccounting />} />
              <Route path="/reports" element={<PlaceholderPage title="Raporty" icon="mdi:chart-line" description="Funkcja raportów będzie dostępna wkrótce" />} />
              <Route path="/accounts" element={<PlaceholderPage title="Konta bankowe" icon="mdi:bank" description="Zarządzanie kontami bankowymi będzie dostępne wkrótce" />} />
              <Route path="/categories" element={<PlaceholderPage title="Kategorie" icon="mdi:tag-multiple" description="Zarządzanie kategoriami będzie dostępne wkrótce" />} />
              <Route path="/taxes" element={<PlaceholderPage title="Podatki" icon="mdi:calculator-variant" description="Kalkulacje podatkowe będą dostępne wkrótce" />} />
            </Routes>
          </main>
        </div>

        {/* Mobile Overlay */}
        {sidebarOpen && (
          <div className="fixed inset-0 z-40 bg-gray-600 bg-opacity-75 lg:hidden" onClick={() => setSidebarOpen(false)} />
        )}
      </div>
    </AdminOnly>
  );
};

export default Accounting; 