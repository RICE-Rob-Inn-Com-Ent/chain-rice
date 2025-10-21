import React from 'react';

export interface StatCardProps {
  title: string;
  value: string;
  change?: string;
  type?: 'increase' | 'decrease' | 'neutral';
  icon?: string;
}

export const StatCard: React.FC<StatCardProps> = ({
  title,
  value,
  change,
  type = 'neutral',
  icon
}) => {
  const changeColor = {
    increase: 'text-green-600',
    decrease: 'text-red-600',
    neutral: 'text-gray-600'
  };

  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-600">{title}</p>
          <p className="text-2xl font-bold text-gray-900">{value}</p>
          {change && (
            <p className={`text-sm ${changeColor[type]}`}>
              {change}
            </p>
          )}
        </div>
        {icon && (
          <div className="text-3xl text-gray-400">
            <span className="material-icons">{icon}</span>
          </div>
        )}
      </div>
    </div>
  );
};
