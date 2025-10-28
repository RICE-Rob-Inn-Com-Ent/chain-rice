import React from "react";

export interface HeaderProps {
  logo?: React.ReactNode;
  title?: string;
  nav?: React.ReactNode;
  actions?: React.ReactNode;
}

/**
 * Header2: Left-aligned with nav
 */
export const Header2: React.FC<HeaderProps> = ({ logo, title = "Dashboard", nav, actions }) => {
  return (
    <header className="w-full bg-theme-surface/80 backdrop-blur-lg border-b border-white/10">
      <div className="max-w-7xl mx-auto px-4 py-4">
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            {logo && <div className="text-3xl">{logo}</div>}
            <h1 className="text-xl font-bold text-theme-text">{title}</h1>
          </div>
          {nav && <nav className="flex-1 flex justify-center">{nav}</nav>}
          {actions && <div className="flex gap-2">{actions}</div>}
        </div>
      </div>
    </header>
  );
};
