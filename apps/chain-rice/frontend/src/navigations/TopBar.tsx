import React from 'react';
import { Menu, Settings } from 'lucide-react';

interface NavigationItem {
  id: string;
  name: string;
  icon: React.ComponentType<{ className?: string }>;
  description: string;
}

interface TopBarProps {
  navigation: NavigationItem[];
  activeTab: string;
  setSidebarOpen: (open: boolean) => void;
  subtitle: string;
}

const TopBar: React.FC<TopBarProps> = ({
  navigation,
  activeTab,
  setSidebarOpen,
  subtitle,
}) => {
  const currentNav = navigation.find(item => item.id === activeTab);

  return (
    <div className="sticky top-0 z-40 bg-white border-b border-gray-200">
      <div className="flex items-center justify-between h-16 px-4 sm:px-6 lg:px-8">
        <div className="flex items-center">
          <button
            onClick={() => setSidebarOpen(true)}
            className="lg:hidden text-gray-500 hover:text-gray-700"
          >
            <Menu className="w-6 h-6" />
          </button>
          <div className="ml-4 lg:ml-0">
            <h2 className="text-lg font-semibold text-gray-900">
              {currentNav?.name}
            </h2>
            <p className="text-sm text-gray-500">
              {currentNav?.description || subtitle}
            </p>
          </div>
        </div>

        <div className="flex items-center space-x-4">
          {/* Status indicator */}
          <div className="flex items-center space-x-2">
            <div className="w-2 h-2 bg-green-500 rounded-full"></div>
            <span className="text-sm text-gray-500">Система активна</span>
          </div>

          {/* Settings button */}
          <button className="p-2 text-gray-500 hover:text-gray-700 rounded-lg hover:bg-gray-100">
            <Settings className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
};

export default TopBar;
