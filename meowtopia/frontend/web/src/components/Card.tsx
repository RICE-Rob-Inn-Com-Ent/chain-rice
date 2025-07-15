import React from "react";

export interface CardProps {
  title?: string;
  subtitle?: string;
  children: React.ReactNode;
  className?: string;
  headerClassName?: string;
  bodyClassName?: string;
  footer?: React.ReactNode;
  footerClassName?: string;
  icon?: string;
  onClick?: () => void;
  hover?: boolean;
  shadow?: "sm" | "md" | "lg" | "xl";
}

const Card: React.FC<CardProps> = ({
  title,
  subtitle,
  children,
  className = "",
  headerClassName = "",
  bodyClassName = "",
  footer,
  footerClassName = "",
  icon,
  onClick,
  hover = false,
  shadow = "md",
}) => {
  const shadowClasses = {
    sm: "shadow-sm",
    md: "shadow",
    lg: "shadow-lg",
    xl: "shadow-xl",
  };

  const baseClasses = `bg-white rounded-lg border border-gray-200 ${shadowClasses[shadow]} ${className}`;
  const interactiveClasses = onClick || hover ? "cursor-pointer transition-all duration-200" : "";
  const hoverClasses = hover ? "hover:shadow-lg hover:border-gray-300" : "";

  return (
    <div className={`${baseClasses} ${interactiveClasses} ${hoverClasses}`} onClick={onClick}>
      {(title || subtitle || icon) && (
        <div className={`px-6 py-4 border-b border-gray-200 ${headerClassName}`}>
          <div className="flex items-center">
            {icon && (
              <div className="flex-shrink-0 mr-3">
                <span className="text-2xl">{icon}</span>
              </div>
            )}
            <div className="flex-1">
              {title && (
                <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
              )}
              {subtitle && (
                <p className="text-sm text-gray-600 mt-1">{subtitle}</p>
              )}
            </div>
          </div>
        </div>
      )}
      
      <div className={`px-6 py-4 ${bodyClassName}`}>
        {children}
      </div>
      
      {footer && (
        <div className={`px-6 py-4 border-t border-gray-200 bg-gray-50 ${footerClassName}`}>
          {footer}
        </div>
      )}
    </div>
  );
};

export default Card; 