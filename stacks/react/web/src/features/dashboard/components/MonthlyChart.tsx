import React from 'react';
import {
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { TrendingUp, BarChart as BarChartIcon } from 'lucide-react';
import { MonthlyData } from '../../../types/accounting';
import { formatCurrency } from '../../../utils/formatters';

interface MonthlyChartProps {
  monthlyData: MonthlyData[];
}

const MonthlyChart: React.FC<MonthlyChartProps> = ({ monthlyData }) => {
  const data = monthlyData.map(item => ({
    ...item,
    revenue: Math.round(item.revenue),
    expenses: Math.round(item.expenses),
    profit: Math.round(item.profit),
  }));

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Monthly Revenue/Expenses Line Chart */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <TrendingUp className="h-5 w-5 mr-2 text-blue-600" />
          Дохід та витрати по місяцях
        </h3>
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="month" />
            <YAxis />
            <Tooltip 
              formatter={(value: number, name: string) => [
                formatCurrency(value), 
                name === 'revenue' ? 'Дохід' : name === 'expenses' ? 'Витрати' : 'Прибуток'
              ]}
            />
            <Legend />
            <Line 
              type="monotone" 
              dataKey="revenue" 
              stroke="#10b981" 
              strokeWidth={2}
              name="Дохід"
            />
            <Line 
              type="monotone" 
              dataKey="expenses" 
              stroke="#ef4444" 
              strokeWidth={2}
              name="Витрати"
            />
            <Line 
              type="monotone" 
              dataKey="profit" 
              stroke="#3b82f6" 
              strokeWidth={2}
              name="Прибуток"
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Monthly Bar Chart */}
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <BarChartIcon className="h-5 w-5 mr-2 text-purple-600" />
          Порівняння по місяцях
        </h3>
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={data}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis dataKey="month" />
            <YAxis />
            <Tooltip 
              formatter={(value: number, name: string) => [
                formatCurrency(value), 
                name === 'revenue' ? 'Дохід' : name === 'expenses' ? 'Витрати' : 'Прибуток'
              ]}
            />
            <Legend />
            <Bar dataKey="revenue" fill="#10b981" name="Дохід" />
            <Bar dataKey="expenses" fill="#ef4444" name="Витрати" />
          </BarChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
};

export default MonthlyChart;
