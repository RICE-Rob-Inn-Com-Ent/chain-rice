import { redirect } from "next/navigation";
import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";
import { getRoleFromId, getRolePrefix } from "@/lib/user-id-generator";
import { isAdminOrOwner, isOwner } from "@/lib/rbac";
import Icon from "@/app/components/Icon";

/**
 * Layout for /ceramix route (placówka name)
 * This replaces /ceramix route with placówka name-based routing
 */
export default async function CeramixLayout({ children }: { children: React.ReactNode }) {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/sign-in");
  }

  const role = getRoleFromId(user.id) || "user";
  const rolePrefix = getRolePrefix(role);
  
  // Redirect to role-specific UI if not admin/owner
  if (!isAdminOrOwner(user.id)) {
    const prefixMap: Record<string, string> = {
      PAT: "pat",
      DOC: "doc",
      USR: "pat",
    };
    const routePrefix = prefixMap[rolePrefix] || "pat";
    redirect(`/${routePrefix}/dashboard`);
  }

  return (
    <div className="flex min-h-screen bg-obsidian-900">
      {/* Desktop Sidebar */}
      <aside className="hidden lg:block w-64 border-r border-white/10 bg-obsidian-800/50">
        <div className="flex h-full flex-col">
          <div className="border-b border-white/10 p-6">
            <h1 className="font-display text-2xl text-ivory-100">Ceramix</h1>
            <p className="mt-1 text-sm text-ivory-100/60">{user.display_name}</p>
            <p className="mt-1 text-xs text-ivory-100/40 uppercase">{role === "owner" ? "Właściciel" : "Administrator"}</p>
          </div>
          <nav className="flex-1 space-y-1 p-4">
            <Link
              href={`/${user.username}`}
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
            >
              <Icon icon="dashboard" className="text-[1.5rem]" />
              <span>Dashboard</span>
            </Link>
            {isAdminOrOwner(user.id) && (
              <Link
                href={`/${user.username}/accounting`}
                className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
              >
                <Icon icon="payments" className="text-[1.5rem]" />
                <span>Księgowość</span>
              </Link>
            )}
            {isAdminOrOwner(user.id) && (
              <>
                <Link
                  href={`/${user.username}/users`}
                  className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
                >
                  <Icon icon="shield" className="text-[1.5rem]" />
                  <span>Użytkownicy</span>
                </Link>
              </>
            )}
            {isOwner(user.id) && (
              <Link
                href={`/${user.username}/settings`}
                className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
              >
                <Icon icon="settings" className="text-[1.5rem]" />
                <span>Ustawienia Systemu</span>
              </Link>
            )}
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

      {/* Main content */}
      <main className="flex-1 overflow-auto pb-20 lg:pb-8">
        <div className="mx-auto w-full max-w-7xl p-2 sm:p-4 lg:p-8">{children}</div>
      </main>
    </div>
  );
}

