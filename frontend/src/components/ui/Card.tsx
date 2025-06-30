import React from 'react';
import { clsx } from 'clsx';

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  hover?: boolean;
  padding?: 'none' | 'sm' | 'md' | 'lg' | 'xl';
  shadow?: 'none' | 'sm' | 'md' | 'lg';
}

interface CardHeaderProps extends React.HTMLAttributes<HTMLDivElement> {
  divider?: boolean;
}

interface CardBodyProps extends React.HTMLAttributes<HTMLDivElement> {}

interface CardFooterProps extends React.HTMLAttributes<HTMLDivElement> {
  divider?: boolean;
}

const Card = React.forwardRef<HTMLDivElement, CardProps>(
  ({ children, className, hover = false, padding = 'md', shadow = 'md', ...props }, ref) => {
    const paddingClasses = {
      none: '',
      sm: 'p-3',
      md: 'p-4',
      lg: 'p-6',
      xl: 'p-8',
    };

    const shadowClasses = {
      none: '',
      sm: 'shadow-sm',
      md: 'shadow-soft',
      lg: 'shadow-soft-lg',
    };

    const classes = clsx(
      'bg-white dark:bg-gray-800 rounded-xl border border-gray-200 dark:border-gray-700',
      paddingClasses[padding],
      shadowClasses[shadow],
      {
        'transition-all duration-200 hover:shadow-soft-lg hover:-translate-y-0.5 cursor-pointer': hover,
      },
      className
    );

    return (
      <div ref={ref} className={classes} {...props}>
        {children}
      </div>
    );
  }
);

const CardHeader = React.forwardRef<HTMLDivElement, CardHeaderProps>(
  ({ children, className, divider = false, ...props }, ref) => {
    const classes = clsx(
      'flex items-center justify-between',
      {
        'border-b border-gray-200 dark:border-gray-700 pb-4 mb-4': divider,
      },
      className
    );

    return (
      <div ref={ref} className={classes} {...props}>
        {children}
      </div>
    );
  }
);

const CardBody = React.forwardRef<HTMLDivElement, CardBodyProps>(
  ({ children, className, ...props }, ref) => {
    const classes = clsx('flex-1', className);

    return (
      <div ref={ref} className={classes} {...props}>
        {children}
      </div>
    );
  }
);

const CardFooter = React.forwardRef<HTMLDivElement, CardFooterProps>(
  ({ children, className, divider = false, ...props }, ref) => {
    const classes = clsx(
      'flex items-center justify-between',
      {
        'border-t border-gray-200 dark:border-gray-700 pt-4 mt-4': divider,
      },
      className
    );

    return (
      <div ref={ref} className={classes} {...props}>
        {children}
      </div>
    );
  }
);

Card.displayName = 'Card';
CardHeader.displayName = 'CardHeader';
CardBody.displayName = 'CardBody';
CardFooter.displayName = 'CardFooter';

export { Card, CardHeader, CardBody, CardFooter };