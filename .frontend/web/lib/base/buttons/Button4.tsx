import React from "react";

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
}

/**
 * Button4: Gradient
 */
export const Button4: React.FC<ButtonProps> = ({ children, className = "", ...props }) => {
  return (
    <button
      className={`px-6 py-3 bg-gradient-to-r from-theme-primary to-theme-secondary text-white rounded-lg font-semibold hover:opacity-90 transition shadow-lg disabled:opacity-50 disabled:cursor-not-allowed ${className}`}
      {...props}
    >
      {children}
    </button>
  );
};

