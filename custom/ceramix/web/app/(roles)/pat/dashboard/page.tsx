import { getCurrentUser } from "@/lib/auth";

export default async function PatientDashboard() {
  const user = await getCurrentUser();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-ivory-100">Witaj, {user?.display_name}!</h1>
        <p className="mt-2 text-ivory-100/60">Panel pacjenta - Ceramix</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
          <h3 className="text-lg font-semibold text-ivory-100">Nadchodzące wizyty</h3>
          <p className="mt-2 text-ivory-100/60">Brak zaplanowanych wizyt</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
          <h3 className="text-lg font-semibold text-ivory-100">Historia wizyt</h3>
          <p className="mt-2 text-ivory-100/60">Zobacz swoją historię leczenia</p>
        </div>

        <div className="rounded-lg border border-white/10 bg-obsidian-800/50 p-6">
          <h3 className="text-lg font-semibold text-ivory-100">Faktury</h3>
          <p className="mt-2 text-ivory-100/60">Dostęp do faktur i dokumentów</p>
        </div>
      </div>
    </div>
  );
}


