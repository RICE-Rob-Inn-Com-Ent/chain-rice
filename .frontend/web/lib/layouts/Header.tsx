import React from "react";

interface HeaderProps {
  children?: React.ReactNode;
}

/**
 * Header - Main layout skeleton component (Legacy - use app/Layout.tsx instead)
 * Provides the full page structure
 */
const Header: React.FC<HeaderProps> = ({ children }) => {
  return (
    <div className="flex min-h-screen flex-col">
      <main className="flex-1">{children}</main>
    </div>
  );
};

export default Header;
