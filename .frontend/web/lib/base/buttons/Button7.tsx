import React from "react";
import { Icon } from "@iconify/react";

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  children: React.ReactNode;
  loading?: boolean;
}

/**
 * Button7: Loading spinner
 */
export const Button7: React.FC<ButtonProps> = ({ children, loading = false, className = "", ...props }) => {
  return (
    <button
      className={`px-6 py-3 bg-theme-primary text-white rounded-lg font-semibold hover:opacity-90 transition flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed ${className}`}
      disabled={loading || props.disabled}
      {...props}
    >
      {loading && <Icon icon="svg-spinners:90-ring-with-bg" width={20} />}
      {children}
    </button>
  );
};

