import React, { useState } from 'react';
import { TopBar } from '../navigation/TopBar';
import { Sidebar } from '../navigation/Sidebar';
import { useUiConfig } from '../config/ConfigProvider';

export interface AppShellProps {
  children: React.ReactNode;
  tabs?: { id: string; label: string }[];
  sidebarItems?: { id: string; label: string; icon?: string; badge?: number }[];
  title?: string;
}

export const AppShell: React.FC<AppShellProps> = ({ children, tabs = [], sidebarItems = [], title }) => {
  const [activeTab, setActiveTab] = useState(tabs[0]?.id ?? 'home');
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const config = useUiConfig();

  return (
    <div className="min-h-screen bg-gray-100">
      <TopBar
        title={title || config.appName}
        tabs={tabs}
        activeTab={activeTab}
        onTabChange={setActiveTab}
        onMenuClick={() => setSidebarOpen((v) => !v)}
        logoUrl={config.logoUrl}
        showAuth={config.showAuthButtons}
      />

      <div className="flex">
        <Sidebar
          isOpen={sidebarOpen}
          onClose={() => setSidebarOpen(false)}
          items={sidebarItems}
          activeItem={sidebarItems[0]?.id}
        />

        <main className="flex-1 md:ml-64 min-h-screen">{children}</main>
      </div>
    </div>
  );
};

export default AppShell;
