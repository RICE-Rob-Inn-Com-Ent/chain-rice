import React from "react";
import { ClickConfig } from "../interfaces/Click";

export const Click: React.FC<ClickConfig> = ({
  variant = "button",
  size = "md",
  disabled = false,
  children,
  onClick,
}) => {
  const baseClasses = "inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50";
  
  const variantClasses = {
    button: "bg-primary text-primary-foreground hover:bg-primary/90",
    link: "text-primary underline-offset-4 hover:underline",
    icon: "h-10 w-10",
  };
  
  const sizeClasses = {
    sm: "h-9 px-3",
    md: "h-10 px-4 py-2",
    lg: "h-11 px-8",
  };

  const className = `${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]}`;

  return (
    <button
      className={className}
      disabled={disabled}
      onClick={onClick}
    >
      {children}
    </button>
  );
};
