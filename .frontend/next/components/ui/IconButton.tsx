import React from 'react';

export interface IconButtonProps {
  icon: string;
  label?: string;
  onClick?: () => void;
  variant?: 'ghost' | 'primary' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

export const IconButton: React.FC<IconButtonProps> = ({
  icon,
  label,
  onClick,
  variant = 'ghost',
  size = 'md',
  className = '',
}) => {
  const base = 'inline-flex items-center justify-center rounded-md transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2';
  const variants = {
    ghost: 'text-gray-600 hover:bg-gray-100 focus:ring-blue-500',
    primary: 'bg-blue-600 text-white hover:bg-blue-700 focus:ring-blue-500',
    danger: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500',
  };
  const sizes = {
    sm: 'h-8 w-8 text-base',
    md: 'h-10 w-10 text-lg',
    lg: 'h-12 w-12 text-xl',
  };

  return (
    <button onClick={onClick} aria-label={label || icon} className={`${base} ${variants[variant]} ${sizes[size]} ${className}`}>
      <span className="material-icons">{icon}</span>
    </button>
  );
};

export default IconButton;
