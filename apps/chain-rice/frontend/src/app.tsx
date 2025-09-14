import React, { useState } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Toaster } from 'react-hot-toast';
import { 
  BarChart3, 
  FileText, 
  Settings, 
  Menu,
  X,
  TrendingUp,
  Receipt
} from 'lucide-react';
import Dashboard from './features/dashboard/pages/Dashboard';
import InvoiceManager from './features/invoices/pages/InvoiceManager';
import MainLayout from './layouts/MainLayout';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

const App: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'dashboard' | 'invoices'>('dashboard');

  const navigation = [
    {
      id: 'dashboard',
      name: 'Дашборд',
      icon: BarChart3,
      description: 'Статистика та графіки',
    },
    {
      id: 'invoices',
      name: 'Інвойси',
      icon: FileText,
      description: 'Управління рахунками',
    },
  ];

  const renderContent = () => {
    switch (activeTab) {
      case 'dashboard':
        return <Dashboard />;
      case 'invoices':
        return <InvoiceManager />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <QueryClientProvider client={queryClient}>
      <div className="min-h-screen bg-gray-50">
        <MainLayout
          navigation={navigation}
          activeTab={activeTab}
          onTabChange={setActiveTab}
          title="ChainRice"
          subtitle="Бухгалтерська система"
        >
          {renderContent()}
        </MainLayout>

        {/* Toast notifications */}
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 4000,
            style: {
              background: '#363636',
              color: '#fff',
            },
            success: {
              duration: 3000,
              iconTheme: {
                primary: '#10b981',
                secondary: '#fff',
              },
            },
            error: {
              duration: 5000,
              iconTheme: {
                primary: '#ef4444',
                secondary: '#fff',
              },
            },
          }}
        />
      </div>
    </QueryClientProvider>
  );
};

export default App;
