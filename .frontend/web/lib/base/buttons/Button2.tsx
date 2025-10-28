import React from "react";

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
}

/**
 * Button2: Outline
 */
export const Button2: React.FC<ButtonProps> = ({ children, className = "", ...props }) => {
  return (
    <button
      className={`px-6 py-3 bg-transparent border-2 border-theme-primary text-theme-primary rounded-lg font-semibold hover:bg-theme-primary hover:text-white transition disabled:opacity-50 disabled:cursor-not-allowed ${className}`}
      {...props}
    >
      {children}
    </button>
  );
};

