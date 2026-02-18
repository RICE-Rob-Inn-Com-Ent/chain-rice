import { redirect } from "next/navigation";
import Link from "next/link";
import { getCurrentUser } from "@/lib/auth";
import { getRoleFromId, getRolePrefix } from "@/lib/user-id-generator";
import { isAdminOrOwner, isOwner } from "@/lib/rbac";
import dynamic from "next/dynamic";
import Icon from "@/app/components/Icon";

// Lazy load AdminNav for better performance
const AdminNav = dynamic(() => import("./components/AdminNav"), {
  ssr: false,
  loading: () => null,
});

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
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
    <div className="flex min-h-screen bg-obsidian-900 relative">
      {/* Desktop Sidebar - Fixed to left */}
      <aside className="hidden lg:block fixed left-0 top-0 h-screen w-64 border-r border-white/10 bg-obsidian-800/50 z-30">
        <div className="flex h-full flex-col">
          <div className="border-b border-white/10 p-6">
            <div className="flex items-center gap-3 mb-4">
              {/* Avatar */}
              <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-bold text-lg flex-shrink-0">
                {user.display_name?.charAt(0)?.toUpperCase() || user.username?.charAt(0)?.toUpperCase() || "A"}
              </div>
              <div className="flex-1 min-w-0">
                <h1 className="font-display text-xl text-ivory-100 truncate">{user.display_name || user.username || "Administrator"}</h1>
                <p className="text-xs text-ivory-100/50 truncate">@{user.username}</p>
              </div>
            </div>
            <p className="text-xs text-ivory-100/40 uppercase font-medium">{user.role}</p>
          </div>
          <nav className="flex-1 space-y-1 p-4 overflow-y-auto">
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
                  href="/admin/appointments"
                  className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
                >
                  <Icon icon="event" className="text-[1.5rem]" />
                  <span>Wizyty</span>
                </Link>
                <Link
                  href={`/${user.username}/users`}
                  className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
                >
                  <Icon icon="shield" className="text-[1.5rem]" />
                  <span>Użytkownicy</span>
                </Link>
                <Link
                  href="/admin/ai"
                  className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
                >
                  <Icon icon="smart_toy" className="text-[1.5rem]" />
                  <span>CerAI - Asystent AI</span>
                </Link>
                <Link
                  href="/admin/langchain"
                  className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
                >
                  <Icon icon="hub" className="text-[1.5rem]" />
                  <span>LangChain</span>
                </Link>
              </>
            )}
            {isOwner(user.id) && (
              <>
                <Link
                  href="/admin/lora-training"
                  className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
                >
                  <Icon icon="psychology" className="text-[1.5rem]" />
                  <span>LoRA Training</span>
                </Link>
                <Link
                  href="/admin/bot-settings"
                  className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
                >
                  <Icon icon="tune" className="text-[1.5rem]" />
                  <span>Ustawienia Botów</span>
                </Link>
                <Link
                  href={`/${user.username}/settings`}
                  className="flex items-center gap-3 rounded-lg px-4 py-3 text-ivory-100/70 transition hover:bg-white/5 hover:text-ivory-100"
                >
                  <Icon icon="settings" className="text-[1.5rem]" />
                  <span>Ustawienia Systemu</span>
                </Link>
              </>
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

      {/* Main content - Relative with left margin for sidebar */}
      <main className="flex-1 overflow-auto pb-20 lg:pb-8 relative lg:ml-64">
        <div className="mx-auto w-full max-w-7xl p-2 sm:p-4 lg:p-8">
          {children}
        </div>
      </main>

      {/* Mobile Bottom Navigation */}
      <AdminNav user={user} />
    </div>
  );
}

