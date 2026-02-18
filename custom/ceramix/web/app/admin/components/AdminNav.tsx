"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useRouter } from "next/navigation";
import Icon from "@/app/components/Icon";

type AdminNavProps = {
  user: {
    id: string;
    role: string;
  };
};

export default function AdminNav({ user }: AdminNavProps) {
  const pathname = usePathname();
  const router = useRouter();

  const navItems = [
    {
      href: `/${user.username}`,
      icon: "dashboard",
      label: "Dashboard",
      show: true,
    },
    {
      href: `/${user.username}/accounting`,
      icon: "payments",
      label: "Księgowość",
      show: user.role === "admin" || user.role === "owner",
    },
    {
      href: `/${user.username}/users`,
      icon: "shield",
      label: "Użytkownicy",
      show: user.role === "admin" || user.role === "owner",
    },
    {
      href: "/admin/ai",
      icon: "smart_toy",
      label: "AI",
      show: user.role === "admin" || user.role === "owner",
    },
    {
      href: "/admin/langchain",
      icon: "hub",
      label: "LangChain",
      show: user.role === "admin" || user.role === "owner",
    },
    {
      href: "/admin/lora-training",
      icon: "psychology",
      label: "LoRA",
      show: user.role === "owner",
    },
  ].filter((item) => item.show);

  const handleLogout = async () => {
    await fetch("/api/auth/logout", { method: "POST" });
    router.push("/sign-in");
  };

  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 bg-obsidian-800/95 border-t border-white/10 backdrop-blur-sm z-50">
      <div className="flex items-center justify-around h-16">
        {navItems.map((item) => {
          const isActive = pathname === item.href;
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex flex-col items-center justify-center flex-1 h-full transition-colors ${
                isActive ? "text-ember-400" : "text-ivory-100/60"
              }`}
            >
              <Icon 
                icon={item.icon} 
                className={`text-[1.75rem] ${isActive ? "opacity-100" : "opacity-70"}`}
              />
            </Link>
          );
        })}
        <button
          onClick={handleLogout}
          className="flex flex-col items-center justify-center flex-1 h-full text-ivory-100/60 transition-colors"
        >
          <Icon icon="logout" className="text-[1.75rem]" />
        </button>
      </div>
    </nav>
  );
}

