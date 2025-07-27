import React from "react";
import { Link } from "react-router-dom";
import { Icon } from "@iconify/react";

export interface ClickConfig {
  type: "button" | "submit" | "reset";
  role?: "primary" | "secondary" | "ghost";
  state?: "pressed" | "loading" | "";
  ariaLabel: string;
  to?: string;
  icon?: string;
  children: React.ReactNode;
  onClick?: () => void;
}

export const Click: React.FC<ClickConfig> = ({
  type = "button",
  role = "primary",
  state= "",
  ariaLabel,
  to,
  icon,
  children,
  onClick,
}) => {
  const roleClasses = {
    "primary": "bg-blue-600 text-white hover:bg-blue-700",
    "secondary": "bg-gray-200 text-gray-800 hover:bg-gray-300",
    "ghost": "bg-transparent text-gray-700 hover:bg-gray-100 border border-gray-300 opacity-50 cursor-not-allowed pointer-events-none",
  };

  const stateClasses = {
    "": "",
    "pressed": "active:scale-[.98] active:opacity-90",
    "loading": "relative text-transparent pointer-events-none",
  };

  const className = `${roleClasses[role]} ${stateClasses[state]}`;

  if (to) {
    return (
      <Link to={to} className={className} aria-label={ariaLabel}>
        {icon && <Icon icon={icon} />}
        {children}
      </Link>
    );
  }

  return (
    <button
      type={type}
      className={className}
      aria-label={ariaLabel}
      onClick={onClick}
      disabled={role === "ghost"}
    >
      {icon && <Icon icon={icon} />}
      {children}
    </button>
  );
};
