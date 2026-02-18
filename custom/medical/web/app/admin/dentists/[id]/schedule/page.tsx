"use client";

import { useState, useEffect } from "react";
import { useParams } from "next/navigation";
import { Calendar, Clock, User, ChevronLeft, ChevronRight, Plus, X } from "lucide-react";
import { format, startOfWeek, addDays, addWeeks, subWeeks, isSameDay, parseISO } from "date-fns";
import { pl } from "date-fns/locale";

interface Appointment {
  id: string;
  appointment_date: string;
  appointment_time: string;
  duration_minutes: number;
  patient_first_name: string;
  patient_last_name: string;
  treatment_type: string;
  status: string;
}

export default function DentistSchedulePage() {
  const params = useParams();
  const dentistId = params.id as string;
  const [currentWeek, setCurrentWeek] = useState(new Date());
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [selectedSlot, setSelectedSlot] = useState<{ date: Date; time: string } | null>(null);
  const [loading, setLoading] = useState(true);
  const [currentUserId, setCurrentUserId] = useState<string | null>(null);

  const weekStart = startOfWeek(currentWeek, { weekStartsOn: 1 });
  const weekDays = Array.from({ length: 7 }, (_, i) => addDays(weekStart, i));
  const timeSlots = Array.from({ length: 16 }, (_, i) => {
    const hour = 8 + i;
    return `${hour.toString().padStart(2, "0")}:00`;
  });

  useEffect(() => {
    // Load current user ID
    const loadUserId = async () => {
      try {
        const res = await fetch("/api/auth/me");
        const data = await res.json();
        if (res.ok && data.user?.id) {
          setCurrentUserId(data.user.id);
        }
      } catch (err) {
        console.error("Failed to load user ID:", err);
      }
    };
    loadUserId();
    fetchAppointments();
  }, [dentistId, currentWeek]);

  const fetchAppointments = async () => {
    setLoading(true);
    try {
      const weekEnd = addDays(weekStart, 6);
      const res = await fetch(
        `/api/dentists/${dentistId}/appointments?start=${weekStart.toISOString()}&end=${weekEnd.toISOString()}`
      );
      const data = await res.json();
      setAppointments(data.appointments || []);
    } catch (error) {
      console.error("Error fetching appointments:", error);
    } finally {
      setLoading(false);
    }
  };

  const getAppointmentsForSlot = (date: Date, time: string) => {
    return appointments.filter((apt) => {
      const aptDate = parseISO(apt.appointment_date);
      const [aptHour] = apt.appointment_time.split(":");
      const [slotHour] = time.split(":");
      return isSameDay(aptDate, date) && aptHour === slotHour;
    });
  };

  const handleSlotClick = (date: Date, time: string) => {
    setSelectedSlot({ date, time });
  };

  const handlePreviousWeek = () => {
    setCurrentWeek(subWeeks(currentWeek, 1));
  };

  const handleNextWeek = () => {
    setCurrentWeek(addWeeks(currentWeek, 1));
  };

  const handleToday = () => {
    setCurrentWeek(new Date());
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-display text-4xl text-ivory-100">Grafik lekarza</h1>
          <p className="mt-2 text-ivory-100/70">Zarządzaj wizytami w kalendarzu</p>
        </div>
        <div className="flex items-center gap-4">
          <button
            onClick={handleToday}
            className="px-4 py-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 hover:bg-white/10 transition-colors"
          >
            Dzisiaj
          </button>
          <div className="flex items-center gap-2">
            <button
              onClick={handlePreviousWeek}
              className="p-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 hover:bg-white/10 transition-colors"
            >
              <ChevronLeft className="h-5 w-5" />
            </button>
            <button
              onClick={handleNextWeek}
              className="p-2 rounded-lg border border-white/10 bg-white/5 text-ivory-100 hover:bg-white/10 transition-colors"
            >
              <ChevronRight className="h-5 w-5" />
            </button>
          </div>
        </div>
      </div>

      {/* Calendar */}
      <div className="marble-card p-6">
        <div className="mb-4 text-center">
          <h2 className="text-xl font-semibold text-ivory-100">
            {format(weekStart, "d MMMM", { locale: pl })} - {format(addDays(weekStart, 6), "d MMMM yyyy", { locale: pl })}
          </h2>
        </div>

        <div className="overflow-x-auto">
          <div className="min-w-[1200px]">
            {/* Header with days */}
            <div className="grid grid-cols-8 gap-2 mb-2">
              <div className="p-2"></div>
              {weekDays.map((day) => (
                <div
                  key={day.toISOString()}
                  className={`p-3 text-center rounded-lg ${
                    isSameDay(day, new Date())
                      ? "bg-ember-500/20 border border-ember-500/50"
                      : "bg-white/5"
                  }`}
                >
                  <div className="text-xs text-ivory-100/60 mb-1">
                    {format(day, "EEE", { locale: pl })}
                  </div>
                  <div className="text-lg font-semibold text-ivory-100">
                    {format(day, "d")}
                  </div>
                </div>
              ))}
            </div>

            {/* Time slots */}
            <div className="space-y-1">
              {timeSlots.map((time) => (
                <div key={time} className="grid grid-cols-8 gap-2">
                  <div className="p-2 text-sm text-ivory-100/60 flex items-center justify-end">
                    {time}
                  </div>
                  {weekDays.map((day) => {
                    const slotAppointments = getAppointmentsForSlot(day, time);
                    return (
                      <div
                        key={`${day.toISOString()}-${time}`}
                        onClick={() => handleSlotClick(day, time)}
                        className="min-h-[60px] p-1 border border-white/5 rounded hover:border-ember-500/50 hover:bg-ember-500/10 transition-colors cursor-pointer relative"
                      >
                        {slotAppointments.map((apt) => {
                          const startTime = parseISO(`${apt.appointment_date}T${apt.appointment_time}`);
                          const endTime = new Date(
                            startTime.getTime() + apt.duration_minutes * 60000
                          );
                          const [slotHour] = time.split(":");
                          const [aptHour] = apt.appointment_time.split(":");
                          const isStart = aptHour === slotHour;

                          if (!isStart) return null;

                          const durationSlots = Math.ceil(apt.duration_minutes / 60);
                          const statusColors: Record<string, string> = {
                            scheduled: "bg-blue-500/30 border-blue-500/50",
                            confirmed: "bg-green-500/30 border-green-500/50",
                            in_progress: "bg-ember-500/30 border-ember-500/50",
                            completed: "bg-gray-500/30 border-gray-500/50",
                            cancelled: "bg-red-500/30 border-red-500/50",
                          };

                          return (
                            <div
                              key={apt.id}
                              className={`absolute inset-x-1 rounded border p-2 text-xs ${
                                statusColors[apt.status] || "bg-gray-500/30"
                              }`}
                              style={{
                                height: `${durationSlots * 60 - 4}px`,
                                zIndex: 10,
                              }}
                            >
                              <div className="font-semibold text-white truncate">
                                {apt.patient_first_name} {apt.patient_last_name}
                              </div>
                              <div className="text-white/80 text-[10px] truncate">
                                {apt.treatment_type || "Wizyta"}
                              </div>
                              <div className="text-white/60 text-[10px]">
                                {format(startTime, "HH:mm")} - {format(endTime, "HH:mm")}
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    );
                  })}
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Legend */}
      <div className="marble-card p-4">
        <div className="flex items-center gap-6 flex-wrap">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-blue-500/30 border border-blue-500/50"></div>
            <span className="text-sm text-ivory-100/70">Zaplanowana</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-green-500/30 border border-green-500/50"></div>
            <span className="text-sm text-ivory-100/70">Potwierdzona</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-ember-500/30 border border-ember-500/50"></div>
            <span className="text-sm text-ivory-100/70">W trakcie</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-gray-500/30 border border-gray-500/50"></div>
            <span className="text-sm text-ivory-100/70">Zakończona</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 rounded bg-red-500/30 border border-red-500/50"></div>
            <span className="text-sm text-ivory-100/70">Anulowana</span>
          </div>
        </div>
      </div>

      {/* Modal for new appointment */}
      {selectedSlot && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-6">
          <div className="marble-card p-6 max-w-md w-full">
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-xl font-semibold text-ivory-100">Nowa wizyta</h3>
              <button
                onClick={() => setSelectedSlot(null)}
                className="p-1 rounded hover:bg-white/10 transition-colors"
              >
                <X className="h-5 w-5 text-ivory-100/70" />
              </button>
            </div>
            <p className="text-ivory-100/70 mb-4">
              {format(selectedSlot.date, "EEEE, d MMMM yyyy", { locale: pl })}, {selectedSlot.time}
            </p>
            <button
              onClick={() => {
                if (currentUserId) {
                  window.location.href = `/${currentUserId}/appointments/new?dentist=${dentistId}&date=${selectedSlot.date.toISOString()}&time=${selectedSlot.time}`;
                } else {
                  window.location.href = `/admin/appointments/new?dentist=${dentistId}&date=${selectedSlot.date.toISOString()}&time=${selectedSlot.time}`;
                }
              }}
              className="btn-primary w-full"
            >
              Utwórz wizytę
            </button>
          </div>
        </div>
      )}
    </div>
  );
}













