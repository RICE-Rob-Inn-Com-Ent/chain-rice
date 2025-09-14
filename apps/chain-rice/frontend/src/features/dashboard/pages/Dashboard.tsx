import React from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { 
  DollarSign, 
  FileText, 
  Clock, 
  AlertTriangle,
  TrendingUp,
  TrendingDown,
  Calendar,
  PieChart as PieChartIcon
} from 'lucide-react';
import { dashboardApi } from '../../../services/api/accounting';
import { DashboardStats } from '../../../types/accounting';
import StatCard from '../components/StatCard';
import MonthlyChart from '../components/MonthlyChart';
import CategoryChart from '../components/CategoryChart';

const COLORS = ['#3b82f6', '#8b5cf6', '#10b981', '#f59e0b', '#ef4444', '#f97316'];

const Dashboard: React.FC = () => {
  const { data: stats, isLoading, error } = useQuery<DashboardStats>({
    queryKey: ['dashboard-stats'],
    queryFn: () => dashboardApi.getStats(),
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-50 border border-red-200 rounded-lg p-4">
        <p className="text-red-600">Помилка завантаження даних дашборду</p>
      </div>
    );
  }

  if (!stats) return null;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Дашборд бухгалтерії</h1>
          <p className="text-gray-600 mt-1">Огляд фінансових показників та статистики</p>
        </div>
        <div className="flex items-center space-x-2 text-sm text-gray-500">
          <Calendar className="h-4 w-4" />
          <span>Останнє оновлення: {new Date().toLocaleDateString('uk-UA')}</span>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        <StatCard
          title="Загальний дохід"
          value={stats.total_revenue}
          icon={<DollarSign className="h-6 w-6" />}
          color="green"
          trend="up"
          trendValue="+12.5%"
        />
        <StatCard
          title="Загальні витрати"
          value={stats.total_expenses}
          icon={<TrendingDown className="h-6 w-6" />}
          color="red"
          trend="down"
          trendValue="-3.2%"
        />
        <StatCard
          title="Чистий прибуток"
          value={stats.net_profit}
          icon={<TrendingUp className="h-6 w-6" />}
          color="blue"
          trend="up"
          trendValue="+8.7%"
        />
        <StatCard
          title="Всього інвойсів"
          value={stats.total_invoices}
          icon={<FileText className="h-6 w-6" />}
          color="purple"
        />
      </div>

      {/* Additional Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <StatCard
          title="Очікуючі інвойси"
          value={stats.pending_invoices}
          icon={<Clock className="h-6 w-6" />}
          color="yellow"
        />
        <StatCard
          title="Прострочені інвойси"
          value={stats.overdue_invoices}
          icon={<AlertTriangle className="h-6 w-6" />}
          color="red"
        />
        <StatCard
          title="Місячний дохід"
          value={stats.monthly_revenue}
          icon={<Calendar className="h-6 w-6" />}
          color="green"
        />
      </div>

      {/* Charts */}
      <MonthlyChart monthlyData={stats.monthly_data} />
      
      {/* Category Charts */}
      <CategoryChart categoryData={stats.category_expenses} />
    </div>
  );
};

export default Dashboard;
