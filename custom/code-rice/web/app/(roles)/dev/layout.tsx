import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { getRoleFromId } from "@/lib/user-id-generator";
import Link from "next/link";

export default async function DeveloperLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/signin");
  }

  const role = getRoleFromId(user.id) || "user";
  if (role !== "developer") {
    const rolePrefix = role === "owner" ? "own" : role === "admin" ? "adm" : role === "manager" ? "mgr" : "dev";
    redirect(`/${user.id}`);
  }

  return (
    <div className="flex min-h-screen bg-void-950">
      <aside className="hidden lg:block w-64 border-r border-white/10 bg-void-900/50">
        <div className="flex h-full flex-col">
          <div className="border-b border-white/10 p-6">
            <h1 className="font-display text-2xl text-white">RICE</h1>
            <p className="mt-1 text-sm text-white/60">{user.display_name}</p>
            <p className="mt-1 text-xs text-white/40 uppercase">Developer</p>
          </div>
          <nav className="flex-1 space-y-1 p-4">
            <Link
              href={`/${user.id}/dashboard`}
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-white/70 transition hover:bg-white/5 hover:text-white"
            >
              <span className="material-symbols-outlined text-[1.5rem]">home</span>
              <span>Dashboard</span>
            </Link>
            <Link
              href="/modules"
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-white/70 transition hover:bg-white/5 hover:text-white"
            >
              <span className="material-symbols-outlined text-[1.5rem]">apps</span>
              <span>Moduły</span>
            </Link>
            <Link
              href={`/${user.id}/projects`}
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-white/70 transition hover:bg-white/5 hover:text-white"
            >
              <span className="material-symbols-outlined text-[1.5rem]">folder</span>
              <span>Moje Projekty</span>
            </Link>
            <Link
              href={`/${user.id}/genes`}
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-white/70 transition hover:bg-white/5 hover:text-white"
            >
              <span className="material-symbols-outlined text-[1.5rem]">science</span>
              <span>Geny</span>
            </Link>
          </nav>
          <div className="border-t border-white/10 p-4">
            <form action="/api/auth/logout" method="POST">
              <button
                type="submit"
                className="flex w-full items-center gap-3 rounded-lg px-4 py-3 text-white/70 transition hover:bg-white/5 hover:text-white"
              >
                <span className="material-symbols-outlined text-[1.5rem]">logout</span>
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

