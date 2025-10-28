import React from "react";

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
  icon?: React.ReactNode;
}

/**
 * Button6: Icon right
 */
export const Button6: React.FC<ButtonProps> = ({ children, icon, className = "", ...props }) => {
  return (
    <button
      className={`px-6 py-3 bg-theme-primary text-white rounded-lg font-semibold hover:opacity-90 transition flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed ${className}`}
      {...props}
    >
      {children}
      {icon && <span className="text-xl">{icon}</span>}
    </button>
  );
};

