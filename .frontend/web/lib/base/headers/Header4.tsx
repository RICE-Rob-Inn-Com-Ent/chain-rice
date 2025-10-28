import React from "react";

export interface HeaderProps {
  logo?: React.ReactNode;
  title?: string;
  nav?: React.ReactNode;
  actions?: React.ReactNode;
}

/**
 * Header4: Sticky with shadow
 */
export const Header4: React.FC<HeaderProps> = ({ logo, title = "Dashboard", nav, actions }) => {
  return (
    <header className="w-full sticky top-0 z-50 bg-theme-surface/95 backdrop-blur-lg border-b border-white/10 shadow-xl">
      <div className="max-w-7xl mx-auto px-4 py-3">
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            {logo && <div className="text-3xl">{logo}</div>}
            <h1 className="text-xl font-bold text-theme-text">{title}</h1>
          </div>
          {nav && <nav className="hidden md:flex flex-1 justify-center gap-6">{nav}</nav>}
          {actions && <div className="flex gap-2">{actions}</div>}
        </div>
      </div>
    </header>
  );
};

