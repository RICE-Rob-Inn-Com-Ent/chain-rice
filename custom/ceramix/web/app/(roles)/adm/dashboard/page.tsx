import { getCurrentUser } from "@/lib/auth";

export default async function AdminDashboard() {
  const user = await getCurrentUser();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-ivory-100">Witaj, {user?.display_name}!</h1>
        <p className="mt-2 text-ivory-100/60">Panel administratora - Ceramix</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
          <h3 className="text-lg font-semibold text-ivory-100">Użytkownicy</h3>
          <p className="mt-2 text-ivory-100/60">Zarządzaj użytkownikami systemu</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
          <h3 className="text-lg font-semibold text-ivory-100">Księgowość</h3>
          <p className="mt-2 text-ivory-100/60">Zarządzaj finansami i fakturami</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
          <h3 className="text-lg font-semibold text-ivory-100">Wizyty</h3>
          <p className="mt-2 text-ivory-100/60">Zarządzaj wizytami i grafikiem</p>
        </div>
      </div>
    </div>
  );
}


