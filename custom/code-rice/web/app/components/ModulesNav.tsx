import Link from "next/link";

const NAV_LINKS = [
  { href: "/modules", label: "Moduły firm" },
  { href: "/about", label: "O nas" },
  { href: "/prices", label: "Cennik" },
  { href: "/contact", label: "Kontakt" },
];

export function ModulesNav() {
  return (
    <div className="flex flex-wrap items-center gap-3 text-sm">
      {NAV_LINKS.map((link) => (
        <Link
          key={link.href}
          href={link.href}
          className="group relative rounded-full border border-white/10 bg-void-900/50 px-4 py-2 text-white/80 backdrop-blur-sm transition-all duration-300 hover:border-ion-400/50 hover:bg-void-900/70 hover:text-ion-200"
        >
          <span className="relative z-10">{link.label}</span>
          <span className="absolute inset-0 rounded-full bg-gradient-to-r from-ion-500/10 to-purple-500/10 opacity-0 transition-opacity group-hover:opacity-100" />
        </Link>
      ))}
      <Link
        href="/signin"
        className="group relative overflow-hidden rounded-full bg-gradient-to-r from-white to-ion-100 px-5 py-2 text-sm font-semibold text-void-900 shadow-md transition-all duration-300 hover:scale-105 hover:shadow-lg hover:shadow-ion-500/20"
      >
        <span className="relative z-10">Zaloguj się</span>
        <div className="absolute inset-0 bg-gradient-to-r from-ion-200 to-white opacity-0 transition-opacity group-hover:opacity-100" />
      </Link>
    </div>
  );
}


