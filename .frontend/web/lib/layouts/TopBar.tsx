import React from "react";

/**
 * TopBar - Navigation bar (Legacy - use app/Layout.tsx sidebar instead)
 */
const TopBar: React.FC = () => {
  return (
    <nav className="sticky top-0 z-50 flex items-center justify-between border-b border-gray-200 bg-white px-4 py-3 shadow-sm dark:border-gray-700 dark:bg-gray-900">
      {/* Logo */}
      <div className="flex items-center space-x-2">
        <span className="text-2xl font-bold text-gray-900 dark:text-white">
          🌾 <span className="text-green-600 dark:text-green-400">RICE</span>
        </span>
      </div>

      {/* Navigation Links */}
      <div className="hidden space-x-6 md:flex">
        <a href="/" className="text-gray-700 hover:text-green-600 dark:text-gray-300 dark:hover:text-green-400">
          Home
        </a>
        <a href="/models" className="text-gray-700 hover:text-green-600 dark:text-gray-300 dark:hover:text-green-400">
          Modele AI
        </a>
        <a href="/pricing" className="text-gray-700 hover:text-green-600 dark:text-gray-300 dark:hover:text-green-400">
          Cennik
        </a>
        <a href="/contact" className="text-gray-700 hover:text-green-600 dark:text-gray-300 dark:hover:text-green-400">
          Kontakt
        </a>
      </div>

      {/* CTA Button */}
      <div className="flex items-center space-x-3">
        <button className="rounded bg-green-600 px-4 py-2 text-sm font-semibold text-white hover:bg-green-700 dark:bg-green-500 dark:hover:bg-green-600">
          God Manager
        </button>
      </div>
    </nav>
  );
};

export default TopBar;
