import React from 'react';
import { TopBar, TopBarProps } from '../navigation/TopBar';
import { Sidebar, SidebarProps } from '../navigation/Sidebar';

export interface TopBarProps {
  title: string;
  tabs: { id: string; label: string }[];
  activeTab: string;
  onTabChange: (tabId: string) => void;
  onMenuClick: () => void;
  logoUrl?: string;
  showAuth?: boolean;
  onSignIn?: () => void;
  onSignUp?: () => void;
}

export interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
  items: { id: string; label: string; icon?: string; badge?: number }[];
  activeItem?: string;
}

export interface DashboardLayoutProps {
  children: React.ReactNode;
  topBarProps: TopBarProps;
  sidebarProps: SidebarProps;
}

export const DashboardLayout: React.FC<DashboardLayoutProps> = ({
  children,
  topBarProps,
  sidebarProps
}) => {
  return (
    <div className="min-h-screen bg-gray-100">
      <TopBar {...topBarProps} />

      <div className="flex">
        <Sidebar {...sidebarProps} />

        <main className="flex-1 md:ml-64 min-h-screen">
          {children}
        </main>
      </div>
    </div>
  );
};
