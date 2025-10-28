import React from "react";

export interface HeaderProps {
  logo?: React.ReactNode;
  title?: string;
  actions?: React.ReactNode;
}

/**
 * Header1: Centered with logo
 */
export const Header1: React.FC<HeaderProps> = ({ logo, title = "Dashboard", actions }) => {
  return (
    <header className="w-full bg-theme-surface/80 backdrop-blur-lg border-b border-white/10">
      <div className="max-w-7xl mx-auto px-4 py-4">
        <div className="flex flex-col items-center gap-3">
          {logo && <div className="text-4xl">{logo}</div>}
          <h1 className="text-2xl font-bold text-theme-text">{title}</h1>
          {actions && <div className="flex gap-2">{actions}</div>}
        </div>
      </div>
    </header>
  );
};
