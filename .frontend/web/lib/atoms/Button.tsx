import React from 'react';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost';
}

export const Button: React.FC<ButtonProps> = ({ variant = 'primary', children, ...rest }) => {
  const base = 'px-4 py-2 rounded-md font-medium focus:outline-none';
  const vClass =
    variant === 'primary'
      ? 'bg-blue-600 text-white hover:bg-blue-700'
      : variant === 'secondary'
        ? 'bg-gray-100 text-gray-800 hover:bg-gray-200'
        : 'bg-transparent text-gray-800';

  return (
    <button className={`${base} ${vClass}`} {...rest}>
      {children}
    </button>
  );
};

export default Button;
