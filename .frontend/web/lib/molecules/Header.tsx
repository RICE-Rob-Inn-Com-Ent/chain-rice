'use client';
import React from 'react';
import Footer from './Footer';

interface HeaderProps {
  children?: React.ReactNode;
}

/**
 * Header - Main layout skeleton component
 * Provides the full page structure: Navbar -> Main content -> Footer
 */
const Header: React.FC<HeaderProps> = ({ children }) => {
  return (
    <div className="flex min-h-screen flex-col">
      {/* Navigation bar at the top */}

      {/* Main content area with top padding to account for fixed navbar */}
      <main className="flex-1 pt-24">{children}</main>

      {/* Footer at the bottom */}
      <Footer />
    </div>
  );
};

export default Header;
