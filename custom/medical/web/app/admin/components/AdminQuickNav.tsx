"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import Icon from "@/app/components/Icon";

export default function AdminQuickNav() {
  const pathname = usePathname();

  // Extract username from pathname if on username-based route
  const usernameMatch = pathname?.match(/^\/([^\/]+)/);
  const username = usernameMatch ? usernameMatch[1] : null;
  const isUsernameRoute = username && username !== 'admin' && !username.startsWith('_');
  
  // Build hrefs based on route type
  const basePath = isUsernameRoute ? `/${username}` : '/admin';
  
  const navItems = [
    {
      href: `${basePath}/accounting`,
      label: "Księgowość",
      icon: "account_balance",
      description: "Dashboard księgowy",
    },
    {
      href: `${basePath}/users`,
      label: "Użytkownicy",
      icon: "people",
      description: "Tabela użytkowników",
    },
    {
      href: `${basePath}/appointments`,
      label: "Wizyty",
      icon: "event",
      description: "Kalendarz rezerwacji",
    },
    {
      href: `${basePath}/lora-training`,
      label: "Trening Bota",
      icon: "psychology",
      description: "Interfejs danych treningowych",
    },
  ];

  // Check if we're on a users page (could be /admin/users or /username/users)
  const isUsersPage = pathname?.includes("/users") && !pathname?.includes("/users/");
  const isAccountingPage = pathname?.includes("/accounting");
  const isAppointmentsPage = pathname?.includes("/appointments");
  const isLoraTrainingPage = pathname?.includes("/lora-training");

  return (
    <div className="marble-card p-4 mb-6 w-full" style={{ display: 'block', visibility: 'visible', opacity: 1 }}>
      <div className="mb-3">
        <h2 className="text-sm font-semibold text-ivory-100/90 uppercase tracking-wider mb-1">
          Szybka Nawigacja
        </h2>
        <p className="text-xs text-ivory-100/50">
          Przejdź do innych sekcji panelu
        </p>
      </div>
      
      <nav className="flex flex-wrap gap-2">
        {navItems.map((item) => {
          let isActive = false;
          // Check if current pathname matches the item href or starts with it
          if (item.href.endsWith("/users")) {
            isActive = isUsersPage;
          } else if (item.href.endsWith("/accounting")) {
            isActive = isAccountingPage;
          } else if (item.href.endsWith("/appointments")) {
            isActive = isAppointmentsPage;
          } else if (item.href.endsWith("/lora-training")) {
            isActive = isLoraTrainingPage;
          } else {
            isActive = pathname === item.href || pathname?.startsWith(item.href + "/");
          }
          
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-2 px-4 py-2.5 rounded-lg transition-colors ${
                isActive
                  ? "bg-amber-500/20 text-amber-400 border border-amber-500/30"
                  : "text-ivory-100/70 hover:bg-white/5 hover:text-ivory-100 border border-white/10"
              }`}
            >
              <Icon icon={item.icon} className="text-lg flex-shrink-0" />
              <div className="flex flex-col">
                <div className="font-medium text-sm">{item.label}</div>
                <div className="text-xs text-ivory-100/50">
                  {item.description}
                </div>
              </div>
            </Link>
          );
        })}
      </nav>
    </div>
  );
}

