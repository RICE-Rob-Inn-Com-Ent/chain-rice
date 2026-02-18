import { query } from "@/lib/db";
import { Users, Calendar, DollarSign, Stethoscope } from "lucide-react";
import TodayOverview from "./TodayOverview";

export default async function AdminDashboard() {
  // Fetch statistics for admin
  const [patientsCount, dentistsCount, appointmentsCount, invoicesCount] = await Promise.all([
    query<{ count: string }>(`
      SELECT COUNT(*) as count 
      FROM users u
      WHERE NOT EXISTS (
        (u.id::text LIKE 'ADM-%' OR u.id::text LIKE 'SUP-%' OR u.id::text LIKE 'DOC-%')
      )
    `),
    query<{ count: string }>(`SELECT COUNT(*) as count FROM dentists WHERE active = true`),
    query<{ count: string }>(`SELECT COUNT(*) as count FROM appointments WHERE appointment_date >= CURRENT_DATE`),
    query<{ count: string }>(`SELECT COUNT(*) as count FROM invoices WHERE status = 'paid' AND issue_date >= DATE_TRUNC('month', CURRENT_DATE)`),
  ]);

  const stats = [
    {
      title: "Pacjenci",
      value: patientsCount.rows[0]?.count || "0",
      icon: Users,
      color: "text-blue-400",
      bgColor: "bg-blue-500/20",
    },
    {
      title: "Dentyści",
      value: dentistsCount.rows[0]?.count || "0",
      icon: Stethoscope,
      color: "text-green-400",
      bgColor: "bg-green-500/20",
    },
    {
      title: "Nadchodzące wizyty",
      value: appointmentsCount.rows[0]?.count || "0",
      icon: Calendar,
      color: "text-ember-400",
      bgColor: "bg-ember-500/20",
    },
    {
      title: "Faktury (miesiąc)",
      value: invoicesCount.rows[0]?.count || "0",
      icon: DollarSign,
      color: "text-purple-400",
      bgColor: "bg-purple-500/20",
    },
  ];

  return (
    <div>
      <header className="mb-8">
        <h1 className="font-display text-4xl text-ivory-100">Dashboard Admin</h1>
        <p className="mt-2 text-ivory-100/70">Zarządzanie kliniką i pacjentami</p>
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

      <div className="mt-8">
        <TodayOverview title="Dzisiejsze wizyty" />
      </div>
    </div>
  );
}

