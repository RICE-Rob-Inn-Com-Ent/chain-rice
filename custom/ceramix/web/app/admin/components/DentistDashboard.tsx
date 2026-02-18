import { query } from "@/lib/db";
import { getCurrentUser } from "@/lib/auth";
import { Calendar, Clock, Users, TrendingUp } from "lucide-react";

export default async function DentistDashboard() {
  const user = await getCurrentUser();
  
  if (!user?.id) {
    return (
      <div>
        <header className="mb-8">
          <h1 className="font-display text-4xl text-ivory-100">Mój Dashboard</h1>
        </header>
        <div className="marble-card p-6">
          <p className="text-ivory-100/60">Nie można załadować danych użytkownika.</p>
        </div>
      </div>
    );
  }

  // First, get the dentist ID for this user
  const dentistResult = await query<{ id: string }>(
    `SELECT id FROM dentists WHERE user_id = $1 AND active = true LIMIT 1`,
    [user.id]
  );

  const dentistId = dentistResult[0]?.id;

  // Fetch statistics specific to dentist
  const [
    todayAppointmentsCount,
    upcomingAppointmentsCount,
    myPatientsCount,
    monthlyAppointmentsCount,
  ] = await Promise.all([
    dentistId
      ? query<{ count: string }>(
          `SELECT COUNT(*) as count FROM appointments 
           WHERE dentist_id = $1 AND appointment_date::date = CURRENT_DATE`,
          [dentistId]
        )
      : Promise.resolve([{ count: "0" }]),
    dentistId
      ? query<{ count: string }>(
          `SELECT COUNT(*) as count FROM appointments 
           WHERE dentist_id = $1 AND appointment_date >= CURRENT_DATE`,
          [dentistId]
        )
      : Promise.resolve([{ count: "0" }]),
    dentistId
      ? query<{ count: string }>(
          `SELECT COUNT(DISTINCT patient_id) as count FROM appointments 
           WHERE dentist_id = $1`,
          [dentistId]
        )
      : Promise.resolve([{ count: "0" }]),
    dentistId
      ? query<{ count: string }>(
          `SELECT COUNT(*) as count FROM appointments 
           WHERE dentist_id = $1 AND appointment_date >= DATE_TRUNC('month', CURRENT_DATE)`,
          [dentistId]
        )
      : Promise.resolve([{ count: "0" }]),
  ]);

  const stats = [
    {
      title: "Wizyty dzisiaj",
      value: Array.isArray(todayAppointmentsCount) ? todayAppointmentsCount[0]?.count : todayAppointmentsCount.rows?.[0]?.count || "0",
      icon: Clock,
      color: "text-blue-400",
      bgColor: "bg-blue-500/20",
    },
    {
      title: "Nadchodzące wizyty",
      value: Array.isArray(upcomingAppointmentsCount) ? upcomingAppointmentsCount[0]?.count : upcomingAppointmentsCount.rows?.[0]?.count || "0",
      icon: Calendar,
      color: "text-ember-400",
      bgColor: "bg-ember-500/20",
    },
    {
      title: "Moi pacjenci",
      value: Array.isArray(myPatientsCount) ? myPatientsCount[0]?.count : myPatientsCount.rows?.[0]?.count || "0",
      icon: Users,
      color: "text-green-400",
      bgColor: "bg-green-500/20",
    },
    {
      title: "Wizyty w tym miesiącu",
      value: Array.isArray(monthlyAppointmentsCount) ? monthlyAppointmentsCount[0]?.count : monthlyAppointmentsCount.rows?.[0]?.count || "0",
      icon: TrendingUp,
      color: "text-purple-400",
      bgColor: "bg-purple-500/20",
    },
  ];

  return (
    <div>
      <header className="mb-8">
        <h1 className="font-display text-4xl text-ivory-100">Mój Dashboard</h1>
        <p className="mt-2 text-ivory-100/70">Witaj, {user?.display_name}</p>
      </header>

      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.title} className="marble-card p-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-ivory-100/60">{stat.title}</p>
                  <p className="mt-2 text-3xl font-bold text-ivory-100">{stat.value}</p>
                </div>
                <div className={`rounded-full p-3 ${stat.bgColor}`}>
                  <Icon className={`h-6 w-6 ${stat.color}`} />
                </div>
              </div>
            </div>
          );
        })}
      </div>

      <div className="mt-8 marble-card p-6">
        <h2 className="mb-4 text-xl font-semibold text-ivory-100">Nadchodzące wizyty</h2>
        <div className="text-sm text-ivory-100/60">
          Szczegóły nadchodzących wizyt będą dostępne wkrótce.
        </div>
      </div>
    </div>
  );
}

