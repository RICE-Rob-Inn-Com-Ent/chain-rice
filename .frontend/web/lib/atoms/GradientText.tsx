import React from "react";

const GradientText: React.FC<{ children: React.ReactNode; className?: string }> = ({ children, className = "" }) => {
  return <span className={`highlighted-text ${className}`}>{children}</span>;
};

export default GradientText;
