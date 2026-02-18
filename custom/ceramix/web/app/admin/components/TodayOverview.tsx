import { queryMany } from "@/lib/db";
import { Calendar, Clock } from "lucide-react";

type TodayAppointment = {
  id: string;
  appointment_time: string;
  duration_minutes: number;
  status: string;
  patient_name: string;
  dentist_name: string;
};

const statusLabels: Record<string, string> = {
  scheduled: "Zaplanowana",
  confirmed: "Potwierdzona",
  in_progress: "W trakcie",
  completed: "Zakończona",
  cancelled: "Anulowana",
  no_show: "Nie stawił się",
};

const statusColors: Record<string, string> = {
  scheduled: "bg-blue-500/15 text-blue-300",
  confirmed: "bg-green-500/15 text-green-300",
  in_progress: "bg-amber-500/15 text-amber-300",
  completed: "bg-gray-500/15 text-gray-300",
  cancelled: "bg-red-500/15 text-red-300",
  no_show: "bg-orange-500/15 text-orange-300",
};

export default async function TodayOverview({ title = "Dzisiejszy podgląd" }: { title?: string }) {
  const todayAppointments = await queryMany<TodayAppointment>(
    `SELECT 
      a.id,
      to_char(a.appointment_time, 'HH24:MI') as appointment_time,
      a.duration_minutes,
      a.status,
      CONCAT(p.first_name, ' ', p.last_name) as patient_name,
      CONCAT(d.first_name, ' ', d.last_name) as dentist_name
     FROM appointments a
     JOIN users p ON p.id = a.patient_id::text
     JOIN dentists d ON d.id = a.dentist_id::text
     WHERE a.appointment_date = CURRENT_DATE
     ORDER BY a.appointment_time ASC
     LIMIT 8`
  );

  const list = Array.isArray(todayAppointments) ? todayAppointments : [];

  return (
    <div className="marble-card p-6">
      <div className="mb-4 flex items-center justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.3em] text-ivory-100/40">Kalendarz</p>
          <h2 className="text-xl font-semibold text-ivory-100">{title}</h2>
        </div>
        <Calendar className="h-5 w-5 text-ivory-100/50" />
      </div>
      {list.length === 0 ? (
        <p className="text-sm text-ivory-100/60">Brak umówionych wizyt na dziś.</p>
      ) : (
        <div className="space-y-3">
          {list.map((apt) => (
            <div key={apt.id} className="rounded-xl border border-white/10 bg-white/5 p-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-sm text-ivory-100/80">
                  <Clock className="h-4 w-4 text-ivory-100/40" />
                  <span>
                    {apt.appointment_time} · {apt.duration_minutes} min
                  </span>
                </div>
                <span
                  className={`rounded-full px-2 py-1 text-[11px] font-medium ${
                    statusColors[apt.status] || "bg-white/10 text-ivory-100"
                  }`}
                >
                  {statusLabels[apt.status] || apt.status}
                </span>
              </div>
              <div className="mt-2 text-sm text-ivory-100">
                <p className="font-semibold">{apt.patient_name}</p>
                <p className="text-ivory-100/70 text-xs">Lekarz: {apt.dentist_name}</p>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

