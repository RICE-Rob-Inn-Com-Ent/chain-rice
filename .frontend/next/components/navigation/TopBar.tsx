import React from 'react';

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
  tabsDisabled?: boolean;
}

export const TopBar: React.FC<TopBarProps> = ({
  title,
  tabs,
  activeTab,
  onTabChange,
  onMenuClick,
  logoUrl,
  showAuth = false,
  onSignIn,
  onSignUp,
  tabsDisabled = false
}) => {
  return (
    <header className="bg-gray-800 text-white p-4 flex justify-between items-center">
      <div className="flex items-center">
        <button
          onClick={onMenuClick}
          className="mr-4 text-2xl md:hidden"
        >
          ☰
        </button>

        {/* Logo */}
        {logoUrl && (
          <div className="flex items-center mr-6">
            <img
              src={logoUrl}
              alt="InfiniR Logo"
              className="h-10 w-auto"
            />
          </div>
        )}

        <h1 className="text-2xl font-bold">{title}</h1>
        <nav className="hidden md:flex ml-8 space-x-4">
          {tabs.map(tab => (
            <button
              key={tab.id}
              onClick={() => !tabsDisabled && onTabChange(tab.id)}
              disabled={tabsDisabled}
              className={`px-3 py-2 rounded-md text-sm font-medium ${
                activeTab === tab.id
                  ? 'bg-gray-900'
                  : 'hover:bg-gray-700'
              }`}
              style={tabsDisabled ? { opacity: 0.5, pointerEvents: 'none' } : undefined}
            >
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      <div className="flex items-center space-x-4">
        {/* Auth Buttons */}
        {showAuth && (
          <div className="flex items-center space-x-2">
            <button
              onClick={onSignIn}
              className="flex items-center space-x-1 px-3 py-2 text-sm font-medium text-gray-300 hover:text-white hover:bg-gray-700 rounded-md transition-colors"
            >
              <span className="material-icons text-lg">login</span>
              <span className="hidden sm:block">Sign In</span>
            </button>
            <button
              onClick={onSignUp}
              className="flex items-center space-x-1 px-3 py-2 text-sm font-medium bg-blue-600 hover:bg-blue-700 text-white rounded-md transition-colors"
            >
              <span className="material-icons text-lg">person_add</span>
              <span className="hidden sm:block">Sign Up</span>
            </button>
          </div>
        )}

        {/* User Profile (when not showing auth) */}
        {!showAuth && (
          <div className="relative">
            <button className="flex items-center space-x-2">
              <span className="hidden md:block">Jan Kowalski</span>
              <div className="w-8 h-8 rounded-full bg-blue-500 flex items-center justify-center">
                JK
              </div>
            </button>
          </div>
        )}
      </div>
    </header>
  );
};
