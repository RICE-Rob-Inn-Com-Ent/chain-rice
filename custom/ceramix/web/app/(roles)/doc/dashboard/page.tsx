import { getCurrentUser } from "@/lib/auth";

export default async function DoctorDashboard() {
  const user = await getCurrentUser();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-ivory-100">Witaj, {user?.display_name}!</h1>
        <p className="mt-2 text-ivory-100/60">Panel lekarza - Ceramix</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
          <h3 className="text-lg font-semibold text-ivory-100">Dzisiejsze wizyty</h3>
          <p className="mt-2 text-ivory-100/60">Sprawdź zaplanowane wizyty</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
          <h3 className="text-lg font-semibold text-ivory-100">Pacjenci</h3>
          <p className="mt-2 text-ivory-100/60">Zarządzaj pacjentami</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
          <h3 className="text-lg font-semibold text-ivory-100">Grafik</h3>
          <p className="mt-2 text-ivory-100/60">Zarządzaj swoim grafikiem</p>
        </div>
      </div>
    </div>
  );
}


