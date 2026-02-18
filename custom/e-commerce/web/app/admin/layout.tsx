import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: {
    default: "MeoWTopia CRM",
    template: "%s | MeoWTopia CRM",
  },
};

const nav = [
  { href: "/admin", label: "Pulpit" },
  { href: "/admin/zamowienia", label: "Zamówienia" },
  { href: "/admin/klienci", label: "Klienci" },
  { href: "/admin/lojalnosc", label: "Program lojalnościowy" },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen bg-moss-950 text-foam-100">
      <aside className="hidden w-64 shrink-0 border-r border-white/10 bg-jungle-900/40 px-5 py-6 backdrop-blur xl:flex xl:flex-col">
        <Link href="/" className="text-lg font-semibold text-citrus-200">
          MeoWTopia CRM
        </Link>
        <nav className="mt-8 space-y-1 text-sm text-foam-200/80">
          {nav.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="block rounded-xl px-3 py-2 transition hover:bg-white/5 hover:text-foam-50"
            >
              {item.label}
            </Link>
          ))}
        </nav>
      </aside>
      <div className="flex flex-1 flex-col">
        <header className="flex flex-col gap-4 border-b border-white/10 bg-jungle-900/30 px-6 py-6 md:flex-row md:items-center md:justify-between">
          <div>
            <h1 className="text-lg font-semibold text-foam-50">Panel marki: MeoWTopia Flagship</h1>
            <p className="text-xs text-foam-200/70">Ostatnia synchronizacja marketplace 2 min temu</p>
          </div>
          <div className="flex items-center gap-3 text-xs text-foam-200/80">
            <Link href="/" className="rounded-full border border-white/15 px-3 py-1 hover:border-citrus-300 hover:text-citrus-200">
              Podgląd sklepu
            </Link>
            <button className="rounded-full border border-white/15 px-3 py-1 hover:border-citrus-300 hover:text-citrus-200">Ustawienia</button>
          </div>
        </header>
        <main className="flex flex-1 flex-col gap-6 bg-moss-950/60 px-6 py-8">{children}</main>
      </div>
    </div>
  );
}

