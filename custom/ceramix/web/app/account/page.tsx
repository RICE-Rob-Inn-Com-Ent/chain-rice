import { redirect } from "next/navigation";
import { getCurrentUser } from "@/lib/auth";
import { queryMany, query } from "@/lib/db";
import Link from "next/link";
import { Calendar, Clock, FileText, Heart, TrendingUp, Bell, Settings, Shield, Sparkles } from "lucide-react";

type Appointment = {
  id: string;
  appointment_number: string;
  appointment_date: Date;
  appointment_time: string;
  duration_minutes: number;
  status: string;
  treatment_type: string;
  dentist_first_name: string;
  dentist_last_name: string;
};

export default async function UserDashboard() {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/sign-in");
  }

  if (user.role !== "user") {
    redirect("/admin");
  }

  // Get user's appointments
  const appointments = await queryMany<Appointment>(
    `SELECT 
      a.id, a.appointment_number, a.appointment_date, a.appointment_time, 
      a.duration_minutes, a.status, a.treatment_type,
      d.first_name as dentist_first_name, d.last_name as dentist_last_name
     FROM appointments a
     JOIN dentists d ON a.dentist_id = d.id
     WHERE a.patient_id = $1
     ORDER BY a.appointment_date DESC, a.appointment_time DESC
     LIMIT 10`,
    [user.id]
  );

  // Get upcoming appointments
  const upcomingAppointments = appointments.filter(
    (apt: Appointment) => new Date(`${apt.appointment_date}T${apt.appointment_time}`) >= new Date()
  );

  // Get statistics
  const stats = await query<{ count: string }>(
    `SELECT COUNT(*) as count 
     FROM appointments a
     WHERE a.patient_id = $1 AND a.status = 'completed'`,
    [user.id]
  );

  const statusColors: Record<string, string> = {
    scheduled: "bg-blue-500/20 text-blue-400 border-blue-500/30",
    confirmed: "bg-green-500/20 text-green-400 border-green-500/30",
    in_progress: "bg-ember-500/20 text-ember-400 border-ember-500/30",
    completed: "bg-gray-500/20 text-gray-400 border-gray-500/30",
    cancelled: "bg-red-500/20 text-red-400 border-red-500/30",
    no_show: "bg-orange-500/20 text-orange-400 border-orange-500/30",
  };

  return (
    <div className="min-h-screen bg-[#050505]">
      {/* Header */}
      <header className="border-b border-[#f8f3e7]/10 bg-[#0f0f0f]/50 backdrop-blur-sm sticky top-0 z-50">
        <div className="container mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-[#eb520a] to-[#cb3906] rounded-lg flex items-center justify-center">
                <Sparkles className="w-6 h-6 text-white" />
              </div>
              <span className="text-2xl font-display font-bold text-[#f8f3e7]">Ceramix</span>
            </div>
            <div className="flex items-center gap-4">
              <Link
                href="/account/settings"
                className="p-2 rounded-lg hover:bg-white/5 transition-colors"
              >
                <Settings className="w-5 h-5 text-[#f8f3e7]/70" />
              </Link>
              <form action="/api/auth/logout" method="POST">
                <button
                  type="submit"
                  className="px-4 py-2 rounded-lg border border-[#f8f3e7]/20 text-[#f8f3e7]/70 hover:bg-white/5 transition-colors"
                >
                  Wyloguj
                </button>
              </form>
            </div>
          </div>
        </div>
      </header>

      <main className="container mx-auto px-6 py-8">
        {/* Welcome Section */}
        <div className="mb-8">
          <h1 className="text-4xl font-display font-bold text-[#f8f3e7] mb-2">
            Witaj, {user.display_name}!
          </h1>
          <p className="text-[#f8f3e7]/70">Zarządzaj swoimi wizytami i zdrowiem jamy ustnej</p>
        </div>

        {/* Quick Stats */}
        <div className="grid gap-6 md:grid-cols-3 mb-8">
          <div className="marble-card p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-[#f8f3e7]/60 mb-1">Nadchodzące wizyty</p>
                <p className="text-3xl font-bold text-[#f8f3e7]">{upcomingAppointments.length}</p>
              </div>
              <div className="rounded-full bg-blue-500/20 p-3">
                <Calendar className="h-6 w-6 text-blue-400" />
              </div>
            </div>
          </div>

          <div className="marble-card p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-[#f8f3e7]/60 mb-1">Zakończone wizyty</p>
                <p className="text-3xl font-bold text-[#f8f3e7]">{stats[0]?.count || "0"}</p>
              </div>
              <div className="rounded-full bg-green-500/20 p-3">
                <Heart className="h-6 w-6 text-green-400" />
              </div>
            </div>
          </div>

          <div className="marble-card p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-[#f8f3e7]/60 mb-1">Zdrowie jamy ustnej</p>
                <p className="text-3xl font-bold text-[#f8f3e7]">Dobre</p>
              </div>
              <div className="rounded-full bg-ember-500/20 p-3">
                <TrendingUp className="h-6 w-6 text-ember-400" />
              </div>
            </div>
          </div>
        </div>

        {/* Main Content Grid */}
        <div className="grid gap-6 lg:grid-cols-3">
          {/* Upcoming Appointments */}
          <div className="lg:col-span-2">
            <div className="marble-card p-6">
              <div className="flex items-center justify-between mb-6">
                <h2 className="text-2xl font-semibold text-[#f8f3e7]">Nadchodzące wizyty</h2>
                <Link
                  href="#umow-wizyte"
                  className="btn-primary text-sm py-2 px-4"
                >
                  Umów wizytę
                </Link>
              </div>

              {upcomingAppointments.length === 0 ? (
                <div className="text-center py-12">
                  <Calendar className="h-12 w-12 text-[#f8f3e7]/30 mx-auto mb-4" />
                  <p className="text-[#f8f3e7]/60 mb-4">Brak nadchodzących wizyt</p>
                  <Link href="#umow-wizyte" className="btn-primary text-sm">
                    Umów pierwszą wizytę
                  </Link>
                </div>
              ) : (
                <div className="space-y-4">
                  {upcomingAppointments.map((appointment) => {
                    const appointmentDateTime = new Date(
                      `${appointment.appointment_date}T${appointment.appointment_time}`
                    );
                    const endTime = new Date(
                      appointmentDateTime.getTime() + appointment.duration_minutes * 60000
                    );

                    return (
                      <div
                        key={appointment.id}
                        className="border border-[#f8f3e7]/10 rounded-lg p-4 hover:border-[#eb520a]/30 transition-colors"
                      >
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="flex items-center gap-3 mb-2">
                              <Clock className="h-4 w-4 text-[#f6823c]" />
                              <span className="font-semibold text-[#f8f3e7]">
                                {appointmentDateTime.toLocaleDateString("pl-PL", {
                                  weekday: "long",
                                  day: "numeric",
                                  month: "long",
                                })}
                              </span>
                            </div>
                            <p className="text-sm text-[#f8f3e7]/70 mb-1">
                              {appointmentDateTime.toLocaleTimeString("pl-PL", {
                                hour: "2-digit",
                                minute: "2-digit",
                              })}{" "}
                              -{" "}
                              {endTime.toLocaleTimeString("pl-PL", {
                                hour: "2-digit",
                                minute: "2-digit",
                              })}
                            </p>
                            <p className="text-sm text-[#f8f3e7]/80 mb-2">
                              Dr {appointment.dentist_first_name} {appointment.dentist_last_name}
                            </p>
                            {appointment.treatment_type && (
                              <p className="text-xs text-[#f8f3e7]/60">{appointment.treatment_type}</p>
                            )}
                          </div>
                          <span
                            className={`rounded-full px-3 py-1 text-xs font-medium border ${
                              statusColors[appointment.status] || "bg-gray-500/20 text-gray-400"
                            }`}
                          >
                            {appointment.status === "scheduled"
                              ? "Zaplanowana"
                              : appointment.status === "confirmed"
                              ? "Potwierdzona"
                              : appointment.status}
                          </span>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>

          {/* Quick Actions & Health */}
          <div className="space-y-6">
            {/* Quick Actions */}
            <div className="marble-card p-6">
              <h3 className="text-lg font-semibold text-[#f8f3e7] mb-4">Szybkie akcje</h3>
              <div className="space-y-3">
                <Link
                  href="#umow-wizyte"
                  className="flex items-center gap-3 p-3 rounded-lg bg-white/5 hover:bg-white/10 transition-colors"
                >
                  <Calendar className="h-5 w-5 text-[#f6823c]" />
                  <span className="text-[#f8f3e7]">Umów wizytę</span>
                </Link>
                <Link
                  href="/account/history"
                  className="flex items-center gap-3 p-3 rounded-lg bg-white/5 hover:bg-white/10 transition-colors"
                >
                  <FileText className="h-5 w-5 text-[#f6823c]" />
                  <span className="text-[#f8f3e7]">Historia wizyt</span>
                </Link>
                <Link
                  href="/account/health"
                  className="flex items-center gap-3 p-3 rounded-lg bg-white/5 hover:bg-white/10 transition-colors"
                >
                  <Heart className="h-5 w-5 text-[#f6823c]" />
                  <span className="text-[#f8f3e7]">Moje zdrowie</span>
                </Link>
                <Link
                  href="/account/settings"
                  className="flex items-center gap-3 p-3 rounded-lg bg-white/5 hover:bg-white/10 transition-colors"
                >
                  <Settings className="h-5 w-5 text-[#f6823c]" />
                  <span className="text-[#f8f3e7]">Ustawienia</span>
                </Link>
              </div>
            </div>

            {/* Health Tips */}
            <div className="marble-card p-6 bg-gradient-to-br from-blue-500/10 to-purple-500/10 border-blue-500/20">
              <div className="flex items-center gap-2 mb-3">
                <Sparkles className="h-5 w-5 text-blue-400" />
                <h3 className="text-lg font-semibold text-[#f8f3e7]">Wskazówki zdrowotne</h3>
              </div>
              <p className="text-sm text-[#f8f3e7]/80 mb-2">
                Pamiętaj o regularnym myciu zębów 2 razy dziennie przez minimum 2 minuty.
              </p>
              <p className="text-xs text-[#f8f3e7]/60">
                Następna kontrola: za 6 miesięcy
              </p>
            </div>

            {/* Security */}
            <div className="marble-card p-6">
              <div className="flex items-center gap-2 mb-3">
                <Shield className="h-5 w-5 text-green-400" />
                <h3 className="text-lg font-semibold text-[#f8f3e7]">Bezpieczeństwo</h3>
              </div>
              <p className="text-sm text-[#f8f3e7]/70 mb-4">
                Twoje dane są bezpieczne i szyfrowane.
              </p>
              <Link
                href="/account/settings/security"
                className="text-sm text-[#f6823c] hover:text-[#eb520a] transition-colors"
              >
                Zarządzaj bezpieczeństwem →
              </Link>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

