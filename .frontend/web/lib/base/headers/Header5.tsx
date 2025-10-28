import React, { useState } from "react";
import { Icon } from "@iconify/react";

export interface HeaderProps {
  logo?: React.ReactNode;
  title?: string;
  menuItems?: Array<{ label: string; items: Array<{ label: string; icon?: string; onClick: () => void }> }>;
  actions?: React.ReactNode;
}

/**
 * Header5: Mega menu dropdown
 */
export const Header5: React.FC<HeaderProps> = ({ logo, title = "Dashboard", menuItems = [], actions }) => {
  const [openMenu, setOpenMenu] = useState<number | null>(null);

  return (
    <header className="w-full bg-theme-surface/80 backdrop-blur-lg border-b border-white/10">
      <div className="max-w-7xl mx-auto px-4 py-3">
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            {logo && <div className="text-3xl">{logo}</div>}
            <h1 className="text-xl font-bold text-theme-text">{title}</h1>
          </div>

          <nav className="hidden md:flex gap-1">
            {menuItems.map((menu, idx) => (
              <div key={idx} className="relative" onMouseLeave={() => setOpenMenu(null)}>
                <button
                  onMouseEnter={() => setOpenMenu(idx)}
                  className="px-4 py-2 text-theme-text hover:bg-white/10 rounded-lg transition font-medium"
                >
                  {menu.label}
                </button>
                {openMenu === idx && (
                  <div className="absolute top-full left-0 mt-1 bg-theme-surface border border-white/20 rounded-lg shadow-xl min-w-[200px] py-2">
                    {menu.items.map((item, itemIdx) => (
                      <button
                        key={itemIdx}
                        onClick={item.onClick}
                        className="w-full px-4 py-2 text-left text-theme-text hover:bg-white/10 transition flex items-center gap-2"
                      >
                        {item.icon && <Icon icon={item.icon} width={20} />}
                        {item.label}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </nav>

          {actions && <div className="flex gap-2">{actions}</div>}
        </div>
      </div>
    </header>
  );
};

