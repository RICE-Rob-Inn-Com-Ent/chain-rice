"use client";

import { useMemo, useState, useEffect, useRef } from "react";
import { useRouter } from "next/navigation";
import { useLocation } from "@/app/contexts/LocationContext";
import Icon from "@/app/components/Icon";

type AppointmentCard = {
  id: string;
  appointmentNumber: string;
  date: string;
  startTime: string;
  durationMinutes: number;
  status: string;
  treatmentType: string | null;
  patientName: string;
  patientId: string;
  patientNumber?: string | null;
  patientUsername?: string | null;
  dentistName: string;
  dentistId: string;
  location_id?: string | null;
};

type PatientOption = {
  id: string;
  display_name: string;
  patient_number: string | null;
  email?: string | null;
  phone?: string | null;
};

type StaffOption = {
  id: string;
  name: string;
};

type ScheduleRow = {
  id: string;
  staff_type: "dentist" | "admin";
  staff_id: string;
  staff_name: string;
  day_of_week: number;
  start_time: string;
  end_time: string;
  location: string | null;
  notes: string | null;
};

type WeekMeta = {
  startISO: string;
  endISO: string;
  days: { date: string; label: string; shortLabel: string; dayIndex: number }[];
};

type WeeklyCalendarBoardProps = {
  week: WeekMeta;
  appointments: AppointmentCard[];
  patients: PatientOption[];
  doctors: StaffOption[];
  doctorSchedules: ScheduleRow[];
  todayISO: string;
  workingHoursStart?: string; // Format: "HH:MM" lub null dla całej doby
  workingHoursEnd?: string; // Format: "HH:MM" lub null dla całej doby
};

type SelectionRange = {
  dentistId: string;
  day: string;
  startSlot: string;
  endSlot: string;
};

const SLOT_INTERVAL = 15;
const DEFAULT_START_MINUTES = 0; // 00:00 - cała doba
const DEFAULT_END_MINUTES = 24 * 60 - 1; // 23:59 - ostatnia minuta doby (nie 24:00!)
const TIME_COLUMN_WIDTH = 80; // Węższa kolumna godzinowa
const SLOT_HEIGHT_PX = 60; // Wysokość każdego 15-minutowego slotu w pikselach
const AUTO_SCROLL_COOLDOWN_MS = 60_000; // Minimalny odstęp między auto-scrollami
const CURRENT_TIME_OFFSET_SLOTS = 1; // Ile slotów powyżej bieżącej godziny utrzymywać

// Color scheme for appointments
const appointmentColors = [
  "bg-amber-400/80",
  "bg-teal-400/80",
  "bg-purple-400/80",
  "bg-blue-400/80",
  "bg-orange-400/80",
];

const statusIcons: Record<string, { iconName: string; color: string }> = {
  favorite: { iconName: "favorite", color: "text-red-500" },
  confirmed: { iconName: "check_circle", color: "text-green-500" },
  message: { iconName: "chat_bubble", color: "text-blue-500" },
  sent: { iconName: "send", color: "text-purple-500" },
  settings: { iconName: "settings", color: "text-gray-500" },
};

function minutesToLabel(totalMinutes: number): string {
  const hours = Math.floor(totalMinutes / 60)
    .toString()
    .padStart(2, "0");
  const minutes = (totalMinutes % 60).toString().padStart(2, "0");
  return `${hours}:${minutes}`;
}

function labelToMinutes(label: string): number {
  const [h, m] = label.split(":").map(Number);
  return h * 60 + m;
}

// Generate all time slots (every 15 minutes) - will be generated dynamically based on working hours
// Maximum is 23:45 (last 15-minute slot of the day, 24:00 doesn't exist)
function generateTimeSlots(startMinutes: number, endMinutes: number): string[] {
  const slots: string[] = [];
  const maxSlotMinutes = 23 * 60 + 45; // 23:45 - ostatni slot doby (1425 minut)
  const safeEndMinutes = Math.min(endMinutes, maxSlotMinutes);

  // Generate slots up to but not including 24:00
  for (let minutes = startMinutes; minutes <= safeEndMinutes; minutes += SLOT_INTERVAL) {
    // Don't generate slot at 24:00 or later
    if (minutes >= 24 * 60) break;
    slots.push(minutesToLabel(minutes));
  }
  return slots;
}

// Generate hour markers for display
// Maximum is 23:00 (last hour marker, 24:00 doesn't exist)
function generateHourMarkers(startMinutes: number, endMinutes: number): number[] {
  const maxMinutes = 24 * 60 - 1; // 23:59 - ostatnia minuta doby
  const safeEndMinutes = Math.min(endMinutes, maxMinutes);
  const startHour = Math.floor(startMinutes / 60);
  const endHour = Math.min(Math.floor(safeEndMinutes / 60), 23); // Max hour is 23
  return Array.from({ length: endHour - startHour + 1 }, (_, i) => {
    const hour = startHour + i;
    if (hour >= 24) return null; // Don't include hour 24
    return hour;
  }).filter((h): h is number => h !== null);
}

// Day abbreviations in Polish
const dayAbbreviations: Record<number, string> = {
  0: "PON",
  1: "WT",
  2: "ŚR",
  3: "CZW",
  4: "PT",
  5: "SOB",
  6: "NIEDZ",
};

// Map day index (0=Monday) to day key in opening_hours
const dayIndexToKey: Record<number, string> = {
  0: "monday",
  1: "tuesday",
  2: "wednesday",
  3: "thursday",
  4: "friday",
  5: "saturday",
  6: "sunday",
};

