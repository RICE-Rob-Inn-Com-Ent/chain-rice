import React from "react";

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
}

/**
 * Button10: Pill shaped
 */
export const Button10: React.FC<ButtonProps> = ({ children, className = "", ...props }) => {
  return (
    <button
      className={`px-8 py-3 bg-theme-primary text-white rounded-full font-semibold hover:opacity-90 transition shadow-lg disabled:opacity-50 disabled:cursor-not-allowed ${className}`}
      {...props}
    >
      {children}
    </button>
  );
};

