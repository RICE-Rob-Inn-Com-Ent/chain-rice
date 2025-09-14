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
  PieChart as PieChartIcon,
} from 'lucide-react';
import { dashboardApi } from '../apis/accounting';
import { DashboardStats } from '../types/accounting';

const COLORS = [
  '#3b82f6',
  '#8b5cf6',
  '#10b981',
  '#f59e0b',
  '#ef4444',
  '#f97316',
];

const StatCard: React.FC<{
  title: string;
  value: string | number;
  icon: React.ReactNode;
  trend?: 'up' | 'down';
  trendValue?: string;
  color?: string;
}> = ({ title, value, icon, trend, trendValue, color = 'blue' }) => (
  <div className={`bg-white rounded-lg shadow-sm border border-gray-200 p-6`}>
    <div className='flex items-center justify-between'>
      <div>
        <p className='text-sm font-medium text-gray-600'>{title}</p>
        <p className='text-2xl font-bold text-gray-900 mt-1'>{value}</p>
        {trend && trendValue && (
          <div className='flex items-center mt-2'>
            {trend === 'up' ? (
              <TrendingUp className='h-4 w-4 text-green-500 mr-1' />
            ) : (
              <TrendingDown className='h-4 w-4 text-red-500 mr-1' />
            )}
            <span
              className={`text-sm ${trend === 'up' ? 'text-green-600' : 'text-red-600'}`}
            >
              {trendValue}
            </span>
          </div>
        )}
      </div>
      <div className={`p-3 rounded-lg bg-${color}-50`}>
        <div className={`text-${color}-600`}>{icon}</div>
      </div>
    </div>
  </div>
);

