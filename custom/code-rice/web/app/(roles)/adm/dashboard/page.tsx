import { getCurrentUser } from "@/lib/auth";

export default async function AdminDashboard() {
  const user = await getCurrentUser();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-white">Witaj, {user?.display_name}!</h1>
        <p className="mt-2 text-white/60">Panel administratora - RICE</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        <div className="rounded-lg border border-white/10 bg-void-900/50 p-6">
          <h3 className="text-lg font-semibold text-white">Użytkownicy</h3>
          <p className="mt-2 text-white/60">Zarządzaj użytkownikami systemu</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-void-900/50 p-6">
          <h3 className="text-lg font-semibold text-white">Projekty</h3>
          <p className="mt-2 text-white/60">Zarządzaj projektami</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-void-900/50 p-6">
          <h3 className="text-lg font-semibold text-white">Moduły</h3>
          <p className="mt-2 text-white/60">Zarządzaj modułami systemu</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-void-900/50 p-6">
          <h3 className="text-lg font-semibold text-white">Infrastruktura</h3>
          <p className="mt-2 text-white/60">Kontrola infrastruktury</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-void-900/50 p-6">
          <h3 className="text-lg font-semibold text-white">Geny</h3>
          <p className="mt-2 text-white/60">Zarządzaj genami</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-void-900/50 p-6">
          <h3 className="text-lg font-semibold text-white">Raporty</h3>
          <p className="mt-2 text-white/60">Generuj raporty i analizy</p>
        </div>
      </div>
    </div>
  );
}

