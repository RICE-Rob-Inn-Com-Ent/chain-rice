import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { getRoleFromId } from "@/lib/user-id-generator";
import Link from "next/link";

export default async function DoctorLayout({ children }: { children: React.ReactNode }) {
  // This layout is deprecated - redirect to username-based routing
  const user = await getCurrentUser();

  if (!user) {
    redirect("/sign-in");
  }

  // Immediately redirect to /me which will redirect to username-based route
  redirect("/me");

  return (
    <div className="flex min-h-screen bg-obsidian-900">
      <aside className="hidden lg:block w-64 border-r border-white/10 bg-obsidian-800/50">
        <div className="flex h-full flex-col">
          <div className="border-b border-white/10 p-6">
            <h1 className="font-display text-2xl text-ivory-100">Ceramix</h1>
            <p className="mt-1 text-sm text-ivory-100/60">{user.display_name}</p>
            <p className="mt-1 text-xs text-ivory-100/40 uppercase">Lekarz</p>
          </div>
          <nav className="flex-1 space-y-1 p-4">
            <Link
              href="/doc/dashboard"
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
            >
              <Icon icon="dashboard" className="text-[1.5rem]" />
              <span>Dashboard</span>
            </Link>
            <Link
              href="/doc/appointments"
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
            >
              <Icon icon="event" className="text-[1.5rem]" />
              <span>Wizyty</span>
            </Link>
            <Link
              href="/doc/patients"
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
            >
              <Icon icon="people" className="text-[1.5rem]" />
              <span>Pacjenci</span>
            </Link>
            <Link
              href="/doc/schedule"
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
            >
              <Icon icon="calendar_month" className="text-[1.5rem]" />
              <span>Grafik</span>
            </Link>
          </nav>
          <div className="border-t border-white/10 p-4">
            <form action="/api/auth/logout" method="POST">
              <button
                type="submit"
                className="flex w-full items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
              >
                <Icon icon="logout" className="text-[1.5rem]" />
                <span>Wyloguj</span>
              </button>
            </form>
          </div>
        </div>
      </aside>
      <main className="flex-1 overflow-auto pb-20 lg:pb-8">
        <div className="mx-auto w-full max-w-7xl p-2 sm:p-4 lg:p-8">{children}</div>
      </main>
    </div>
  );
}


