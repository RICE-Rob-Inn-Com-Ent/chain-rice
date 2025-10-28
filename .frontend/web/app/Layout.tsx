import React, { useState } from "react";
import { Icon } from "@iconify/react";

export interface LayoutProps {
  children: React.ReactNode;
  currentPage: string;
  onNavigate: (page: string) => void;
}

const navItems = [
  { id: "dashboard", icon: "mdi:view-dashboard", label: "Dashboard" },
  { id: "models", icon: "mdi:robot", label: "Models" },
  { id: "lora", icon: "mdi:dna", label: "LoRA Training" },
  { id: "prices", icon: "mdi:currency-usd", label: "Prices" },
  { id: "components", icon: "mdi:palette", label: "Components" },
];

export const Layout: React.FC<LayoutProps> = ({ children, currentPage, onNavigate }) => {
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900">
      {/* Sidebar Navigation */}
      <aside
        className={`fixed left-0 top-0 h-screen bg-black/30 backdrop-blur-lg border-r border-white/10 transition-all duration-300 z-50 ${
          sidebarCollapsed ? "w-16" : "w-64"
        }`}
      >
        {/* Header */}
        <div className="p-4 border-b border-white/10 flex items-center justify-between">
          {!sidebarCollapsed && (
            <div className="flex items-center gap-2">
              <span className="text-2xl">🏺</span>
              <h1 className="text-lg font-bold text-white">Egyptian AI</h1>
            </div>
          )}
          {sidebarCollapsed && <span className="text-2xl mx-auto">🏺</span>}
          <button
            onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
            className="text-white/70 hover:text-white transition"
            title={sidebarCollapsed ? "Expand sidebar" : "Collapse sidebar"}
          >
            <Icon icon={sidebarCollapsed ? "mdi:chevron-right" : "mdi:chevron-left"} width={24} />
          </button>
        </div>

        {/* Navigation */}
        <nav className="p-2 space-y-1">
          {navItems.map((item) => (
            <button
              key={item.id}
              onClick={() => onNavigate(item.id)}
              className={`w-full flex items-center gap-3 px-3 py-3 rounded-lg transition ${
                currentPage === item.id
                  ? "bg-white/20 text-white"
                  : "text-white/70 hover:bg-white/10 hover:text-white"
              }`}
              title={sidebarCollapsed ? item.label : ""}
            >
              <Icon icon={item.icon} width={24} className="flex-shrink-0" />
              {!sidebarCollapsed && <span className="font-medium">{item.label}</span>}
            </button>
          ))}
        </nav>

        {/* Footer */}
        {!sidebarCollapsed && (
          <div className="absolute bottom-0 left-0 right-0 p-4 border-t border-white/10">
            <div className="text-xs text-white/50 text-center">
              <p>© 2024 Code-Rice</p>
              <p className="mt-1">Powered by Ollama</p>
            </div>
          </div>
        )}
      </aside>

      {/* Main Content */}
      <main
        className={`transition-all duration-300 ${sidebarCollapsed ? "ml-16" : "ml-64"}`}
        style={{ minHeight: "100vh" }}
      >
        {children}
      </main>
    </div>
  );
};

