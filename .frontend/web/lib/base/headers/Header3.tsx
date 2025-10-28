import React from "react";

export interface HeaderProps {
  logo?: React.ReactNode;
  title?: string;
  actions?: React.ReactNode;
}

/**
 * Header3: Transparent overlay
 */
export const Header3: React.FC<HeaderProps> = ({ logo, title = "Dashboard", actions }) => {
  return (
    <header className="w-full absolute top-0 left-0 z-50">
      <div className="max-w-7xl mx-auto px-4 py-6">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            {logo && <div className="text-3xl drop-shadow-lg">{logo}</div>}
            <h1 className="text-2xl font-bold text-white drop-shadow-lg">{title}</h1>
          </div>
          {actions && <div className="flex gap-2">{actions}</div>}
        </div>
      </div>
    </header>
  );
};
