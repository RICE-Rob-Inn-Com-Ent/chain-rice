import React, { useState } from 'react';
import { X, Menu, Settings } from 'lucide-react';
import Sidebar from '../web/src/navigations/Sidebar';
import TopBar from '../web/src/navigations/TopBar';

interface NavigationItem {
  id: string;
  name: string;
  icon: React.ComponentType<{ className?: string }>;
  description: string;
}

interface MainLayoutProps {
  children: React.ReactNode;
  navigation: NavigationItem[];
  activeTab: string;
  onTabChange: (tab: string) => void;
  title: string;
  subtitle: string;
}

const MainLayout: React.FC<MainLayoutProps> = ({
  children,
  navigation,
  activeTab,
  onTabChange,
  title,
  subtitle,
}) => {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <>
      {/* Mobile sidebar backdrop */}
      {sidebarOpen && (
        <div
          className="fixed inset-0 bg-black bg-opacity-50 z-40 lg:hidden"
          onClick={() => setSidebarOpen(false)}
        />
      )}

      {/* Sidebar */}
      <Sidebar
        navigation={navigation}
        activeTab={activeTab}
        onTabChange={onTabChange}
        sidebarOpen={sidebarOpen}
        setSidebarOpen={setSidebarOpen}
        title={title}
      />

      {/* Main content */}
      <div className="lg:pl-64">
        {/* Top bar */}
        <TopBar
          navigation={navigation}
          activeTab={activeTab}
          setSidebarOpen={setSidebarOpen}
          subtitle={subtitle}
        />

        {/* Page content */}
        <main className="p-4 sm:p-6 lg:p-8">
          {children}
        </main>
      </div>
    </>
  );
};

export default MainLayout;
