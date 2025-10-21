import React from 'react';

export interface SidebarItem {
  id: string;
  label: string;
  icon?: string;
  badge?: number;
}

export interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
  items: SidebarItem[];
  activeItem?: string;
  onItemClick?: (itemId: string) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({
  isOpen,
  onClose,
  items,
  activeItem,
  onItemClick
}) => {
  return (
    <>
      {/* Overlay for mobile */}
      {isOpen && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 z-40 md:hidden"
          onClick={onClose}
          onKeyDown={(e) => e.key === 'Escape' && onClose()}
          role="button"
          tabIndex={0}
          aria-label="Close sidebar"
        />
      )}

      {/* Sidebar */}
      <aside className={`
        fixed top-0 left-0 h-full bg-gray-900 text-white z-50 transform transition-transform duration-300 ease-in-out
        ${isOpen ? 'translate-x-0' : '-translate-x-full'}
        md:translate-x-0 md:static md:z-auto
        w-64
      `}>
        <div className="p-4">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-bold">Menu</h2>
            <button
              onClick={onClose}
              className="md:hidden text-gray-400 hover:text-white"
            >
              <span className="material-icons">close</span>
            </button>
          </div>

          <nav className="space-y-2">
            {items.map(item => (
              <button
                key={item.id}
                onClick={() => {
                  onItemClick?.(item.id);
                  onClose(); // Close on mobile after selection
                }}
                className={`
                  w-full flex items-center justify-between px-3 py-2 rounded-md text-left transition-colors
                  ${activeItem === item.id
                    ? 'bg-gray-700 text-white'
                    : 'text-gray-300 hover:bg-gray-700 hover:text-white'
                  }
                `}
              >
                <div className="flex items-center space-x-3">
                  {item.icon && (
                    <span className="text-lg">{item.icon}</span>
                  )}
                  <span>{item.label}</span>
                </div>
                {item.badge && (
                  <span className="bg-blue-600 text-white text-xs rounded-full px-2 py-1 min-w-[20px] text-center">
                    {item.badge}
                  </span>
                )}
              </button>
            ))}
          </nav>
        </div>
      </aside>
    </>
  );
};