const Dashboard: React.FC = () => {
  const {
    data: stats,
    isLoading,
    error,
  } = useQuery<DashboardStats>({
    queryKey: ['dashboard-stats'],
    queryFn: () => dashboardApi.getStats(),
  });

  if (isLoading) {
    return (
      <div className='flex items-center justify-center h-64'>
        <div className='animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600'></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className='bg-red-50 border border-red-200 rounded-lg p-4'>
        <p className='text-red-600'>Помилка завантаження даних дашборду</p>
      </div>
    );
  }

  if (!stats) return null;

  // Format currency values
  const formatCurrency = (value: number) =>
    new Intl.NumberFormat('uk-UA', {
      style: 'currency',
      currency: 'UAH',
      minimumFractionDigits: 0,
    }).format(value);

  // Prepare data for charts
  const monthlyData = stats.monthly_data.map(item => ({
    ...item,
    revenue: Math.round(item.revenue),
    expenses: Math.round(item.expenses),
    profit: Math.round(item.profit),
  }));

  const categoryData = stats.category_expenses.map((item, index) => ({
    ...item,
    fill: COLORS[index % COLORS.length],
  }));

  return (
    <div className='space-y-6'>
      {/* Header */}
      <div className='flex items-center justify-between'>
        <div>
          <h1 className='text-3xl font-bold text-gray-900'>
            Дашборд бухгалтерії
          </h1>
          <p className='text-gray-600 mt-1'>
            Огляд фінансових показників та статистики
          </p>
        </div>
        <div className='flex items-center space-x-2 text-sm text-gray-500'>
          <Calendar className='h-4 w-4' />
          <span>
            Останнє оновлення: {new Date().toLocaleDateString('uk-UA')}
          </span>
        </div>
      </div>

      {/* Stats Cards */}
      <div className='grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6'>
        <StatCard
          title='Загальний дохід'
          value={formatCurrency(stats.total_revenue)}
          icon={<DollarSign className='h-6 w-6' />}
          color='green'
          trend='up'
          trendValue='+12.5%'
        />
        <StatCard
          title='Загальні витрати'
          value={formatCurrency(stats.total_expenses)}
          icon={<TrendingDown className='h-6 w-6' />}
          color='red'
          trend='down'
          trendValue='-3.2%'
        />
        <StatCard
          title='Чистий прибуток'
          value={formatCurrency(stats.net_profit)}
          icon={<TrendingUp className='h-6 w-6' />}
          color='blue'
          trend='up'
          trendValue='+8.7%'
        />
        <StatCard
          title='Всього інвойсів'
          value={stats.total_invoices}
          icon={<FileText className='h-6 w-6' />}
          color='purple'
        />
      </div>

      {/* Additional Stats */}
      <div className='grid grid-cols-1 md:grid-cols-3 gap-6'>
        <StatCard
          title='Очікуючі інвойси'
          value={stats.pending_invoices}
          icon={<Clock className='h-6 w-6' />}
          color='yellow'
        />
        <StatCard
          title='Прострочені інвойси'
          value={stats.overdue_invoices}
          icon={<AlertTriangle className='h-6 w-6' />}
          color='red'
        />
        <StatCard
          title='Місячний дохід'
          value={formatCurrency(stats.monthly_revenue)}
          icon={<Calendar className='h-6 w-6' />}
          color='green'
        />
      </div>

      {/* Charts */}
      <div className='grid grid-cols-1 lg:grid-cols-2 gap-6'>
        {/* Monthly Revenue/Expenses Chart */}
        <div className='bg-white rounded-lg shadow-sm border border-gray-200 p-6'>
          <h3 className='text-lg font-semibold text-gray-900 mb-4 flex items-center'>
            <TrendingUp className='h-5 w-5 mr-2 text-blue-600' />
            Дохід та витрати по місяцях
          </h3>
          <ResponsiveContainer width='100%' height={300}>
            <LineChart data={monthlyData}>
              <CartesianGrid strokeDasharray='3 3' />
              <XAxis dataKey='month' />
              <YAxis />
              <Tooltip
                formatter={(value: number, name: string) => [
                  formatCurrency(value),
                  name === 'revenue'
                    ? 'Дохід'
                    : name === 'expenses'
                      ? 'Витрати'
                      : 'Прибуток',
                ]}
              />
              <Legend />
              <Line
                type='monotone'
                dataKey='revenue'
                stroke='#10b981'
                strokeWidth={2}
                name='Дохід'
              />
              <Line
                type='monotone'
                dataKey='expenses'
                stroke='#ef4444'
                strokeWidth={2}
                name='Витрати'
              />
              <Line
                type='monotone'
                dataKey='profit'
                stroke='#3b82f6'
                strokeWidth={2}
                name='Прибуток'
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Monthly Bar Chart */}
        <div className='bg-white rounded-lg shadow-sm border border-gray-200 p-6'>
          <h3 className='text-lg font-semibold text-gray-900 mb-4 flex items-center'>
            <BarChart className='h-5 w-5 mr-2 text-purple-600' />
            Порівняння по місяцях
          </h3>
          <ResponsiveContainer width='100%' height={300}>
            <BarChart data={monthlyData}>
              <CartesianGrid strokeDasharray='3 3' />
              <XAxis dataKey='month' />
              <YAxis />
              <Tooltip
                formatter={(value: number, name: string) => [
                  formatCurrency(value),
                  name === 'revenue'
                    ? 'Дохід'
                    : name === 'expenses'
                      ? 'Витрати'
                      : 'Прибуток',
                ]}
              />
              <Legend />
              <Bar dataKey='revenue' fill='#10b981' name='Дохід' />
              <Bar dataKey='expenses' fill='#ef4444' name='Витрати' />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Category Expenses Pie Chart */}
      <div className='grid grid-cols-1 lg:grid-cols-2 gap-6'>
        <div className='bg-white rounded-lg shadow-sm border border-gray-200 p-6'>
          <h3 className='text-lg font-semibold text-gray-900 mb-4 flex items-center'>
            <PieChartIcon className='h-5 w-5 mr-2 text-orange-600' />
            Витрати по категоріях
          </h3>
          <ResponsiveContainer width='100%' height={300}>
            <PieChart>
              <Pie
                data={categoryData}
                cx='50%'
                cy='50%'
                labelLine={false}
                label={({ name, percentage }) =>
                  `${name} (${percentage.toFixed(1)}%)`
                }
                outerRadius={80}
                fill='#8884d8'
                dataKey='amount'
              >
                {categoryData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.fill} />
                ))}
              </Pie>
              <Tooltip
                formatter={(value: number) => [formatCurrency(value), 'Сума']}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Category List */}
        <div className='bg-white rounded-lg shadow-sm border border-gray-200 p-6'>
          <h3 className='text-lg font-semibold text-gray-900 mb-4'>
            Деталізація по категоріях
          </h3>
          <div className='space-y-3'>
            {stats.category_expenses.map((category, index) => (
              <div
                key={category.category}
                className='flex items-center justify-between'
              >
                <div className='flex items-center'>
                  <div
                    className='w-3 h-3 rounded-full mr-3'
                    style={{ backgroundColor: COLORS[index % COLORS.length] }}
                  />
                  <span className='text-sm font-medium text-gray-700'>
                    {category.category}
                  </span>
                </div>
                <div className='text-right'>
                  <div className='text-sm font-semibold text-gray-900'>
                    {formatCurrency(category.amount)}
                  </div>
                  <div className='text-xs text-gray-500'>
                    {category.percentage.toFixed(1)}%
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
