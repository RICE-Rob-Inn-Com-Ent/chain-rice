"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import Icon from "@/app/components/Icon";

export default function AppointmentsNav() {
  const pathname = usePathname();

  const navItems = [
    {
      href: "/admin/accounting",
      label: "Księgowość",
      icon: "account_balance",
      description: "Dashboard księgowy",
    },
    {
      href: "/admin/users",
      label: "Użytkownicy",
      icon: "people",
      description: "Tabela użytkowników",
    },
    {
      href: "/admin/lora-training",
      label: "Trening Bota",
      icon: "psychology",
      description: "Interfejs danych treningowych",
    },
  ];

  return (
    <div className="marble-card p-4">
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
          const isActive = pathname === item.href;
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

