"use client";
import React from "react";
import Navbar from "./Navbar";
import Footer from "./Footer";

interface HeaderProps {
  children?: React.ReactNode;
}

/**
 * Header - Main layout skeleton component
 * Provides the full page structure: Navbar -> Main content -> Footer
 */
const Header: React.FC<HeaderProps> = ({ children }) => {
  return (
    <header className="flex min-h-screen flex-col">
      <Navbar />
    </header>
  );
};

export default Header;
