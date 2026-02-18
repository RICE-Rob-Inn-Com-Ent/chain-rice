import { getCurrentUser } from "@/lib/auth";
import Link from "next/link";

export default async function DeveloperDashboard() {
  const user = await getCurrentUser();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-white">Witaj, {user?.display_name}!</h1>
        <p className="mt-2 text-white/60">Panel developera - RICE</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        <Link
          href="/modules"
          className="rounded-lg border border-white/10 bg-void-900/50 p-6 hover:bg-void-900/70 transition"
        >
          <h3 className="text-lg font-semibold text-white">Moduły</h3>
          <p className="mt-2 text-white/60">Przeglądaj i używaj modułów</p>
        </Link>

        <Link
          href={`/${user?.id}/projects`}
          className="rounded-lg border border-white/10 bg-void-900/50 p-6 hover:bg-void-900/70 transition"
        >
          <h3 className="text-lg font-semibold text-white">Moje Projekty</h3>
          <p className="mt-2 text-white/60">Zarządzaj swoimi projektami</p>
        </Link>

        <Link
          href={`/${user?.id}/genes`}
          className="rounded-lg border border-white/10 bg-void-900/50 p-6 hover:bg-void-900/70 transition"
        >
          <h3 className="text-lg font-semibold text-white">Geny</h3>
          <p className="mt-2 text-white/60">Pracuj z genami</p>
        </Link>
      </div>
    </div>
  );
}

