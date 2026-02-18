import { redirect } from "next/navigation";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { getRoleFromId } from "@/lib/user-id-generator";
import Link from "next/link";

export default async function ManagerLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession(authOptions);

  if (!session?.user?.email) {
    redirect("/signin");
  }

  const user = await prisma.user.findUnique({
    where: { email: session.user.email },
  });

  if (!user) {
    redirect("/signin");
  }

  const role = getRoleFromId(user.id)?.toUpperCase() || "CUSTOMER";
  if (role !== "MANAGER") {
    const rolePrefix = role === "OWNER" || role === "SUPERADMIN" ? "own" : role === "ADMIN" ? "adm" : role === "VOLUNTEER" ? "vol" : role === "CUSTOMER" ? "cus" : role === "ARTIST" ? "art" : "mgr";
    redirect(`/${user.id}`);
  }

  return (
    <div className="flex min-h-screen bg-jungle-950">
      <aside className="hidden lg:block w-64 border-r border-white/10 bg-jungle-900/50">
        <div className="flex h-full flex-col">
          <div className="border-b border-white/10 p-6">
            <h1 className="font-display text-2xl text-foam-50">MeoWTopia</h1>
            <p className="mt-1 text-sm text-foam-100/60">{user.name || user.email}</p>
            <p className="mt-1 text-xs text-foam-100/40 uppercase">Manager</p>
          </div>
          <nav className="flex-1 space-y-1 p-4">
            <Link
              href={`/${user.id}/dashboard`}
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-foam-100/70 transition hover:bg-white/5 hover:text-foam-50"
            >
              <span className="material-symbols-outlined text-[1.5rem]">home</span>
              <span>Dashboard</span>
            </Link>
            <Link
              href={`/${user.id}/products`}
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-foam-100/70 transition hover:bg-white/5 hover:text-foam-50"
            >
              <span className="material-symbols-outlined text-[1.5rem]">inventory</span>
              <span>Produkty</span>
            </Link>
            <Link
              href={`/${user.id}/orders`}
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-foam-100/70 transition hover:bg-white/5 hover:text-foam-50"
            >
              <span className="material-symbols-outlined text-[1.5rem]">shopping_cart</span>
              <span>Zamówienia</span>
            </Link>
            <Link
              href={`/${user.id}/inventory`}
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-foam-100/70 transition hover:bg-white/5 hover:text-foam-50"
            >
              <span className="material-symbols-outlined text-[1.5rem]">warehouse</span>
              <span>Magazyn</span>
            </Link>
            <Link
              href={`/${user.id}/reports`}
              className="flex items-center gap-3 rounded-lg px-4 py-3 text-foam-100/70 transition hover:bg-white/5 hover:text-foam-50"
            >
              <span className="material-symbols-outlined text-[1.5rem]">assessment</span>
              <span>Raporty</span>
            </Link>
          </nav>
          <div className="border-t border-white/10 p-4">
            <form action="/api/auth/signout" method="POST">
              <button
                type="submit"
                className="flex w-full items-center gap-3 rounded-lg px-4 py-3 text-foam-100/70 transition hover:bg-white/5 hover:text-foam-50"
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

