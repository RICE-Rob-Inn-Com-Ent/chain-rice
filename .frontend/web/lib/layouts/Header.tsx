"use client";
import React from "react";
import TopBar from "./TopBar";

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
      <TopBar />
      <main className="flex-1">{children}</main>
    </div>
  );
};

export default Header;
