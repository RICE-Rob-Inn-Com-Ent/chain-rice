import React from 'react';
import { clsx } from 'clsx';

interface SpinnerProps {
  size?: 'sm' | 'md' | 'lg' | 'xl';
  className?: string;
}

interface SkeletonProps {
  height?: string | number;
  width?: string | number;
  className?: string;
  lines?: number;
}

interface LoadingPageProps {
  message?: string;
}

const Spinner: React.FC<SpinnerProps> = ({ size = 'md', className }) => {
  const sizeClasses = {
    sm: 'h-4 w-4',
    md: 'h-6 w-6',
    lg: 'h-8 w-8',
    xl: 'h-12 w-12',
  };

  return (
    <svg
      className={clsx('animate-spin', sizeClasses[size], className)}
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
    >
      <circle
        className="opacity-25"
        cx="12"
        cy="12"
        r="10"
        stroke="currentColor"
        strokeWidth="4"
      ></circle>
      <path
        className="opacity-75"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      ></path>
    </svg>
  );
};

const Dots: React.FC<SpinnerProps> = ({ size = 'md', className }) => {
  const sizeClasses = {
    sm: 'h-1 w-1',
    md: 'h-1.5 w-1.5',
    lg: 'h-2 w-2',
    xl: 'h-3 w-3',
  };

  return (
    <div className={clsx('flex space-x-1', className)}>
      <div className={clsx('bg-current rounded-full animate-bounce', sizeClasses[size])} style={{ animationDelay: '0ms' }}></div>
      <div className={clsx('bg-current rounded-full animate-bounce', sizeClasses[size])} style={{ animationDelay: '150ms' }}></div>
      <div className={clsx('bg-current rounded-full animate-bounce', sizeClasses[size])} style={{ animationDelay: '300ms' }}></div>
    </div>
  );
};

const Pulse: React.FC<SpinnerProps> = ({ size = 'md', className }) => {
  const sizeClasses = {
    sm: 'h-4 w-4',
    md: 'h-6 w-6',
    lg: 'h-8 w-8',
    xl: 'h-12 w-12',
  };

  return (
    <div className={clsx('bg-current rounded-full animate-pulse-gentle', sizeClasses[size], className)}></div>
  );
};

const Skeleton: React.FC<SkeletonProps> = ({ height = '1rem', width = '100%', className, lines = 1 }) => {
  if (lines > 1) {
    return (
      <div className={clsx('space-y-2', className)}>
        {Array.from({ length: lines }).map((_, index) => (
          <div
            key={index}
            className="loading-skeleton"
            style={{
              height,
              width: index === lines - 1 ? '75%' : width,
            }}
          />
        ))}
      </div>
    );
  }

  return (
    <div
      className={clsx('loading-skeleton', className)}
      style={{ height, width }}
    />
  );
};

const LoadingCard: React.FC = () => (
  <div className="card p-6 space-y-4">
    <div className="flex items-center space-x-4">
      <Skeleton width="3rem" height="3rem" className="rounded-full" />
      <div className="flex-1 space-y-2">
        <Skeleton height="1rem" width="60%" />
        <Skeleton height="0.75rem" width="40%" />
      </div>
    </div>
    <Skeleton lines={3} />
    <div className="flex justify-end space-x-2">
      <Skeleton width="5rem" height="2rem" className="rounded-lg" />
      <Skeleton width="5rem" height="2rem" className="rounded-lg" />
    </div>
  </div>
);

const LoadingTable: React.FC<{ rows?: number; cols?: number }> = ({ rows = 5, cols = 4 }) => (
  <div className="space-y-3">
    {/* Header */}
    <div className="grid gap-4" style={{ gridTemplateColumns: `repeat(${cols}, 1fr)` }}>
      {Array.from({ length: cols }).map((_, index) => (
        <Skeleton key={index} height="1rem" width="80%" />
      ))}
    </div>
    {/* Rows */}
    {Array.from({ length: rows }).map((_, rowIndex) => (
      <div key={rowIndex} className="grid gap-4" style={{ gridTemplateColumns: `repeat(${cols}, 1fr)` }}>
        {Array.from({ length: cols }).map((_, colIndex) => (
          <Skeleton key={colIndex} height="0.875rem" />
        ))}
      </div>
    ))}
  </div>
);

const LoadingPage: React.FC<LoadingPageProps> = ({ message = 'Loading...' }) => (
  <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900">
    <div className="text-center space-y-4">
      <Spinner size="xl" className="mx-auto text-primary-500" />
      <p className="text-lg text-gray-600 dark:text-gray-400">{message}</p>
    </div>
  </div>
);

export {
  Spinner,
  Dots,
  Pulse,
  Skeleton,
  LoadingCard,
  LoadingTable,
  LoadingPage,
};