export default function WeeklyCalendarBoard({
  week,
  appointments: initialAppointments,
  patients,
  doctors,
  doctorSchedules,
  todayISO,
  workingHoursStart,
  workingHoursEnd,
}: WeeklyCalendarBoardProps) {
  const { selectedLocation, selectedLocationId, setSelectedLocationId, locations } = useLocation();
  const MAX_END_MINUTES = 24 * 60 - 1; // 23:59 - ostatnia minuta doby
  
  // Use state for appointments so we can refresh them after creating new ones
  // Initialize with empty array - appointments will be fetched from API
  const [appointments, setAppointments] = useState<AppointmentCard[]>([]);
  

  // Fetch appointments from API on mount and when selected day/location changes
  useEffect(() => {
    const fetchAppointments = async () => {
      try {
        const url = `/api/appointments?date_from=${week.startISO}&date_to=${week.endISO}${selectedLocationId ? `&location_id=${selectedLocationId}` : ''}`;
        const res = await fetch(url);
        if (res.ok) {
          const data = await res.json();
          if (data.appointments) {
            const updatedAppointments = data.appointments.map((apt: any) => {
              // Normalize date to YYYY-MM-DD format
              const appointmentDate = apt.appointment_date || apt.date;
              const normalizedDate = appointmentDate ? appointmentDate.split('T')[0] : '';
              
              return {
                id: apt.id,
                appointmentNumber: apt.appointment_number,
                date: normalizedDate,
                startTime: apt.appointment_time || apt.startTime,
                durationMinutes: apt.duration_minutes || apt.durationMinutes,
                status: apt.status,
                treatmentType: apt.treatment_type_name || apt.treatment_type || apt.treatmentType,
                patientName: apt.patient_name || (apt.patient_first_name && apt.patient_last_name 
                  ? `${apt.patient_first_name} ${apt.patient_last_name}` 
                  : apt.patientName || "Nieznany pacjent"),
                patientId: apt.patient_id || apt.patientId,
                patientNumber: apt.patient_number || null,
                patientUsername: apt.patient_username || null,
                dentistName: apt.dentist_name || (apt.dentist_first_name && apt.dentist_last_name
                  ? `${apt.dentist_first_name} ${apt.dentist_last_name}`
                  : apt.dentistName || "Nieznany dentysta"),
                dentistId: String(apt.dentist_id || apt.dentistId || "").trim(),
                location_id: apt.location_id || null,
              };
            });
            setAppointments(updatedAppointments);
          } else {
            setAppointments([]);
          }
        } else {
          console.error('Failed to fetch appointments:', res.status, res.statusText);
          const errorText = await res.text();
          console.error('Error response:', errorText);
        }
      } catch (error) {
        console.error('Error fetching appointments:', error);
      }
    };
    fetchAppointments();
  }, [week.startISO, week.endISO, selectedLocationId]);

  // Get opening hours for each day from selected location
  const getDayOpeningHours = useMemo(() => {
    return (dayIndex: number) => {
      if (!selectedLocation?.opening_hours) {
        // Fallback to global working hours or full day
        return {
          startMinutes: workingHoursStart ? labelToMinutes(workingHoursStart) : DEFAULT_START_MINUTES,
          endMinutes: workingHoursEnd ? labelToMinutes(workingHoursEnd) : DEFAULT_END_MINUTES,
          closed: false,
        };
      }

      const dayKey = dayIndexToKey[dayIndex];
      const dayHours = selectedLocation.opening_hours[dayKey];

      if (!dayHours || dayHours.closed) {
        // Day is closed - return empty range
        return {
          startMinutes: 0,
          endMinutes: 0,
          closed: true,
        };
      }

      return {
        startMinutes: labelToMinutes(dayHours.open),
        endMinutes: labelToMinutes(dayHours.close),
        closed: false,
      };
    };
  }, [selectedLocation, workingHoursStart, workingHoursEnd]);

  // Helper function to check if a slot is within opening hours for a specific day
  const isSlotInOpeningHours = (slot: string, dayIndex: number): boolean => {
    const dayHours = getDayOpeningHours(dayIndex);
    if (dayHours.closed) return false;
    const slotMinutes = labelToMinutes(slot);
    return slotMinutes >= dayHours.startMinutes && slotMinutes < dayHours.endMinutes;
  };

  // Get overall min/max for all days to determine calendar range
  const overallRange = useMemo(() => {
    let minStart = DEFAULT_END_MINUTES;
    let maxEnd = DEFAULT_START_MINUTES;
    let hasOpenDays = false;

    week.days.forEach((day) => {
      const hours = getDayOpeningHours(day.dayIndex);
      if (!hours.closed) {
        hasOpenDays = true;
        minStart = Math.min(minStart, hours.startMinutes);
        maxEnd = Math.max(maxEnd, hours.endMinutes);
      }
    });

    // If no open days, use default range
    if (!hasOpenDays) {
      return {
        startMinutes: workingHoursStart ? labelToMinutes(workingHoursStart) : DEFAULT_START_MINUTES,
        endMinutes: workingHoursEnd ? labelToMinutes(workingHoursEnd) : DEFAULT_END_MINUTES,
      };
    }

    return {
      startMinutes: minStart,
      endMinutes: maxEnd,
    };
  }, [week.days, getDayOpeningHours, workingHoursStart, workingHoursEnd]);

  // Generate time slots and hour markers based on overall range
  const allTimeSlots = useMemo(
    () => generateTimeSlots(overallRange.startMinutes, overallRange.endMinutes),
    [overallRange.startMinutes, overallRange.endMinutes]
  );
  const hourMarkers = useMemo(
    () => generateHourMarkers(overallRange.startMinutes, overallRange.endMinutes),
    [overallRange.startMinutes, overallRange.endMinutes]
  );
  const router = useRouter();
  const touchStartY = useRef<number | null>(null);
  const touchEndY = useRef<number | null>(null);
  const [currentTime, setCurrentTime] = useState<string>("");
  const [pendingSelection, setPendingSelection] = useState<SelectionRange | null>(null);
  const [activeRange, setActiveRange] = useState<SelectionRange | null>(null);
  const [isMobile, setIsMobile] = useState<boolean>(false);
  const [scrollPosition, setScrollPosition] = useState<number>(0); // Pozycja scroll w pikselach
  const [visibleHeight, setVisibleHeight] = useState<number>(600); // Default height for SSR
  const timeScrollRef = useRef<HTMLDivElement>(null);
  const daysScrollRef = useRef<HTMLDivElement>(null);
  const headerScrollRef = useRef<HTMLDivElement>(null);
  const contentScrollRef = useRef<HTMLDivElement>(null);
  const lastManualScrollRef = useRef<number>(0);
  const isAutoScrollingRef = useRef<boolean>(false);

  // Track window size
  useEffect(() => {
    const checkMobile = () => {
      setIsMobile(window.innerWidth < 1024);
      setVisibleHeight(window.innerHeight * 0.7);
    };
    checkMobile();
    window.addEventListener("resize", checkMobile);
    return () => window.removeEventListener("resize", checkMobile);
  }, []);

  // Initialize scroll to current time
  useEffect(() => {
    const now = new Date();
    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    if (currentMinutes >= overallRange.startMinutes && currentMinutes <= overallRange.endMinutes) {
      const currentSlot = (currentMinutes - overallRange.startMinutes) / SLOT_INTERVAL;
      const scrollPos = currentSlot * SLOT_HEIGHT_PX;
      setScrollPosition(scrollPos);

      // Scroll to current time on mount
      if (timeScrollRef.current) {
        timeScrollRef.current.scrollTop = scrollPos;
      }
      if (daysScrollRef.current) {
        daysScrollRef.current.scrollTop = scrollPos;
      }
    }
  }, [overallRange.startMinutes, overallRange.endMinutes]);
  const [modalContext, setModalContext] = useState<{
    dentistId: string;
    day: string;
    start: string;
    end: string;
  } | null>(null);
  const [modalSearch, setModalSearch] = useState("");
  const [modalStart, setModalStart] = useState("");
  const [modalEnd, setModalEnd] = useState("");
  const [modalSelection, setModalSelection] = useState("");
  const [actionError, setActionError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showAddDoctorModal, setShowAddDoctorModal] = useState<{ day: string } | null>(null);
  const [selectedDoctorForModal, setSelectedDoctorForModal] = useState<StaffOption | null>(null);
  const [doctorStartTime, setDoctorStartTime] = useState<string>("08:00");
  const [doctorEndTime, setDoctorEndTime] = useState<string>("17:00");
  const [isSavingDoctor, setIsSavingDoctor] = useState(false);
  const [saveDoctorError, setSaveDoctorError] = useState<string | null>(null);
  const [showPatientRegistrationModal, setShowPatientRegistrationModal] = useState<{
    dentistId: string;
    dentistName: string;
    day: string;
    startTime: string;
    endTime: string;
  } | null>(null);
  const [selectedPatientId, setSelectedPatientId] = useState<string | null>(null);
  const [patientSearchQuery, setPatientSearchQuery] = useState("");
  const [appointmentStartTime, setAppointmentStartTime] = useState("");
  const [appointmentEndTime, setAppointmentEndTime] = useState("");
  const [selectedTreatmentType, setSelectedTreatmentType] = useState<string | null>(null);
  const [treatmentTypes, setTreatmentTypes] = useState<Array<{ id: string; name: string; default_duration_minutes: number }>>([]);
  const [patientError, setPatientError] = useState("");
  const [isSubmittingPatient, setIsSubmittingPatient] = useState(false);
  const [isLoadingTreatmentTypes, setIsLoadingTreatmentTypes] = useState(false);
  const [editingAppointmentId, setEditingAppointmentId] = useState<string | null>(null);
  const [dayDoctors, setDayDoctors] = useState<Map<string, string[]>>(new Map()); // Map<date, dentistIds[]>
  const [dayDoctorSchedules, setDayDoctorSchedules] = useState<Map<string, Map<string, { start_time: string | null; end_time: string | null }>>>(new Map()); // Map<date, Map<dentistId, {start_time, end_time}>>
  const [selectedDay, setSelectedDay] = useState<string>(todayISO);
  const [showFilterModal, setShowFilterModal] = useState(false);
  const [dateRangeStart, setDateRangeStart] = useState<string>(week.startISO);
  const [dateRangeEnd, setDateRangeEnd] = useState<string>(week.endISO);

  const inputClass =
    "w-full rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-sm text-ivory-100 placeholder:text-ivory-100/40 focus:border-ember-400 focus:outline-none focus:ring-2 focus:ring-ember-400/20";


  // Update current time every minute
  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setCurrentTime(minutesToLabel(now.getHours() * 60 + now.getMinutes()));
    };
    updateTime();
    const interval = setInterval(updateTime, 60000);
    return () => clearInterval(interval);
  }, []);

  // Auto-hide past hours by following current time and sliding slots under sticky header
  useEffect(() => {
    if (!currentTime || typeof window === "undefined") return;
    if (!contentScrollRef.current) return;

    const currentMinutes = labelToMinutes(currentTime);
    if (currentMinutes < overallRange.startMinutes || currentMinutes > overallRange.endMinutes) return;

    const now = Date.now();
    if (now - lastManualScrollRef.current < AUTO_SCROLL_COOLDOWN_MS) return;

    const currentSlotIndex = (currentMinutes - overallRange.startMinutes) / SLOT_INTERVAL;
    const targetSlotIndex = Math.max(currentSlotIndex - CURRENT_TIME_OFFSET_SLOTS, 0);
    const targetScrollTop = targetSlotIndex * SLOT_HEIGHT_PX;
    const currentScrollTop = contentScrollRef.current.scrollTop;

    if (Math.abs(currentScrollTop - targetScrollTop) < SLOT_HEIGHT_PX / 2) {
      return;
    }

    isAutoScrollingRef.current = true;
    contentScrollRef.current.scrollTo({ top: targetScrollTop, behavior: "smooth" });

    if (timeScrollRef.current) {
      timeScrollRef.current.scrollTop = targetScrollTop;
    }
    if (daysScrollRef.current) {
      daysScrollRef.current.scrollTop = targetScrollTop;
    }

    const timeoutId = window.setTimeout(() => {
      isAutoScrollingRef.current = false;
    }, 500);

    return () => window.clearTimeout(timeoutId);
  }, [currentTime, overallRange.startMinutes, overallRange.endMinutes]);

  // Fetch doctors for selected day
  const fetchDayDoctors = async (date: string, retries = 3) => {
    for (let attempt = 0; attempt < retries; attempt++) {
      try {
        const locationParam = selectedLocationId ? `&location_id=${selectedLocationId}` : '';
        const res = await fetch(`/api/day-doctors?date=${date}${locationParam}`, {
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
          },
          cache: 'no-store',
        });
        
        if (res.ok) {
          const data = await res.json();
          setDayDoctors((prev) => {
            const newMap = new Map(prev);
            newMap.set(date, data.dentistIds || []);
            return newMap;
          });
          // Store schedules for each dentist
          if (data.schedules) {
            setDayDoctorSchedules((prev) => {
              const newMap = new Map(prev);
              const schedulesMap = new Map<string, { start_time: string | null; end_time: string | null }>();
              data.schedules.forEach((sched: { dentist_id: string; start_time: string | null; end_time: string | null }) => {
                schedulesMap.set(sched.dentist_id, { start_time: sched.start_time, end_time: sched.end_time });
              });
              newMap.set(date, schedulesMap);
              return newMap;
            });
          }
          return; // Success, exit retry loop
        } else {
          // If not ok and not last attempt, wait before retry
          if (attempt < retries - 1) {
            await new Promise(resolve => setTimeout(resolve, 1000 * (attempt + 1)));
            continue;
          }
          // Last attempt failed, set empty
          setDayDoctors((prev) => {
            const newMap = new Map(prev);
            newMap.set(date, []);
            return newMap;
          });
          setDayDoctorSchedules((prev) => {
            const newMap = new Map(prev);
            newMap.set(date, new Map());
            return newMap;
          });
        }
      } catch (error) {
        console.error(`Error fetching day doctors (attempt ${attempt + 1}/${retries}):`, error);
        // If not last attempt, wait before retry
        if (attempt < retries - 1) {
          await new Promise(resolve => setTimeout(resolve, 1000 * (attempt + 1)));
          continue;
        }
        // Last attempt failed, set empty
        setDayDoctors((prev) => {
          const newMap = new Map(prev);
          newMap.set(date, []);
          return newMap;
        });
        setDayDoctorSchedules((prev) => {
          const newMap = new Map(prev);
          newMap.set(date, new Map());
          return newMap;
        });
      }
    }
  };

  // Load doctors for selected day
  useEffect(() => {
    fetchDayDoctors(selectedDay);
  }, [selectedDay]);

  // Load treatment types
  useEffect(() => {
    const loadTreatmentTypes = async (retries = 3) => {
      setIsLoadingTreatmentTypes(true);
      for (let attempt = 0; attempt < retries; attempt++) {
        try {
          const res = await fetch("/api/treatment-types", {
            method: 'GET',
            headers: {
              'Content-Type': 'application/json',
            },
            cache: 'no-store',
          });
          
          if (res.ok) {
            const data = await res.json();
            setTreatmentTypes(data.treatment_types || []);
            setIsLoadingTreatmentTypes(false);
            return; // Success, exit retry loop
          } else {
            // If not ok and not last attempt, wait before retry
            if (attempt < retries - 1) {
              await new Promise(resolve => setTimeout(resolve, 1000 * (attempt + 1)));
              continue;
            }
            // Last attempt failed, set empty
            setTreatmentTypes([]);
          }
        } catch (error) {
          console.error(`Error loading treatment types (attempt ${attempt + 1}/${retries}):`, error);
          // If not last attempt, wait before retry
          if (attempt < retries - 1) {
            await new Promise(resolve => setTimeout(resolve, 1000 * (attempt + 1)));
            continue;
          }
          // Last attempt failed, set empty
          setTreatmentTypes([]);
        } finally {
          if (attempt === retries - 1) {
            setIsLoadingTreatmentTypes(false);
          }
        }
      }
    };
    loadTreatmentTypes();
  }, []);

  // Get doctors for selected day
  const getDoctorsForDay = (date: string): StaffOption[] => {
    const dentistIds = dayDoctors.get(date) || [];
    // Normalize IDs to strings for comparison
    const normalizedDentistIds = dentistIds.map(id => String(id).trim());
    return doctors.filter((doc) => {
      const docId = String(doc.id).trim();
      return normalizedDentistIds.includes(docId);
    });
  };


  // Swipe handlers for vertical scrolling (mobile only)
  const handleTouchStart = (e: React.TouchEvent) => {
    if (!isMobile) return;
    touchStartY.current = e.touches[0].clientY;
  };

  const handleTouchMove = (e: React.TouchEvent) => {
    if (!isMobile) return;
    touchEndY.current = e.touches[0].clientY;
  };

  const handleTouchEnd = () => {
    if (!isMobile || !touchStartY.current || !touchEndY.current) return;

    const diff = touchStartY.current - touchEndY.current;
    const minSwipeDistance = 50;
    const scrollStep = 200; // Pikseli na swipe

    if (Math.abs(diff) > minSwipeDistance) {
      if (diff > 0) {
        // Swipe up - scroll down
        setScrollPosition((prev) => Math.min(prev + scrollStep, totalHeight - window.innerHeight * 0.7));
      } else {
        // Swipe down - scroll up
        setScrollPosition((prev) => Math.max(prev - scrollStep, 0));
      }
    }

    touchStartY.current = null;
    touchEndY.current = null;
  };

  // Handle mouse wheel scroll (mobile only)
  const handleWheel = (e: React.WheelEvent) => {
    if (!isMobile) return;

    e.preventDefault();
    const scrollStep = 200;

    if (e.deltaY > 0) {
      // Scroll down
      setScrollPosition((prev) => Math.min(prev + scrollStep, totalHeight - window.innerHeight * 0.7));
    } else {
      // Scroll up
      setScrollPosition((prev) => Math.max(prev - scrollStep, 0));
    }
  };

  // Scroll to today
  const scrollToToday = () => {
    const now = new Date();
    const currentMinutes = now.getHours() * 60 + now.getMinutes();
    if (currentMinutes >= overallRange.startMinutes && currentMinutes <= overallRange.endMinutes) {
      const currentSlot = (currentMinutes - overallRange.startMinutes) / SLOT_INTERVAL;
      const scrollPos = currentSlot * SLOT_HEIGHT_PX;
      setScrollPosition(scrollPos);

      if (timeScrollRef.current) {
        timeScrollRef.current.scrollTop = scrollPos;
      }
      if (daysScrollRef.current) {
        daysScrollRef.current.scrollTop = scrollPos;
      }
    }
  };

  // Handle scroll sync - synchronize time column with days columns
  const handleTimeScroll = (e: React.UIEvent<HTMLDivElement>) => {
    const scrollTop = e.currentTarget.scrollTop;
    setScrollPosition(scrollTop);
    // Sync all day columns with time column
    if (daysScrollRef.current) {
      daysScrollRef.current.scrollTop = scrollTop;
    }
  };

  const handleDaysScroll = (e: React.UIEvent<HTMLDivElement>) => {
    const scrollTop = e.currentTarget.scrollTop;
    setScrollPosition(scrollTop);
    // Sync time column with day columns
    if (timeScrollRef.current) {
      timeScrollRef.current.scrollTop = scrollTop;
    }
  };


  // Calculate total height of calendar based on actual number of slots (not endMinutes)
  // This ensures we don't exceed 24 hours
  const totalHeight = allTimeSlots.length * SLOT_HEIGHT_PX;

  // Get schedule for dentist on specific day
  const getDentistSchedule = (dentistId: string, date: string) => {
    // First check if there's a specific schedule for this day
    const daySchedule = dayDoctorSchedules.get(date)?.get(dentistId);
    if (daySchedule && (daySchedule.start_time || daySchedule.end_time)) {
      return {
        start_time: daySchedule.start_time || "00:00",
        end_time: daySchedule.end_time || "23:59",
      };
    }
    // Fallback to weekly schedule
    const dateObj = new Date(date);
    const dayOfWeek = (dateObj.getUTCDay() + 6) % 7; // Convert to Monday=0 format
    return doctorSchedules.find(
      (s) => {
        // Match by staff_id (can be dentist UUID or user_id), dentist_id, or dentist_user_id
        return s.day_of_week === dayOfWeek && (
          s.staff_id === dentistId ||
          (s as any).dentist_id === dentistId ||
          (s as any).dentist_user_id === dentistId
        );
      }
    );
  };

  // Get appointments for specific dentist and day, filtered by location
  const getAppointmentsForDayAndDentist = (date: string, dentistId: string) => {
    // Normalize date to YYYY-MM-DD format (remove time if present)
    const normalizedDate = date.split('T')[0];
    
    const filtered = appointments.filter((apt) => {
      // Normalize both dates to YYYY-MM-DD format
      const aptDate = apt.date?.split('T')[0] || apt.date || '';
      const searchDate = normalizedDate;
      const matchesDate = aptDate === searchDate;
      
      // Compare dentist IDs - normalize both to strings for comparison
      const aptDentistId = String(apt.dentistId || '').trim();
      const searchDentistId = String(dentistId || '').trim();
      const matchesDentist = aptDentistId === searchDentistId;
      
      // Filtruj po lokalizacji jeśli wybrana
      const matchesLocation = !selectedLocationId || (apt as any).location_id === selectedLocationId || !(apt as any).location_id;
      
      return matchesDate && matchesDentist && matchesLocation;
    });
    
    return filtered;
  };

  const getCurrentTimePosition = (date: string) => {
    if (!currentTime) return null;
    const currentMinutes = labelToMinutes(currentTime);
    // Get opening hours for this specific day
    const dayMeta = week.days.find(d => d.date === date);
    if (!dayMeta) return null;
    const dayHours = getDayOpeningHours(dayMeta.dayIndex);
    if (dayHours.closed || currentMinutes < dayHours.startMinutes || currentMinutes > dayHours.endMinutes) return null;

    const slotIndex = (currentMinutes - overallRange.startMinutes) / SLOT_INTERVAL;
    const position = slotIndex * SLOT_HEIGHT_PX;

    // Check if this day is today
    const isToday = date === todayISO;

    return isToday ? { top: `${position}px` } : null;
  };

  const handleSlotClick = (dentistId: string, day: string, slot: string) => {
    setActionError("");

    if (!pendingSelection || pendingSelection.dentistId !== dentistId || pendingSelection.day !== day) {
      setPendingSelection({ dentistId, day, startSlot: slot, endSlot: slot });
      setActiveRange(null);
      return;
    }

    let startMinutes = labelToMinutes(pendingSelection.startSlot);
    let endMinutes = labelToMinutes(slot) + SLOT_INTERVAL;
    endMinutes = Math.min(endMinutes, endMinutes);

    if (endMinutes <= startMinutes) {
      startMinutes = labelToMinutes(slot);
      endMinutes = Math.min(startMinutes + SLOT_INTERVAL, endMinutes);
    }

    const normalizedStart = Math.min(startMinutes, endMinutes - SLOT_INTERVAL);
    const normalizedEnd = Math.max(normalizedStart + SLOT_INTERVAL, endMinutes);

    setActiveRange({
      dentistId,
      day,
      startSlot: minutesToLabel(normalizedStart),
      endSlot: minutesToLabel(normalizedEnd),
    });
    setPendingSelection(null);
  };

  const closeModal = () => {
    setModalContext(null);
    setModalSelection("");
    setModalSearch("");
    setModalStart("");
    setModalEnd("");
    setActionError("");
  };

  const closePatientModal = () => {
    setShowPatientRegistrationModal(null);
    setSelectedPatientId(null);
    setPatientSearchQuery("");
    setAppointmentStartTime("");
    setAppointmentEndTime("");
    setSelectedTreatmentType(null);
    setPatientError("");
    setEditingAppointmentId(null);
  };

  const openModal = (dentistId: string) => {
    if (!activeRange) return;
    setModalContext({
      dentistId,
      day: activeRange.day,
      start: activeRange.startSlot,
      end: activeRange.endSlot,
    });
    setModalStart(activeRange.startSlot);
    setModalEnd(activeRange.endSlot);
    setModalSearch("");
    setModalSelection("");
    setActionError("");
  };

  const renderAppointment = (appointment: AppointmentCard, index: number) => {
    const aptStartMinutes = labelToMinutes(appointment.startTime);
    const aptEndMinutes = aptStartMinutes + appointment.durationMinutes;
    const slotIndex = (aptStartMinutes - overallRange.startMinutes) / SLOT_INTERVAL;
    const durationSlots = appointment.durationMinutes / SLOT_INTERVAL;

    const top = slotIndex * SLOT_HEIGHT_PX;
    const height = durationSlots * SLOT_HEIGHT_PX;

    const colorIndex = index % appointmentColors.length;
    const color = appointmentColors[colorIndex];

    // Determine status icon
    let statusIcon = null;
    if (appointment.status === "confirmed") {
      statusIcon = statusIcons.confirmed;
    } else if (appointment.status === "favorite") {
      statusIcon = statusIcons.favorite;
    }

    return (
      <div
        key={appointment.id}
        className={`absolute left-1 right-1 rounded-lg ${color} text-white p-2 text-xs shadow-lg z-30 cursor-pointer hover:opacity-90 transition-opacity`}
        style={{
          top: `${top}px`,
          height: `${Math.max(height, 40)}px`,
          pointerEvents: 'auto',
        }}
        title={`${appointment.patientName} • ${appointment.treatmentType || "Wizyta"} • Kliknij aby edytować`}
        onClick={(e) => {
          e.stopPropagation();
          // Open edit modal for appointment
          const aptEndTime = minutesToLabel(aptEndMinutes);
          setEditingAppointmentId(appointment.id);
          setShowPatientRegistrationModal({
            dentistId: appointment.dentistId || "",
            dentistName: appointment.dentistName,
            day: appointment.date,
            startTime: appointment.startTime,
            endTime: aptEndTime,
          });
          setSelectedPatientId(appointment.patientId || null);
          setAppointmentStartTime(appointment.startTime);
          setAppointmentEndTime(aptEndTime);
          setSelectedTreatmentType(appointment.treatmentType || null);
          setPatientSearchQuery("");
          setPatientError("");
        }}
      >
        <div className="flex items-start justify-between h-full">
          <div className="flex-1 min-w-0">
            <div className="font-semibold truncate">{appointment.patientName}</div>
            {(appointment.patientNumber || appointment.patientUsername) && (
              <div className="text-[10px] opacity-80 truncate mt-0.5">
                {appointment.patientNumber || appointment.patientUsername}
              </div>
            )}
            <div className="text-xs opacity-90 truncate mt-0.5">
              {appointment.treatmentType || "Wizyta"}
            </div>
            <div className="text-[10px] opacity-75 mt-1 font-medium">
              {appointment.startTime} - {minutesToLabel(aptEndMinutes)}
            </div>
          </div>
          {statusIcon && (
            <span
              className={`material-symbols-outlined h-4 w-4 ${statusIcon.color} flex-shrink-0 ml-1`}
              style={{ fontVariationSettings: '"FILL" 1, "wght" 400, "GRAD" 0, "opsz" 20' }}
            >
              {statusIcon.iconName}
            </span>
          )}
        </div>
      </div>
    );
  };



  const renderActionPanel = () => {
    if (!activeRange) return null;

    const durationMinutes = labelToMinutes(activeRange.endSlot) - labelToMinutes(activeRange.startSlot);
    const dentist = doctors.find((d) => d.id === activeRange.dentistId);
    const dayMeta = week.days.find((d) => d.date === activeRange.day);
    const summary = `${dayMeta?.label || activeRange.day} • ${activeRange.startSlot} – ${activeRange.endSlot}`;

    return (
      <div className="marble-card space-y-4 p-6">
        <div className="flex items-center gap-3">
          <span
            className="material-symbols-outlined text-amber-300"
            style={{ fontVariationSettings: '"FILL" 1, "wght" 400, "GRAD" 0, "opsz" 24' }}
          >
            event
          </span>
          <div>
            <p className="text-sm uppercase tracking-widest text-ivory-100/40">Nowa wizyta</p>
            <h3 className="text-xl font-semibold text-ivory-100">{summary}</h3>
            {dentist && <p className="text-sm text-ivory-100/60">Lekarz: {dentist.name}</p>}
          </div>
        </div>
        <p className="text-sm text-ivory-100/70">Czas trwania: {durationMinutes} min</p>
        {actionError && <p className="text-sm text-red-400">{actionError}</p>}
        <div className="flex gap-2">
          <button
            type="button"
            className="flex-1 rounded-lg py-2 text-sm font-semibold text-white bg-amber-500 hover:bg-amber-400"
            onClick={() => openModal(activeRange.dentistId)}
          >
            <span className="inline-flex items-center justify-center gap-2">
              <span
                className="material-symbols-outlined"
                style={{ fontVariationSettings: '"FILL" 0, "wght" 400, "GRAD" 0, "opsz" 24' }}
              >
                add
              </span>
              Dodaj pacjenta
            </span>
          </button>
          <button
            type="button"
            className="flex-1 rounded-lg border border-white/10 py-2 text-sm text-ivory-100 transition hover:bg-white/5"
            onClick={() => setActiveRange(null)}
          >
            Anuluj
          </button>
        </div>
      </div>
    );
  };

  const renderModal = () => {
    if (!modalContext) return null;

    const dayMeta = week.days.find((d) => d.date === modalContext.day);
    const sortedPatientsList = [...patients].sort((a, b) =>
      a.display_name.localeCompare(b.display_name, "pl")
    );
    const filtered = sortedPatientsList.filter((item) =>
      item.display_name.toLowerCase().includes(modalSearch.trim().toLowerCase())
    );

    const handleSave = async () => {
      if (!modalSelection) {
        setActionError("Wybierz pacjenta z listy.");
        return;
      }
      const start = modalStart || modalContext.start;
      const end = modalEnd || modalContext.end;
      if (!start || !end) {
        setActionError("Uzupełnij godziny rozpoczęcia i zakończenia.");
        return;
      }
      const startMinutes = labelToMinutes(start);
      const endMinutes = labelToMinutes(end);
      if (endMinutes <= startMinutes) {
        setActionError("Godzina zakończenia musi być późniejsza niż rozpoczęcia.");
        return;
      }

      setIsSubmitting(true);
      setActionError("");

      try {
        const duration = endMinutes - startMinutes;
        const res = await fetch("/api/appointments", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            patient_id: modalSelection,
            dentist_id: modalContext.dentistId,
            appointment_date: modalContext.day,
            appointment_time: start,
            duration_minutes: duration,
            treatment_type: null,
            location_id: selectedLocationId,
          }),
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error || "Nie udało się zapisać wizyty.");

        closeModal();
        setActiveRange(null);
        // Refresh appointments by fetching them again
        try {
          const refreshRes = await fetch(`/api/appointments?date_from=${week.startISO}&date_to=${week.endISO}`);
          if (refreshRes.ok) {
            const refreshData = await refreshRes.json();
            if (refreshData.appointments) {
              const updatedAppointments = refreshData.appointments.map((apt: any) => ({
                id: apt.id,
                appointmentNumber: apt.appointment_number,
                date: apt.appointment_date || apt.date,
                startTime: apt.appointment_time || apt.startTime,
                durationMinutes: apt.duration_minutes || apt.durationMinutes,
                status: apt.status,
                treatmentType: apt.treatment_type_name || apt.treatment_type || apt.treatmentType,
                patientName: apt.patient_name || (apt.patient_first_name && apt.patient_last_name 
                  ? `${apt.patient_first_name} ${apt.patient_last_name}` 
                  : apt.patientName),
                patientId: apt.patient_id || apt.patientId,
                patientNumber: apt.patient_number || null,
                patientUsername: apt.patient_username || null,
                dentistName: apt.dentist_name || (apt.dentist_first_name && apt.dentist_last_name
                  ? `${apt.dentist_first_name} ${apt.dentist_last_name}`
                  : apt.dentistName),
                dentistId: String(apt.dentist_id || apt.dentistId).trim(),
              }));
              setAppointments(updatedAppointments);
            }
          }
        } catch (error) {
          console.error("Error refreshing appointments:", error);
          // Fallback to page reload if fetch fails
          router.refresh();
        }
      } catch (error: any) {
        setActionError(error.message || "Wystąpił błąd.");
      } finally {
        setIsSubmitting(false);
      }
    };

    return (
      <div className="fixed inset-0 z-40 flex items-start justify-center bg-slate-900/70 p-4">
        <div className="w-full max-w-3xl rounded-3xl border border-white/10 bg-obsidian-900 p-6 shadow-2xl">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.3em] text-ivory-100/40">Nowa wizyta</p>
              <h3 className="text-2xl font-semibold text-ivory-100">{dayMeta?.label}</h3>
            </div>
            <button
              onClick={closeModal}
              className="rounded-full border border-white/15 px-3 py-1 text-sm text-ivory-100/70 hover:bg-white/10 flex items-center gap-2"
            >
              <span
                className="material-symbols-outlined"
                style={{ fontVariationSettings: '"FILL" 0, "wght" 300, "GRAD" 0, "opsz" 24' }}
              >
                close
              </span>
              Zamknij
            </button>
          </div>

          <div className="mt-4 grid gap-4 md:grid-cols-3">
            <label className="text-sm text-ivory-100/70">
              Start
              <input
                type="time"
                className={inputClass}
                value={modalStart}
                onChange={(e) => setModalStart(e.target.value)}
              />
            </label>
            <label className="text-sm text-ivory-100/70">
              Koniec
              <input
                type="time"
                className={inputClass}
                value={modalEnd}
                onChange={(e) => setModalEnd(e.target.value)}
              />
            </label>
            <label className="text-sm text-ivory-100/70">
              Szukaj
              <input
                type="text"
                className={inputClass}
                placeholder="Wpisz nazwisko"
                value={modalSearch}
                onChange={(e) => setModalSearch(e.target.value)}
              />
            </label>
          </div>

          <div className="mt-4 max-h-72 space-y-2 overflow-y-auto pr-2">
            {filtered.length === 0 ? (
              <p className="text-sm text-ivory-100/60">Brak wyników.</p>
            ) : (
              filtered.map((item) => (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => setModalSelection(item.id)}
                  className={`flex w-full items-center justify-between rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-left text-sm text-ivory-100 ${
                    modalSelection === item.id ? "ring-2 ring-ember-400" : ""
                  }`}
                >
                  <div>
                    <p className="font-semibold">{item.display_name}</p>
                    {item.patient_number && (
                      <p className="text-xs text-ivory-100/60">Nr pacjenta: {item.patient_number}</p>
                    )}
                  </div>
                  <span className="text-xs text-ivory-100/50">
                    {modalSelection === item.id ? "Wybrane" : "Wybierz"}
                  </span>
                </button>
              ))
            )}
          </div>

          {actionError && <p className="mt-3 text-sm text-red-400">{actionError}</p>}
          <div className="mt-4 flex gap-2">
            <button
              type="button"
              className="flex-1 rounded-lg py-2 text-sm font-semibold text-white bg-amber-500 hover:bg-amber-400 disabled:opacity-50"
              disabled={!modalSelection || isSubmitting}
              onClick={handleSave}
            >
              {isSubmitting ? (
                <>
                  <span
                    className="material-symbols-outlined animate-spin"
                    style={{ fontVariationSettings: '"FILL" 0, "wght" 400, "GRAD" 0, "opsz" 24' }}
                  >
                    progress_activity
                  </span>
                  Zapisywanie...
                </>
              ) : (
                "Zapisz"
              )}
            </button>
            <button
              type="button"
              className="flex-1 rounded-lg border border-white/10 py-2 text-sm text-ivory-100 transition hover:bg-white/5"
              onClick={closeModal}
            >
              Anuluj
            </button>
          </div>
        </div>
      </div>
    );
  };

  // Filter patients based on search query
  const filteredPatients = useMemo(() => {
    if (!patientSearchQuery.trim()) return patients;
    const query = patientSearchQuery.trim().toLowerCase();
    return patients.filter((patient) => {
      const displayName = patient.display_name?.toLowerCase() || "";
      const patientNumber = patient.patient_number?.toLowerCase() || "";
      const email = patient.email?.toLowerCase() || "";
      const phone = patient.phone?.toLowerCase() || "";
      return (
        displayName.includes(query) ||
        patientNumber.includes(query) ||
        email.includes(query) ||
        phone.includes(query)
      );
    });
  }, [patients, patientSearchQuery]);

  const renderPatientRegistrationModal = () => {
    if (!showPatientRegistrationModal) return null;

    const dayMeta = week.days.find((d) => d.date === showPatientRegistrationModal.day);

    const handleSave = async () => {
      if (!selectedPatientId) {
        setPatientError("Wybierz pacjenta z listy.");
        return;
      }

      const start = appointmentStartTime || showPatientRegistrationModal.startTime;
      const end = appointmentEndTime || showPatientRegistrationModal.endTime;

      if (!start || !end) {
        setPatientError("Uzupełnij godziny rozpoczęcia i zakończenia.");
        return;
      }

      const startMinutes = labelToMinutes(start);
      const endMinutes = labelToMinutes(end);

      if (endMinutes <= startMinutes) {
        setPatientError("Godzina zakończenia musi być późniejsza niż rozpoczęcia.");
        return;
      }

      setIsSubmittingPatient(true);
      setPatientError("");

      try {
        const duration = endMinutes - startMinutes;

        // Validate dentist_id before sending
        if (!showPatientRegistrationModal.dentistId) {
          throw new Error("Brak ID dentysty. Odśwież stronę i spróbuj ponownie.");
        }

        const appointmentData = {
          patient_id: selectedPatientId,
          dentist_id: showPatientRegistrationModal.dentistId,
          appointment_date: showPatientRegistrationModal.day,
          appointment_time: start,
          duration_minutes: duration,
          treatment_type: selectedTreatmentType || null,
          location_id: selectedLocationId,
        };

        const isEditMode = Boolean(editingAppointmentId);
        const endpoint = isEditMode ? `/api/appointments/${editingAppointmentId}` : "/api/appointments";
        const method = isEditMode ? "PUT" : "POST";

        const res = await fetch(endpoint, {
          method,
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(appointmentData),
        });

        const data = await res.json();
        if (!res.ok) {
          // Better error message for foreign key constraint
          const errorMessage = data.error || "Nie udało się zapisać wizyty.";
          if (errorMessage.includes("foreign key constraint")) {
            if (errorMessage.includes("appointments_patient_id_fkey")) {
              throw new Error("Wybrany pacjent nie istnieje w bazie danych. Odśwież stronę i wybierz pacjenta ponownie.");
            }
            if (errorMessage.includes("appointments_dentist_id_fkey") || errorMessage.includes("dentysta")) {
              throw new Error("Wybrany dentysta nie istnieje w bazie danych. Odśwież stronę i spróbuj ponownie.");
            }
          }
          throw new Error(errorMessage);
        }

        closePatientModal();
        // Refresh appointments by fetching them again
        try {
          const refreshRes = await fetch(`/api/appointments?date_from=${week.startISO}&date_to=${week.endISO}`);
          if (refreshRes.ok) {
            const refreshData = await refreshRes.json();
            if (refreshData.appointments) {
              const updatedAppointments = refreshData.appointments.map((apt: any) => ({
                id: apt.id,
                appointmentNumber: apt.appointment_number,
                date: apt.appointment_date || apt.date,
                startTime: apt.appointment_time || apt.startTime,
                durationMinutes: apt.duration_minutes || apt.durationMinutes,
                status: apt.status,
                treatmentType: apt.treatment_type_name || apt.treatment_type || apt.treatmentType,
                patientName: apt.patient_name || (apt.patient_first_name && apt.patient_last_name 
                  ? `${apt.patient_first_name} ${apt.patient_last_name}` 
                  : apt.patientName),
                patientId: apt.patient_id || apt.patientId,
                patientNumber: apt.patient_number || null,
                patientUsername: apt.patient_username || null,
                dentistName: apt.dentist_name || (apt.dentist_first_name && apt.dentist_last_name
                  ? `${apt.dentist_first_name} ${apt.dentist_last_name}`
                  : apt.dentistName),
                dentistId: String(apt.dentist_id || apt.dentistId).trim(),
              }));
              setAppointments(updatedAppointments);
            }
          }
        } catch (error) {
          console.error("Error refreshing appointments:", error);
          // Fallback to page reload if fetch fails
          router.refresh();
        }
      } catch (error: any) {
        setPatientError(error.message || "Wystąpił błąd.");
      } finally {
        setIsSubmittingPatient(false);
      }
    };

    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/70 p-4">
        <div className="w-full max-w-2xl rounded-3xl border border-white/10 bg-obsidian-900 p-6 shadow-2xl">
          <div className="flex items-center justify-between mb-6">
            <div>
              <p className="text-xs uppercase tracking-[0.3em] text-ivory-100/40">
                {editingAppointmentId ? "Edytuj wizytę" : "Nowa wizyta"}
              </p>
              <h3 className="text-2xl font-semibold text-ivory-100">{dayMeta?.label}</h3>
              <p className="text-sm text-ivory-100/60 mt-1">Lekarz: {showPatientRegistrationModal.dentistName}</p>
            </div>
            <button
              onClick={closePatientModal}
              className="rounded-full border border-white/15 px-3 py-1 text-sm text-ivory-100/70 hover:bg-white/10 flex items-center gap-2"
            >
              <span
                className="material-symbols-outlined"
                style={{ fontVariationSettings: '"FILL" 0, "wght" 300, "GRAD" 0, "opsz" 24' }}
              >
                close
              </span>
              Zamknij
            </button>
          </div>

          {patientError && (
            <div className="mb-4 rounded-lg bg-red-500/20 border border-red-500/50 p-3 text-red-400 text-sm">
              {patientError}
            </div>
          )}

          {/* Patient Search */}
          <div className="mb-4">
            <label className="block text-sm font-medium text-ivory-100/80 mb-2">
              Wyszukaj pacjenta
            </label>
            <input
              type="text"
              className={inputClass}
              placeholder="Wpisz imię, nazwisko lub numer pacjenta..."
              value={patientSearchQuery}
              onChange={(e) => setPatientSearchQuery(e.target.value)}
            />
          </div>

          {/* Patient List with Time Selection */}
          <div className="mb-4 max-h-96 space-y-3 overflow-y-auto pr-2">
            {filteredPatients.length === 0 ? (
              <p className="text-sm text-ivory-100/60">Brak wyników.</p>
            ) : (
              filteredPatients.map((patient) => {
                const isSelected = selectedPatientId === patient.id;
                return (
                  <div
                    key={patient.id}
                    className={`rounded-2xl border ${
                      isSelected ? "ring-2 ring-amber-400 border-amber-400/50 bg-amber-500/10" : "border-white/10 bg-white/5"
                    } p-4 transition-colors`}
                  >
                    <div className="flex items-start justify-between gap-4">
                      <button
                        type="button"
                        onClick={() => {
                          setSelectedPatientId(patient.id);
                          if (!appointmentStartTime) {
                            setAppointmentStartTime(showPatientRegistrationModal.startTime);
                            setAppointmentEndTime(showPatientRegistrationModal.endTime);
                          }
                        }}
                        className="flex-1 text-left"
                      >
                        <div>
                          <p className="font-semibold text-ivory-100">{patient.display_name}</p>
                          {patient.patient_number && (
                            <p className="text-xs text-ivory-100/60">Nr pacjenta: {patient.patient_number}</p>
                          )}
                          {(patient.email || patient.phone) && (
                            <p className="text-xs text-ivory-100/50 mt-0.5">
                              {patient.email ? `Email: ${patient.email}` : ""}
                              {patient.email && patient.phone ? " • " : ""}
                              {patient.phone ? `Tel: ${patient.phone}` : ""}
                            </p>
                          )}
                        </div>
                      </button>
                      <span className="text-xs text-ivory-100/50 flex-shrink-0">
                        {isSelected ? "✓ Wybrane" : "Wybierz"}
                      </span>
                    </div>

                    {/* Time Selection and Procedure - shown only for selected patient */}
                    {isSelected && (
                      <div className="mt-4 space-y-3 pt-4 border-t border-white/10">
                        {/* Procedure Selection */}
                        <div>
                          <label className="block text-sm font-medium text-ivory-100/80 mb-2">
                            Procedura
                          </label>
                          <select
                            className={inputClass}
                            value={selectedTreatmentType || ""}
                            onChange={(e) => {
                              setSelectedTreatmentType(e.target.value);
                              // Auto-set duration based on treatment type
                              if (e.target.value) {
                                const treatment = treatmentTypes.find((t) => t.id === e.target.value);
                                if (treatment && appointmentStartTime) {
                                  const startMinutes = labelToMinutes(appointmentStartTime);
                                  const endMinutes = startMinutes + treatment.default_duration_minutes;
                                  setAppointmentEndTime(minutesToLabel(endMinutes));
                                }
                              }
                            }}
                          >
                            <option value="">Wybierz procedurę</option>
                            {treatmentTypes.map((treatment) => (
                              <option key={treatment.id} value={treatment.id}>
                                {treatment.name} ({treatment.default_duration_minutes} min)
                              </option>
                            ))}
                          </select>
                        </div>

                        {/* Time Range Selection */}
                        <div>
                          <div className="flex items-center justify-between mb-2">
                            <label className="block text-sm font-medium text-ivory-100/80">
                              Przedział godzinowy (format 24h, krok 15 min)
                            </label>
                            <button
                              type="button"
                              onClick={async () => {
                                // FIFO: Find next available slot starting from clicked time
                                try {
                                  // Get duration from selected treatment or default 15 minutes
                                  let durationMinutes = 15;
                                  if (selectedTreatmentType) {
                                    const treatment = treatmentTypes.find((t) => t.id === selectedTreatmentType);
                                    if (treatment) {
                                      durationMinutes = treatment.default_duration_minutes;
                                    }
                                  }

                                  // Get day metadata to find opening hours
                                  const dayMeta = week.days.find((d) => d.date === showPatientRegistrationModal.day);
                                  if (!dayMeta) {
                                    setPatientError("Nie znaleziono danych dla wybranego dnia.");
                                    return;
                                  }

                                  // Get opening hours for this specific day
                                  const dayHours = getDayOpeningHours(dayMeta.dayIndex);
                                  
                                  // Check if day is closed
                                  if (dayHours.closed) {
                                    setPatientError("Wybrany dzień jest dniem wolnym od pracy.");
                                    return;
                                  }

                                  // Get existing appointments for this dentist and day
                                  const dayAppointments = getAppointmentsForDayAndDentist(
                                    showPatientRegistrationModal.day,
                                    showPatientRegistrationModal.dentistId
                                  );

                                  // Use opening hours for this specific day
                                  const clinicStart = dayHours.startMinutes;
                                  const clinicEnd = dayHours.endMinutes;

                                  // Start from beginning of day (FIFO - first available slot)
                                  let searchStartMinutes = clinicStart;

                                  // Check if there's enough time until closing
                                  const timeUntilClosing = clinicEnd - searchStartMinutes;
                                  if (timeUntilClosing < durationMinutes) {
                                    setPatientError(`Do końca pracy gabinetu (${minutesToLabel(clinicEnd)}) brakuje czasu na zabieg (${durationMinutes} min).`);
                                    return;
                                  }

                                  // Find next available slot (FIFO)
                                  let foundSlot = false;
                                  let slotStartMinutes = searchStartMinutes;

                                  // Search through all time slots
                                  for (const slotTime of allTimeSlots) {
                                    slotStartMinutes = labelToMinutes(slotTime);
                                    const slotEndMinutes = slotStartMinutes + durationMinutes;

                                    // Check if slot is within working hours
                                    if (slotStartMinutes < clinicStart || slotEndMinutes > clinicEnd) {
                                      continue;
                                    }

                                    // Check if slot is after or equal to search start
                                    if (slotStartMinutes < searchStartMinutes) {
                                      continue;
                                    }

                                    // Check if there's enough time until closing for this slot
                                    if (slotEndMinutes > clinicEnd) {
                                      // No more slots available - not enough time until closing
                                      break;
                                    }

                                    // Check if slot is free (no overlapping appointments)
                                    const isOccupied = dayAppointments.some((apt) => {
                                      const aptStart = labelToMinutes(apt.startTime);
                                      const aptEnd = aptStart + apt.durationMinutes;
                                      // Check for overlap
                                      return (
                                        (slotStartMinutes >= aptStart && slotStartMinutes < aptEnd) ||
                                        (slotEndMinutes > aptStart && slotEndMinutes <= aptEnd) ||
                                        (slotStartMinutes <= aptStart && slotEndMinutes >= aptEnd)
                                      );
                                    });

                                    if (!isOccupied) {
                                      foundSlot = true;
                                      break;
                                    }
                                  }

                                  if (foundSlot) {
                                    setAppointmentStartTime(minutesToLabel(slotStartMinutes));
                                    setAppointmentEndTime(minutesToLabel(slotStartMinutes + durationMinutes));
                                    setPatientError(""); // Clear any previous errors
                                  } else {
                                    // Check if it's because of insufficient time
                                    const lastPossibleStart = clinicEnd - durationMinutes;
                                    if (searchStartMinutes > lastPossibleStart) {
                                      setPatientError(`Do końca pracy gabinetu (${minutesToLabel(clinicEnd)}) brakuje czasu na zabieg (${durationMinutes} min).`);
                                    } else {
                                      setPatientError("Nie znaleziono wolnego terminu w godzinach pracy gabinetu.");
                                    }
                                  }
                                } catch (error) {
                                  console.error("Error finding recommended slot:", error);
                                  setPatientError("Wystąpił błąd podczas wyszukiwania wolnego terminu.");
                                }
                              }}
                              className="text-xs text-amber-400 hover:text-amber-300 underline"
                            >
                              Użyj rekomendowane
                            </button>
                          </div>
                          <div className="grid grid-cols-2 gap-4">
                            <label className="text-sm text-ivory-100/70">
                              Godzina rozpoczęcia
                              <input
                                type="time"
                                className={inputClass}
                                value={appointmentStartTime}
                                onChange={(e) => {
                                  setAppointmentStartTime(e.target.value);
                                  // Auto-update end time if treatment type is selected
                                  if (selectedTreatmentType) {
                                    const treatment = treatmentTypes.find((t) => t.id === selectedTreatmentType);
                                    if (treatment && e.target.value) {
                                      const startMinutes = labelToMinutes(e.target.value);
                                      const endMinutes = startMinutes + treatment.default_duration_minutes;
                                      setAppointmentEndTime(minutesToLabel(endMinutes));
                                    }
                                  }
                                }}
                                step="900"
                              />
                            </label>
                            <label className="text-sm text-ivory-100/70">
                              Godzina zakończenia
                              <input
                                type="time"
                                className={inputClass}
                                value={appointmentEndTime}
                                onChange={(e) => setAppointmentEndTime(e.target.value)}
                                step="900"
                              />
                            </label>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                );
              })
            )}
          </div>

          <div className="flex gap-2 pt-4 border-t border-white/10">
            <button
              type="button"
              className="flex-1 rounded-lg py-2 text-sm font-semibold text-white bg-amber-500 hover:bg-amber-400 disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={!selectedPatientId || isSubmittingPatient}
              onClick={handleSave}
            >
              {isSubmittingPatient ? (
                <>
                  <span
                    className="material-symbols-outlined animate-spin"
                    style={{ fontVariationSettings: '"FILL" 0, "wght" 400, "GRAD" 0, "opsz" 24' }}
                  >
                    progress_activity
                  </span>
                  Zapisywanie...
                </>
              ) : (
                editingAppointmentId ? "Zaktualizuj wizytę" : "Zapisz wizytę"
              )}
            </button>
            <button
              type="button"
              className="flex-1 rounded-lg border border-white/10 py-2 text-sm text-ivory-100 transition hover:bg-white/5"
              onClick={() => {
                setShowPatientRegistrationModal(null);
                setSelectedPatientId(null);
                setPatientSearchQuery("");
                setAppointmentStartTime("");
                setAppointmentEndTime("");
                setSelectedTreatmentType(null);
                setPatientError("");
                setEditingAppointmentId(null);
              }}
            >
              Anuluj
            </button>
          </div>
        </div>
      </div>
    );
  };

  const renderFilterModal = () => {
    if (!showFilterModal) return null;

    return (
      <div className="fixed inset-0 z-40 flex items-center justify-center bg-slate-900/70 p-4">
        <div className="w-full max-w-md rounded-3xl border border-white/10 bg-obsidian-900 p-6 shadow-2xl">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-xs uppercase tracking-[0.3em] text-ivory-100/40">Filtry</p>
              <h3 className="text-xl font-semibold text-ivory-100">Zakres dat i lokalizacje</h3>
            </div>
            <button
              onClick={() => setShowFilterModal(false)}
              className="rounded-full border border-white/15 px-3 py-1 text-sm text-ivory-100/70 hover:bg-white/10"
            >
              <span
                className="material-symbols-outlined"
                style={{ fontVariationSettings: '"FILL" 0, "wght" 300, "GRAD" 0, "opsz" 24' }}
              >
                close
              </span>
            </button>
          </div>

          <div className="space-y-4">
            {/* Date range selection */}
            <div>
              <label className="block text-xs text-ivory-100/60 mb-2">Zakres dat</label>
              <div className="flex items-center gap-2">
                <div className="flex-1">
                  <label className="block text-xs text-ivory-100/40 mb-1">Od</label>
                  <input
                    type="date"
                    value={dateRangeStart}
                    onChange={(e) => setDateRangeStart(e.target.value)}
                    className={inputClass}
                  />
                </div>
                <div className="flex-1">
                  <label className="block text-xs text-ivory-100/40 mb-1">Do</label>
                  <input
                    type="date"
                    value={dateRangeEnd}
                    onChange={(e) => setDateRangeEnd(e.target.value)}
                    className={inputClass}
                  />
                </div>
              </div>
            </div>

            {/* Location selection */}
            {locations.length > 0 && (
              <div>
                <label className="block text-xs text-ivory-100/60 mb-2">Lokalizacja</label>
                <div className="space-y-2 max-h-48 overflow-y-auto">
                  <button
                    type="button"
                    onClick={() => setSelectedLocationId(null)}
                    className={`w-full rounded-lg border px-4 py-3 text-left text-sm text-ivory-100 transition-colors ${
                      selectedLocationId === null
                        ? "border-amber-500/50 bg-amber-500/10"
                        : "border-white/10 bg-white/5 hover:bg-white/10"
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <span className="material-symbols-outlined text-sm">location_on</span>
                      <span className="font-semibold">Wszystkie lokalizacje</span>
                    </div>
                  </button>
                  {locations.map((location) => (
                    <button
                      key={location.id}
                      type="button"
                      onClick={() => setSelectedLocationId(location.id)}
                      className={`w-full rounded-lg border px-4 py-3 text-left text-sm text-ivory-100 transition-colors ${
                        selectedLocationId === location.id
                          ? "border-amber-500/50 bg-amber-500/10"
                          : "border-white/10 bg-white/5 hover:bg-white/10"
                      }`}
                    >
                      <div className="flex items-center gap-3">
                        <span className="material-symbols-outlined text-sm">business</span>
                        <div className="flex-1">
                          <p className="font-semibold">{location.name}</p>
                          {location.city && (
                            <p className="text-xs text-ivory-100/60 mt-0.5">{location.city}</p>
                          )}
                        </div>
                      </div>
                    </button>
                  ))}
                </div>
              </div>
            )}

            <div className="flex gap-2 pt-2">
              <button
                type="button"
                onClick={() => {
                  setShowFilterModal(false);
                  // TODO: Apply filters to calendar
                }}
                className="flex-1 rounded-lg bg-amber-500 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-600 transition-colors"
              >
                Zastosuj
              </button>
              <button
                type="button"
                onClick={() => {
                  setShowFilterModal(false);
                  setSelectedLocationId(null);
                  setDateRangeStart(week.startISO);
                  setDateRangeEnd(week.endISO);
                }}
                className="flex-1 rounded-lg border border-white/10 px-4 py-2 text-sm text-ivory-100 hover:bg-white/5 transition-colors"
              >
                Resetuj
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  };

  const renderAddDoctorModal = () => {
    if (!showAddDoctorModal) return null;

    const dayMeta = week.days.find((d) => d.date === showAddDoctorModal.day);
    const assignedDoctorIds = dayDoctors.get(showAddDoctorModal.day) || [];

    // Show ALL doctors - user can assign same doctor to different days
    // Filter out invalid entries and remove duplicates by id
    const availableDoctors = doctors
      .filter((doc) => {
        // Must have at least an id to be valid
        return doc && doc.id;
      })
      .filter((doc, index, self) => {
        // Remove duplicates by id
        return index === self.findIndex((d) => d.id === doc.id);
      });

    // Debug logging
    if (availableDoctors.length === 0 && doctors.length > 0) {
      console.warn("All doctors were filtered out:", doctors);
    }

    // If doctor is selected, show time selection form
    if (selectedDoctorForModal) {
      // Get opening hours for this day
      const dayIndex = dayMeta ? dayMeta.dayIndex : 0;
      const dayHours = getDayOpeningHours(dayIndex);
      
      // Calculate default hours: 8 hours from opening time
      const getDefaultHours = () => {
        if (dayHours.closed || !selectedLocation?.opening_hours) {
          return { start: "08:00", end: "17:00" };
        }
        const openTime = dayHours.startMinutes;
        const closeTime = dayHours.endMinutes;
        // Default: 8 hours from opening (or until closing if less than 8 hours)
        const defaultEndMinutes = Math.min(openTime + (8 * 60), closeTime);
        return {
          start: minutesToLabel(openTime),
          end: minutesToLabel(defaultEndMinutes),
        };
      };

      const defaultHours = getDefaultHours();
      const fullDayHours = dayHours.closed 
        ? { start: "00:00", end: "23:59" }
        : {
            start: minutesToLabel(dayHours.startMinutes),
            end: minutesToLabel(dayHours.endMinutes),
          };

      return (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-slate-900/70 p-4">
          <div className="w-full max-w-md rounded-3xl border border-white/10 bg-obsidian-900 p-6 shadow-2xl">
            <div className="flex items-center justify-between mb-4">
              <div>
                <p className="text-xs uppercase tracking-[0.3em] text-ivory-100/40">Ustaw godziny pracy</p>
                <h3 className="text-xl font-semibold text-ivory-100">{selectedDoctorForModal.name}</h3>
                <p className="text-sm text-ivory-100/60">{dayMeta?.label || showAddDoctorModal.day}</p>
              </div>
              <button
                onClick={() => {
                  setSelectedDoctorForModal(null);
                  setDoctorStartTime(defaultHours.start);
                  setDoctorEndTime(defaultHours.end);
                  setSaveDoctorError(null);
                  setIsSavingDoctor(false);
                }}
                className="rounded-full border border-white/15 px-3 py-1 text-sm text-ivory-100/70 hover:bg-white/10"
              >
                <span
                  className="material-symbols-outlined"
                  style={{ fontVariationSettings: '"FILL" 0, "wght" 300, "GRAD" 0, "opsz" 24' }}
                >
                  arrow_back
                </span>
              </button>
            </div>

            <div className="space-y-4">
              <div className="flex items-center gap-2">
                <div className="flex-1">
                  <label className="block text-xs text-ivory-100/60 mb-1">Godzina rozpoczęcia</label>
                  <input
                    type="time"
                    step="900"
                    value={doctorStartTime}
                    onChange={(e) => setDoctorStartTime(e.target.value)}
                    className={inputClass}
                  />
                </div>
                <div className="flex-1">
                  <label className="block text-xs text-ivory-100/60 mb-1">Godzina zakończenia</label>
                  <input
                    type="time"
                    step="900"
                    value={doctorEndTime}
                    onChange={(e) => setDoctorEndTime(e.target.value)}
                    className={inputClass}
                  />
                </div>
              </div>

              {!dayHours.closed && (
                <button
                  type="button"
                  onClick={() => {
                    setDoctorStartTime(fullDayHours.start);
                    setDoctorEndTime(fullDayHours.end);
                  }}
                  className="w-full rounded-lg border border-amber-500/50 bg-amber-500/10 px-4 py-2 text-sm text-amber-400 hover:bg-amber-500/20 transition-colors"
                >
                  Cały dzień ({fullDayHours.start} - {fullDayHours.end})
                </button>
              )}

              <div className="flex flex-col gap-3 pt-2">
                <div className="flex gap-2">
                <button
                  type="button"
                  onClick={async () => {
                    setSaveDoctorError(null);
                    setIsSavingDoctor(true);
                    try {
                      const res = await fetch("/api/day-doctors", {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({
                          date: showAddDoctorModal.day,
                          dentistId: selectedDoctorForModal.id,
                          startTime: doctorStartTime,
                          endTime: doctorEndTime,
                          location_id: selectedLocationId,
                        }),
                      });
                      const data = await res.json();
                      if (res.ok) {
                        await fetchDayDoctors(showAddDoctorModal.day);
                        setShowAddDoctorModal(null);
                        setSelectedDoctorForModal(null);
                        // Reset to default hours based on opening hours
                        const dayIndex = dayMeta ? dayMeta.dayIndex : 0;
                        const dayHours = getDayOpeningHours(dayIndex);
                        if (dayHours.closed || !selectedLocation?.opening_hours) {
                          setDoctorStartTime("08:00");
                          setDoctorEndTime("17:00");
                        } else {
                          const openTime = dayHours.startMinutes;
                          const closeTime = dayHours.endMinutes;
                          const defaultEndMinutes = Math.min(openTime + (8 * 60), closeTime);
                          setDoctorStartTime(minutesToLabel(openTime));
                          setDoctorEndTime(minutesToLabel(defaultEndMinutes));
                        }
                        setSaveDoctorError(null);
                        setIsSavingDoctor(false);
                        router.refresh();
                        return;
                      }
                      throw new Error(data?.error || "Nie udało się dodać lekarza do grafiku.");
                    } catch (error) {
                      console.error("Error adding doctor to day:", error);
                      setSaveDoctorError(error instanceof Error ? error.message : "Wystąpił błąd podczas zapisywania.");
                    } finally {
                      setIsSavingDoctor(false);
                    }
                  }}
                  disabled={isSavingDoctor}
                  className="flex-1 rounded-lg bg-amber-500 px-4 py-2 text-sm font-semibold text-white hover:bg-amber-600 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isSavingDoctor ? "Zapisywanie..." : "Zapisz"}
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setSelectedDoctorForModal(null);
                    setDoctorStartTime("08:00");
                    setDoctorEndTime("17:00");
                    setSaveDoctorError(null);
                    setIsSavingDoctor(false);
                  }}
                  className="flex-1 rounded-lg border border-white/10 px-4 py-2 text-sm text-ivory-100 hover:bg-white/5 transition-colors"
                >
                  Anuluj
                </button>
              </div>
                {saveDoctorError && (
                  <p className="text-sm text-red-400">{saveDoctorError}</p>
                )}
              </div>
            </div>
          </div>
        </div>
      );
    }

    // Show doctor selection list
    return (
      <div className="fixed inset-0 z-40 flex items-center justify-center bg-slate-900/70 p-4">
        <div className="w-full max-w-md rounded-3xl border border-white/10 bg-obsidian-900 p-6 shadow-2xl">
          <div className="flex items-center justify-between mb-4">
            <div>
              <p className="text-xs uppercase tracking-[0.3em] text-ivory-100/40">Dodaj lekarza</p>
              <h3 className="text-xl font-semibold text-ivory-100">{dayMeta?.label || showAddDoctorModal.day}</h3>
            </div>
            <button
              onClick={() => {
                setShowAddDoctorModal(null);
                setSelectedDoctorForModal(null);
                // Reset to default hours
                const dayIndex = dayMeta ? dayMeta.dayIndex : 0;
                const dayHours = getDayOpeningHours(dayIndex);
                if (dayHours.closed || !selectedLocation?.opening_hours) {
                  setDoctorStartTime("08:00");
                  setDoctorEndTime("17:00");
                } else {
                  const openTime = dayHours.startMinutes;
                  const closeTime = dayHours.endMinutes;
                  const defaultEndMinutes = Math.min(openTime + (8 * 60), closeTime);
                  setDoctorStartTime(minutesToLabel(openTime));
                  setDoctorEndTime(minutesToLabel(defaultEndMinutes));
                }
              }}
              className="rounded-full border border-white/15 px-3 py-1 text-sm text-ivory-100/70 hover:bg-white/10"
            >
              <span
                className="material-symbols-outlined"
                style={{ fontVariationSettings: '"FILL" 0, "wght" 300, "GRAD" 0, "opsz" 24' }}
              >
                close
              </span>
            </button>
          </div>

          <div className="space-y-2 max-h-96 overflow-y-auto">
            {availableDoctors.length === 0 ? (
              <div className="space-y-2">
                <p className="text-sm text-ivory-100/60">Brak dostępnych lekarzy w systemie.</p>
                {doctors.length > 0 ? (
                  <p className="text-xs text-ivory-100/40">
                    Znaleziono {doctors.length} lekarzy w prop, ale nie można ich wyświetlić. Sprawdź konsolę przeglądarki (F12) dla szczegółów.
                  </p>
                ) : (
                  <p className="text-xs text-ivory-100/40">
                    Brak lekarzy w prop `doctors`. Sprawdź, czy lekarze są aktywni (`active = true`) w bazie danych.
                  </p>
                )}
              </div>
            ) : (
              availableDoctors.map((doctor) => {
                const isAlreadyAssigned = assignedDoctorIds.includes(doctor.id);
                return (
                <button
                  key={doctor.id}
                  type="button"
                  onClick={() => {
                    setSelectedDoctorForModal(doctor);
                  }}
                  className={`w-full rounded-lg border px-4 py-3 text-left text-sm text-ivory-100 transition-colors ${
                    isAlreadyAssigned
                      ? "border-amber-500/50 bg-amber-500/10 hover:bg-amber-500/20"
                      : "border-white/10 bg-white/5 hover:bg-white/10"
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-gradient-to-br from-ember-400 to-ember-600 flex items-center justify-center text-white font-semibold">
                      {(doctor.name && doctor.name.length > 0) ? doctor.name.charAt(0).toUpperCase() : "?"}
                    </div>
                    <div className="flex-1">
                      <p className="font-semibold">{doctor.name || "Lekarz bez nazwy"}</p>
                      {isAlreadyAssigned && (
                        <p className="text-xs text-amber-400/80 mt-0.5">Już przypisany do tego dnia (możesz zmienić godziny)</p>
                      )}
                    </div>
                  </div>
                </button>
              );
              })
            )}
          </div>
        </div>
      </div>
    );
  };

  return (
    <div className="space-y-6 flex flex-col h-full min-h-0">

      {/* Top bar with days and filter button in one row */}
      <div className="marble-card p-4">
        <div className="flex items-center gap-4">
          {/* Day selection bar - 30 days from today */}
          <div className="flex items-center gap-2 overflow-x-auto flex-1">
            {week.days.filter((day) => {
              // Show only days from today onwards (30 days)
              const dayDate = new Date(day.date);
              const todayDate = new Date(todayISO);
              dayDate.setHours(0, 0, 0, 0);
              todayDate.setHours(0, 0, 0, 0);
              return dayDate >= todayDate;
            }).map((day) => {
              const dayNumber = new Date(day.date).getUTCDate();
              const dayIndex = (new Date(day.date).getUTCDay() + 6) % 7;
              const isToday = day.date === todayISO;
              const isSelected = day.date === selectedDay;
              const dayHours = getDayOpeningHours(dayIndex);
              const isClosed = dayHours.closed;

              return (
                <button
                  key={day.date}
                  type="button"
                  onClick={() => setSelectedDay(day.date)}
                  className={`flex-shrink-0 flex flex-col items-center gap-1 px-3 py-2 rounded-lg transition-colors relative ${
                  isSelected
                    ? "bg-amber-500 text-white"
                    : isToday
                    ? "bg-amber-500/20 text-amber-400"
                    : isClosed
                    ? "bg-white/2 text-ivory-100/30 opacity-50"
                    : "hover:bg-white/5 text-ivory-100/60"
                  }`}
                  title={isClosed ? "Wolne - gabinet zamknięty" : undefined}
                >
                  <span className="text-xs font-medium">{dayAbbreviations[dayIndex]}</span>
                  <span className={`text-lg font-semibold ${isSelected ? "text-white" : ""}`}>
                    {dayNumber}
                  </span>
                </button>
              );
            })}
          </div>

          {/* Filter button */}
          <div className="flex items-center gap-2 flex-shrink-0">
            <button
              type="button"
              onClick={() => setShowFilterModal(true)}
              className="p-2 rounded-lg border border-white/10 hover:bg-white/5"
              title="Filtruj daty i lokalizacje"
            >
              <Icon icon="filter_alt" className="text-ivory-100/60 text-lg" />
            </button>
          </div>
        </div>
      </div>

      {/* Calendar grid */}
      <div
        className="marble-card w-full flex flex-col"
        style={{
          maxHeight: isMobile ? '70vh' : 'calc(100vh - 320px)',
          height: isMobile ? '70vh' : 'calc(100vh - 320px)',
          overflow: 'hidden',
          display: 'flex',
          flexDirection: 'column',
          position: 'relative'
        }}
      >
        {/* Top bar with date indicator, add button and doctors - STICKY (hidden if day is closed) */}
        {(() => {
          const selectedDayMeta = week.days.find((d) => d.date === selectedDay);
          if (!selectedDayMeta) return null;
          const dayNumber = new Date(selectedDayMeta.date).getUTCDate();
          const dayIndex = (new Date(selectedDayMeta.date).getUTCDay() + 6) % 7;
          const isToday = selectedDayMeta.date === todayISO;
          const dayHours = getDayOpeningHours(dayIndex);
          const isClosed = dayHours.closed;

          // Hide header for closed days
          if (isClosed) return null;

          return (
            <div
              ref={headerScrollRef}
              className="flex border-b border-white/10 bg-obsidian-900/95 sticky top-0 z-20 flex-shrink-0 overflow-x-auto overflow-y-hidden"
              style={{ minWidth: '100%' }}
            >
              {/* Date indicator column - sticky left */}
              <div
                className="flex-shrink-0 border-r border-white/10 p-3 sticky left-0 bg-obsidian-900/95 z-21"
                style={{ width: `${TIME_COLUMN_WIDTH}px` }}
              >
                <div className="text-center">
                  <div className={`text-xs font-medium mb-1 ${isToday ? "text-amber-400" : "text-ivory-100/60"}`}>
                    {dayAbbreviations[dayIndex]}
                  </div>
                  <div
                    className={`text-lg font-semibold rounded-full w-10 h-10 mx-auto flex items-center justify-center ${
                      isToday
                        ? "bg-amber-500 text-white"
                        : "text-ivory-100/80"
                    }`}
                  >
                    {dayNumber}
                  </div>
                  {isToday && (
                    <div className="text-[10px] text-amber-400/80 mt-1">
                      Dzisiaj
                    </div>
                  )}
                </div>
              </div>

              {/* Scrollable columns container - doctors and add button */}
              <div className="flex flex-shrink-0 header-scrollable-content" style={{ minWidth: 'max-content' }}>
              {/* Doctors columns - only doctors assigned to this day (hidden if day is closed) */}
              {!isClosed && getDoctorsForDay(selectedDayMeta.date).map((dentist) => {
                const schedule = getDentistSchedule(dentist.id, selectedDayMeta.date);
                return (
                  <div
                    key={dentist.id}
                    className="flex-shrink-0 w-[200px] border-r border-white/10 p-2"
                  >
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-full bg-gradient-to-br from-ember-400 to-ember-600 flex items-center justify-center text-white font-semibold text-xs flex-shrink-0">
                        {dentist.name.charAt(0).toUpperCase()}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-semibold text-ivory-100 truncate text-xs">
                          {dentist.name}
                        </div>
                        {schedule && (
                          <div className="text-[10px] text-ivory-100/60">
                            {schedule.start_time} - {schedule.end_time}
                          </div>
                        )}
                      </div>
                      <button
                        type="button"
                        onClick={async () => {
                          try {
                            const res = await fetch(
                              `/api/day-doctors?date=${selectedDayMeta.date}&dentistId=${dentist.id}`,
                              { method: "DELETE" }
                            );
                            if (res.ok) {
                              await fetchDayDoctors(selectedDayMeta.date);
                              router.refresh();
                            }
                          } catch (error) {
                            console.error("Error removing doctor from day:", error);
                          }
                        }}
                        className="ml-auto p-1 rounded hover:bg-white/10 transition-colors"
                        title="Usuń lekarza z dnia"
                      >
                        <span
                          className="material-symbols-outlined text-ivory-100/60 hover:text-red-400 text-sm"
                          style={{ fontVariationSettings: '"FILL" 0, "wght" 300, "GRAD" 0, "opsz" 24' }}
                        >
                          close
                        </span>
                      </button>
                    </div>
                  </div>
                );
              })}

              {/* Add doctor button - appears after all doctors (only if day is open) */}
              {!isClosed && (
                <div className="flex-shrink-0 w-[200px] border-r border-white/10 p-3 flex items-center justify-center">
                  <button
                    type="button"
                    onClick={() => setShowAddDoctorModal({ day: selectedDayMeta.date })}
                    className="w-10 h-10 rounded-full bg-gradient-to-br from-amber-500 to-amber-700 text-white shadow-lg flex items-center justify-center hover:from-amber-600 hover:to-amber-800 transition-all transform hover:scale-105"
                    title="Dodaj lekarza"
                  >
                    <Icon icon="filter_alt" className="text-white text-xl" />
                  </button>
                </div>
              )}
              </div>
            </div>
          );
        })()}

        {/* Scrollable calendar content - only this area scrolls */}
        {(() => {
          const selectedDayMeta = week.days.find((d) => d.date === selectedDay);
          if (!selectedDayMeta) return null;
          const dayHours = getDayOpeningHours(selectedDayMeta.dayIndex);
          const isClosed = dayHours.closed;

          // If day is closed, show only "Wolne" message
          if (isClosed) {
            return (
              <div className="flex flex-1 items-center justify-center">
                <div className="text-center space-y-2">
                  <div className="text-6xl mb-4">🏖️</div>
                  <h3 className="text-2xl font-semibold text-ivory-100">Wolne</h3>
                  <p className="text-ivory-100/60">Gabinet jest zamknięty w ten dzień</p>
                </div>
              </div>
            );
          }

          return (
            <div
              ref={contentScrollRef}
              className="flex flex-1 overflow-y-auto overflow-x-auto"
              style={{
                flex: '1 1 auto',
                minHeight: 0,
              }}
              onScroll={(e) => {
            const scrollTop = e.currentTarget.scrollTop;
            const scrollLeft = e.currentTarget.scrollLeft;
            setScrollPosition(scrollTop);
            if (!isAutoScrollingRef.current) {
              lastManualScrollRef.current = Date.now();
            }
            // Sync time column markers
            if (timeScrollRef.current) {
              timeScrollRef.current.scrollTop = scrollTop;
            }
            // Sync day columns
            if (daysScrollRef.current) {
              daysScrollRef.current.scrollTop = scrollTop;
            }
            // Sync horizontal scroll with header - move scrollable columns container
            if (headerScrollRef.current) {
              const scrollableContainer = headerScrollRef.current.querySelector('.header-scrollable-content') as HTMLElement;
              if (scrollableContainer) {
                scrollableContainer.style.marginLeft = `-${scrollLeft}px`;
              }
            }
            if (isAutoScrollingRef.current) {
              isAutoScrollingRef.current = false;
            }
          }}
          onTouchStart={handleTouchStart}
          onTouchMove={handleTouchMove}
          onTouchEnd={handleTouchEnd}
          onWheel={handleWheel}
        >
          {/* Time column - sticky left, fixed when scrolling horizontally */}
          <div
            className="flex-shrink-0 border-r border-white/10 sticky left-0 z-50"
            style={{ 
              width: `${TIME_COLUMN_WIDTH}px`, 
              position: 'sticky',
              backgroundColor: 'rgba(0, 0, 0, 0.75)'
            }}
          >
            <div
              className="relative"
              style={{
                height: `${totalHeight}px`,
                backgroundColor: 'rgba(0, 0, 0, 0.75)'
              }}
            >
              <div
                ref={timeScrollRef}
                className="absolute inset-0 z-10"
                style={{ 
                  pointerEvents: 'none',
                  backgroundColor: 'rgba(0, 0, 0, 0.75)'
                }}
              >
                <div style={{ 
                  height: `${totalHeight}px`,
                  backgroundColor: 'rgba(0, 0, 0, 0.75)'
                }}>
                  {allTimeSlots.map((slot, slotIdx) => {
                    const slotMinutes = labelToMinutes(slot);
                    const position = slotIdx * SLOT_HEIGHT_PX;
                    const minutes = slotMinutes % 60;
                    const hours = Math.floor(slotMinutes / 60);
                    const isHour = minutes === 0;
                    const isQuarter = minutes === 15 || minutes === 30 || minutes === 45;

                    return (
                      <div
                        key={slot}
                        className="absolute left-0 right-0"
                        style={{
                          top: `${position}px`,
                        }}
                      >
                        <div className="px-2 text-right">
                          {isHour ? (
                            <span className="text-sm font-semibold text-ivory-100">
                              {minutesToLabel(slotMinutes)}
                            </span>
                          ) : isQuarter ? (
                            <span className="text-[11px] text-ivory-100/60">
                              {minutes}
                            </span>
                          ) : null}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
              
              {/* Current time indicator in time column */}
              {(() => {
                const selectedDayMeta = week.days.find((d) => d.date === selectedDay);
                if (!selectedDayMeta) return null;
                const currentTimePos = getCurrentTimePosition(selectedDayMeta.date);
                if (!currentTimePos) return null;
                
                return (
                  <div
                    className="absolute left-0 right-0 z-50 pointer-events-none"
                    style={{ top: currentTimePos.top }}
                  >
                    <div className="relative flex items-center px-2">
                      {/* Circle indicator in time column */}
                      <div className="w-3 h-3 rounded-full bg-amber-500 border-2 border-black flex-shrink-0"></div>
                      {/* Arrow pointing right */}
                      <div className="w-0 h-0 border-t-[6px] border-b-[6px] border-l-[8px] border-t-transparent border-b-transparent border-l-amber-500 ml-1"></div>
                    </div>
                  </div>
                );
              })()}
            </div>
          </div>

              {/* Selected day column - time slots for doctors */}
              <div className="flex-shrink-0" style={{ minWidth: 'max-content', width: '100%' }}>
                {(() => {
                  const selectedDayMeta = week.days.find((d) => d.date === selectedDay);
                  if (!selectedDayMeta) return null;

                  const doctorsForDay = getDoctorsForDay(selectedDayMeta.date);
                  const currentTimePos = getCurrentTimePosition(selectedDayMeta.date);
                  
                  return (
                <div className="flex relative" style={{ height: `${totalHeight}px`, width: '100%' }}>
                  {/* Current time line across all doctor columns */}
                  {currentTimePos && (
                    <div
                      className="absolute left-0 right-0 z-30 pointer-events-none"
                      style={{ top: currentTimePos.top }}
                    >
                      <div className="h-0.5 bg-amber-500 w-full"></div>
                    </div>
                  )}
                  
                  {/* Doctor time slot columns - only doctors assigned to this day */}
                  {doctorsForDay.map((dentist, dentistIdx) => {
                    const schedule = getDentistSchedule(dentist.id, selectedDayMeta.date);
                    const dayAppointments = getAppointmentsForDayAndDentist(selectedDayMeta.date, dentist.id);

                    return (
                      <div
                        key={`${selectedDayMeta.date}-${dentist.id}`}
                        className="flex-shrink-0 w-[200px] border-r border-white/5 relative cursor-pointer"
                        onClick={(e) => {
                          // Otwórz modal z listą użytkowników przy kliknięciu na kolumnę lekarza
                          if (schedule) {
                            setShowPatientRegistrationModal({
                              dentistId: dentist.id,
                              dentistName: dentist.name,
                              day: selectedDayMeta.date,
                              startTime: schedule.start_time,
                              endTime: schedule.end_time,
                            });
                          }
                        }}
                      >
                        <div
                          className="relative"
                          style={{
                            height: `${totalHeight}px`,
                          }}
                        >
                          <div
                            ref={dentistIdx === 0 ? daysScrollRef : null}
                            className="absolute inset-0"
                            style={{ pointerEvents: 'none' }}
                          >
                            <div style={{ height: `${totalHeight}px` }}>
                              {/* Background with diagonal pattern */}
                              <div
                                className="absolute inset-0 opacity-20"
                                style={{
                                  backgroundImage: "repeating-linear-gradient(45deg, transparent, transparent 4px, rgba(255,255,255,0.03) 4px, rgba(255,255,255,0.03) 8px)",
                                  backgroundSize: "100% 60px",
                                }}
                              />

                              {/* Horizontal borders for each 15-minute slot - filtered by opening hours */}
                              {allTimeSlots.map((slot, slotIdx) => {
                                const slotTop = slotIdx * SLOT_HEIGHT_PX;
                                const isInHours = isSlotInOpeningHours(slot, selectedDayMeta.dayIndex);
                                return (
                                  <div
                                    key={`slot-border-${slot}`}
                                    className={`absolute left-0 right-0 border-b ${
                                      isInHours ? "border-white/10" : "border-white/5"
                                    } ${!isInHours ? "bg-white/2" : ""}`}
                                    style={{
                                      top: `${slotTop}px`,
                                      height: `${SLOT_HEIGHT_PX}px`,
                                    }}
                                  />
                                );
                              })}
                              {/* Last border at the very bottom to complete the grid */}
                              <div
                                className="absolute left-0 right-0 border-b border-white/10"
                                style={{
                                  top: `${totalHeight}px`,
                                }}
                              />

                              {/* Highlight opening hours for this day */}
                              {(() => {
                                const dayHours = getDayOpeningHours(selectedDayMeta.dayIndex);
                                if (dayHours.closed) return null;
                                const startTop = ((dayHours.startMinutes - overallRange.startMinutes) / SLOT_INTERVAL) * SLOT_HEIGHT_PX;
                                const height = ((dayHours.endMinutes - dayHours.startMinutes) / SLOT_INTERVAL) * SLOT_HEIGHT_PX;
                                return (
                                  <div
                                    className="absolute left-0 right-0 bg-emerald-500/5 border-y border-emerald-500/10 z-10"
                                    style={{
                                      top: `${startTop}px`,
                                      height: `${height}px`,
                                      pointerEvents: 'none',
                                    }}
                                  />
                                );
                              })()}
                              {schedule && (
                                <div
                                  className="absolute left-0 right-0 bg-emerald-500/10 border-y border-emerald-500/20 hover:bg-emerald-500/20 transition-colors z-20"
                                  style={{
                                    top: `${((labelToMinutes(schedule.start_time) - overallRange.startMinutes) / SLOT_INTERVAL) * SLOT_HEIGHT_PX}px`,
                                    height: `${((labelToMinutes(schedule.end_time) - labelToMinutes(schedule.start_time)) / SLOT_INTERVAL) * SLOT_HEIGHT_PX}px`,
                                    pointerEvents: 'none',
                                  }}
                                />
                              )}

                              {dayAppointments.map((apt, idx) => renderAppointment(apt, idx))}

                              {/* Clickable area for all slots - covers entire column height */}
                              <div
                                className="absolute left-0 right-0"
                                onClick={(e) => {
                                  e.stopPropagation();
                                  const rect = e.currentTarget.getBoundingClientRect();
                                  const clickY = e.clientY - rect.top;
                                  const slotIndex = Math.floor(clickY / SLOT_HEIGHT_PX);
                                  if (slotIndex >= 0 && slotIndex < allTimeSlots.length) {
                                    const slot = allTimeSlots[slotIndex];
                                    const slotMinutes = labelToMinutes(slot);
                                    // Check if slot is within opening hours
                                    const isInHours = isSlotInOpeningHours(slot, selectedDayMeta.dayIndex);
                                    if (!isInHours) return; // Don't allow clicking outside opening hours
                                    const isOccupied = dayAppointments.some((apt) => {
                                      const aptStart = labelToMinutes(apt.startTime);
                                      const aptEnd = aptStart + apt.durationMinutes;
                                      return slotMinutes >= aptStart && slotMinutes < aptEnd;
                                    });
                                    // Allow clicking on any slot within opening hours
                                    if (!isOccupied) {
                                      const defaultEndTime = minutesToLabel(slotMinutes + SLOT_INTERVAL);
                                      setShowPatientRegistrationModal({
                                        dentistId: dentist.id,
                                        dentistName: dentist.name,
                                        day: selectedDayMeta.date,
                                        startTime: slot,
                                        endTime: defaultEndTime,
                                      });
                                      // Set default time values
                                      setAppointmentStartTime(slot);
                                      setAppointmentEndTime(defaultEndTime);
                                      setSelectedPatientId(null);
                                      setSelectedTreatmentType(null);
                                      setPatientSearchQuery("");
                                      setPatientError("");
                                    }
                                  }
                                }}
                                style={{
                                  cursor: "pointer",
                                  pointerEvents: 'auto',
                                  top: 0,
                                  height: `${totalHeight}px`,
                                  width: '100%'
                                }}
                              />
                            </div>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              );
            })()}
              </div>
            </div>
          );
        })()}
      </div>


      {renderActionPanel()}
      {renderModal()}
      {renderAddDoctorModal()}
      {renderPatientRegistrationModal()}
      {renderFilterModal()}
    </div>
  );
}
