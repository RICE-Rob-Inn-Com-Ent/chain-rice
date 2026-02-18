"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useSession } from "next-auth/react";
import {
  LogOut,
} from "lucide-react";
import { Icon } from "@iconify/react";
import { signOut } from "next-auth/react";

interface PanelSidebarProps {
  userRole: string;
}

const menuItems = [
  {
    label: "Dashboard",
    href: "dashboard",
    icon: "material-symbols:empty-dashboard-outline-rounded",
    iconType: "iconify",
    roles: ["ADMIN", "MANAGER", "OWNER", "SUPERADMIN"],
  },
  {
    label: "Produkty",
    href: "products",
    icon: "material-symbols:inventory-2-outline-rounded",
    iconType: "iconify",
    roles: ["ADMIN", "MANAGER", "OWNER", "SUPERADMIN"],
  },
  {
    label: "Ustawienia dla bota",
    href: "bot-settings",
    icon: "material-symbols:smart-toy-outline-rounded",
    iconType: "iconify",
    roles: ["ADMIN", "OWNER", "SUPERADMIN"],
  },
  {
    label: "Settings",
    href: "settings",
    icon: "material-symbols:settings-rounded",
    iconType: "iconify",
    roles: ["ADMIN", "OWNER", "SUPERADMIN"],
  },
];

export default function PanelSidebar({ userRole }: PanelSidebarProps) {
  const pathname = usePathname();
  const { data: session } = useSession();
  const username = (session?.user as any)?.username || "";

  const filteredMenuItems = menuItems.filter((item) =>
    item.roles.includes(userRole)
  );

  // Extract current route from pathname (e.g., /adm_own/dashboard -> dashboard)
  const currentRoute = pathname.split("/").filter(Boolean)[1] || "dashboard";

  return (
    <aside className="group w-16 hover:w-64 bg-gray-900 text-white flex flex-col shadow-xl transition-all duration-300 ease-in-out overflow-hidden">
      <div className="p-4 border-b border-gray-800">
        {/* User section */}
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-blue-600 rounded-full flex items-center justify-center text-white font-semibold text-lg flex-shrink-0">
            {session?.user?.name?.charAt(0) || "A"}
          </div>
          <div className="flex-1 min-w-0 opacity-0 group-hover:opacity-100 transition-opacity duration-300 whitespace-nowrap">
            <p className="text-sm font-medium text-white truncate">
              {session?.user?.name || "Administrator"}
            </p>
            <p className="text-xs text-gray-400 truncate">
              {(session?.user as any)?.role || userRole || "ADMIN"}
            </p>
          </div>
        </div>
      </div>

      <nav className="flex-1 p-2 space-y-2">
        {filteredMenuItems.map((item) => {
          const href = `/${username}/${item.href}`;
          const isActive = currentRoute === item.href || pathname.startsWith(`/${username}/${item.href}/`);
          return (
            <Link
              key={item.href}
              href={href}
              className={`flex items-center gap-3 px-3 py-3 rounded-lg transition-colors ${
                isActive
                  ? "bg-blue-600 text-white shadow-md"
                  : "text-gray-300 hover:bg-gray-800 hover:text-white"
              }`}
            >
              <div className="flex-shrink-0">
                {item.iconType === "iconify" ? (
                  <Icon icon={item.icon as string} width="24" height="24" />
                ) : null}
              </div>
              <span className="font-medium whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                {item.label}
              </span>
            </Link>
          );
        })}
      </nav>

      <div className="p-2 border-t border-gray-800">
        <button
          onClick={async () => {
            // Clear all NextAuth cookies
            if (typeof document !== 'undefined') {
              document.cookie.split(";").forEach((c) => {
                const cookieName = c.trim().split("=")[0];
                if (cookieName.includes("next-auth")) {
                  document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=.meowtopia.ltd;`;
                  document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;`;
                  document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=panel.meowtopia.ltd;`;
                }
              });
            }
            await signOut({ callbackUrl: "/signin" });
          }}
          className="flex items-center gap-3 px-3 py-3 rounded-lg text-gray-300 hover:bg-red-600 hover:text-white transition-colors w-full"
        >
          <LogOut className="w-5 h-5 flex-shrink-0" />
          <span className="font-medium whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity duration-300">
            Wyloguj
          </span>
        </button>
      </div>
    </aside>
  );
}

