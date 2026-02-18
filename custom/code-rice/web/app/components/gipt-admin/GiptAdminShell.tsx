"use client";

import type { ReactNode } from "react";
import { useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { BarChart3, BookOpen, Building2, Cloud, Database, FlaskRound, LayoutDashboard, LogOut } from "lucide-react";
import clsx from "clsx";

type NavItem = {
  label: string;
  href: string;
  icon: ReactNode;
  group: "primary" | "interfaces" | "resources";
};

const NAV_ITEMS: NavItem[] = [
  {
    label: "Dashboard",
    href: "/admin/dashboard",
    icon: <LayoutDashboard className="h-5 w-5" strokeWidth={1.75} />,
    group: "primary",
  },
  {
    label: "Geny",
    href: "/admin/training",
    icon: <FlaskRound className="h-5 w-5" strokeWidth={1.75} />,
    group: "primary",
  },
  {
    label: "Benchmark",
    href: "/admin/benchmark",
    icon: <BarChart3 className="h-5 w-5" strokeWidth={1.75} />,
    group: "primary",
  },
  {
    label: "Data Manager",
    href: "/admin/interfaces/data-manager",
    icon: <Database className="h-5 w-5" strokeWidth={1.75} />,
    group: "interfaces",
  },
  {
    label: "Knowledge Base",
    href: "/admin/interfaces/knowledge-base",
    icon: <BookOpen className="h-5 w-5" strokeWidth={1.75} />,
    group: "interfaces",
  },
  {
    label: "Cloud Manager",
    href: "/admin/interfaces/cloud-manager",
    icon: <Cloud className="h-5 w-5" strokeWidth={1.75} />,
    group: "interfaces",
  },
  {
    label: "Modules",
    href: "/modules",
    icon: <Building2 className="h-5 w-5" strokeWidth={1.75} />,
    group: "resources",
  },
];

export default function GiptAdminShell({ children }: { children: ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const [isLoggingOut, setIsLoggingOut] = useState(false);

  const handleLogout = async () => {
    if (isLoggingOut) return;
    
    setIsLoggingOut(true);
    try {
      const res = await fetch("/api/auth/logout", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
      });

      if (res.ok) {
        // Force full page reload to clear all state
        window.location.href = "/signin";
      } else {
        console.error("Logout failed");
        setIsLoggingOut(false);
      }
    } catch (error) {
      console.error("Logout error:", error);
      setIsLoggingOut(false);
    }
  };

  const renderNavGroup = (group: NavItem["group"]) => (
    <div className="flex flex-col gap-2" key={group}>
      {NAV_ITEMS.filter((item) => item.group === group).map((item) => {
        const isActive = pathname === item.href || (pathname?.startsWith(item.href) ?? false);

        return (
          <Link
            key={item.href}
            href={item.href}
            className={clsx(
              "group relative mx-2 flex items-center justify-center rounded-xl p-3.5 transition-all duration-300",
              isActive
                ? "bg-gradient-to-br from-purple-500/20 via-purple-500/10 to-transparent text-purple-300 shadow-[0_4px_20px_rgba(139,92,246,0.3)]"
                : "text-gray-500 hover:bg-white/5 hover:text-white",
            )}
            title={item.label}
            aria-label={item.label}
          >
            {/* Active indicator */}
            {isActive && (
              <div className="absolute left-0 top-1/2 h-8 w-1 -translate-y-1/2 rounded-r-full bg-gradient-to-b from-purple-400 to-pink-500 shadow-[0_0_12px_rgba(139,92,246,0.6)]" />
            )}
            
            {/* Hover glow effect */}
            {!isActive && (
              <div className="absolute inset-0 rounded-xl bg-gradient-to-br from-purple-500/10 to-pink-500/10 opacity-0 blur-xl transition-opacity duration-300 group-hover:opacity-100" />
            )}
            
            <div className={clsx(
              "relative z-10 transition-transform duration-300",
              isActive ? "scale-110" : "group-hover:scale-110"
            )}>
              {item.icon}
            </div>
          </Link>
        );
      })}
    </div>
  );

  return (
    <div className="flex min-h-screen bg-[#0a0a0f] text-white">
      {/* Animated background */}
      <div className="fixed inset-0 -z-10">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top,_rgba(139,92,246,0.15),transparent_50%)]" />
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_bottom_right,_rgba(99,102,241,0.1),transparent_50%)]" />
        <div className="absolute inset-0 bg-[linear-gradient(to_bottom_right,_rgba(15,23,42,0.8),rgba(30,27,75,0.4))]" />
      </div>

      <aside className="relative flex w-20 flex-col border-r border-white/5 bg-white/[0.02] backdrop-blur-2xl">
        {/* Sidebar glow effect */}
        <div className="absolute inset-0 bg-gradient-to-b from-purple-500/5 via-transparent to-transparent" />
        
        <div className="relative z-10 py-6 px-3">
          <div className="group relative mx-auto mb-3">
            <div className="absolute inset-0 rounded-2xl bg-gradient-to-br from-purple-500/30 to-pink-500/20 blur-xl opacity-0 transition-opacity group-hover:opacity-100" />
            <div className="relative flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-purple-600 via-purple-500 to-pink-500 shadow-[0_8px_32px_rgba(139,92,246,0.4)]">
              <span className="text-xl font-bold text-white">G</span>
            </div>
          </div>
          <div className="text-center">
            <div className="text-[10px] font-semibold tracking-[0.2em] text-purple-400/80">GiPT</div>
            <div className="text-[8px] font-medium tracking-wider text-purple-500/60">-1</div>
          </div>
        </div>

        <div className="relative z-10 flex-1 overflow-y-auto py-4">
          {renderNavGroup("primary")}
          <div className="mx-4 my-3 h-px bg-gradient-to-r from-transparent via-white/10 to-transparent" />
          {renderNavGroup("interfaces")}
          {NAV_ITEMS.some((item) => item.group === "resources") && (
            <>
              <div className="mx-4 my-3 h-px bg-gradient-to-r from-transparent via-white/10 to-transparent" />
              {renderNavGroup("resources")}
            </>
          )}
        </div>

        <div className="relative z-10 border-t border-white/5 px-2 py-3">
          <button
            onClick={handleLogout}
            disabled={isLoggingOut}
            className={clsx(
              "group relative mx-2 flex w-full items-center justify-center rounded-xl p-3 text-gray-400 transition-all duration-300",
              "hover:bg-red-500/10 hover:text-red-400",
              "before:absolute before:inset-0 before:rounded-xl before:bg-gradient-to-r before:from-red-500/20 before:to-pink-500/20 before:opacity-0 before:blur-xl before:transition-opacity before:duration-300",
              "hover:before:opacity-100",
              isLoggingOut && "opacity-50 cursor-not-allowed"
            )}
            title="Wyloguj się"
            aria-label="Wyloguj się"
          >
            <LogOut className="relative z-10 h-5 w-5 transition-transform duration-300 group-hover:scale-110" strokeWidth={2} />
          </button>
        </div>

        <div className="relative z-10 border-t border-white/5 px-3 py-4 text-center">
          <p className="text-[9px] font-medium tracking-[0.15em] text-white/30">© 2025</p>
          <p className="mt-1 text-[8px] font-medium tracking-wider text-white/20">Code-Rice</p>
        </div>
      </aside>

      <main className="relative flex min-h-screen flex-1 overflow-hidden">
        {/* Content area with subtle pattern */}
        <div className="absolute inset-0 bg-[linear-gradient(to_bottom,_rgba(15,23,42,0.4),rgba(30,27,75,0.2))]" />
        <div className="relative z-10 flex-1">{children}</div>
      </main>
    </div>
  );
}

