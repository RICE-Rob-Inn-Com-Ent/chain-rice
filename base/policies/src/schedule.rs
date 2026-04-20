//! **Metronom** — UTC temporal anchors for policy: windows, recurrence gates, clock-skew tolerance,
//! and CEL snapshots. No locale, no civil timezone database: everything is [`chrono::Utc`].
//!
//! ## Active checks (hot path)
//!
//! [`ScheduleWindow::is_active_at`] and [`is_active_simple`] compare only [`DateTime`] bounds and
//! integers — **no heap allocation** on the check path.
//!
//! ## CEL
//!
//! Use [`schedule_to_cel_value`] (or [`RuleContext::with_schedule`](crate::rule::RuleContext::with_schedule))
//! so rules can read **`schedule.is_active`** (bool) and RFC 3339 strings for audit. CEL has no
//! host calls here; `is_active` is fixed at snapshot time when the context is built.

use std::collections::HashMap;

use cel_interpreter::Value;
use chrono::{DateTime, Datelike, Duration, Timelike, Utc, Weekday};
use serde::{Deserialize, Serialize};

use crate::error::ScheduleError;

// --- Tolerance ----------------------------------------------------------------

/// Symmetric clock-skew allowance: the effective window becomes
/// \\([start - \\delta, end + \\delta]\\) (when chrono arithmetic does not overflow).
#[derive(Clone, Copy, Debug, PartialEq, Eq, Hash)]
pub struct TimeTolerance(Duration);

impl TimeTolerance {
    pub const ZERO: Self = Self(Duration::zero());

    /// Construct from a non-negative duration.
    pub fn try_new(d: Duration) -> Result<Self, ScheduleError> {
        if d < Duration::zero() {
            return Err(ScheduleError::InvalidRecurrence("time tolerance must be non-negative".into()));
        }
        Ok(Self(d))
    }

    #[must_use]
    pub fn as_duration(self) -> Duration {
        self.0
    }
}

impl Default for TimeTolerance {
    fn default() -> Self {
        Self::ZERO
    }
}

impl TryFrom<Duration> for TimeTolerance {
    type Error = ScheduleError;

    fn try_from(value: Duration) -> Result<Self, Self::Error> {
        Self::try_new(value)
    }
}

// --- Recurrence (UTC-only gates) ----------------------------------------------

/// Optional UTC filters applied **inside** the outer [`ScheduleWindow`].
///
/// * **`weekday_mask`**: `None` = any weekday. `Some(m)`: bits 0..6 = Mon..Sun (see [`weekday_bit`]).
/// * **`utc_daytime`**: `None` = all day UTC. `Some` = seconds-from-midnight band (see [`UtcDaytimeBand`]).
/// * **`month_day`**: `None` = any calendar day. `Some(1..=31)` = only that day-of-month in UTC.
#[derive(Clone, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct RecurrenceGate {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub weekday_mask: Option<u8>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub utc_daytime: Option<UtcDaytimeBand>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub month_day: Option<u8>,
}

/// Half-open UTC time-of-day in seconds from 00:00:00 UTC: \\([start\_sec, end\_sec)\\).
///
/// If `start_sec > end_sec`, the band **wraps across midnight** (e.g. 22:00–06:00 UTC).
#[derive(Clone, Copy, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct UtcDaytimeBand {
    pub start_sec: u32,
    pub end_sec: u32,
}

impl RecurrenceGate {
    pub fn validate(&self) -> Result<(), ScheduleError> {
        if let Some(m) = self.weekday_mask {
            if m == 0 {
                return Err(ScheduleError::InvalidRecurrence(
                    "weekday_mask must not be zero (use null for 'any day')".into(),
                ));
            }
            if m > 0x7F {
                return Err(ScheduleError::InvalidRecurrence(
                    "weekday_mask must use only bits 0..6 (Mon..Sun)".into(),
                ));
            }
        }
        if let Some(d) = self.month_day {
            if !(1..=31).contains(&d) {
                return Err(ScheduleError::InvalidRecurrence(format!("month_day must be 1..=31, got {d}")));
            }
        }
        if let Some(b) = self.utc_daytime {
            b.validate()?;
        }
        Ok(())
    }

    #[inline]
    fn is_empty(&self) -> bool {
        self.weekday_mask.is_none() && self.utc_daytime.is_none() && self.month_day.is_none()
    }
}

impl UtcDaytimeBand {
    pub fn validate(&self) -> Result<(), ScheduleError> {
        if self.start_sec > 86400 || self.end_sec > 86400 {
            return Err(ScheduleError::InvalidRecurrence(format!(
                "utc daytime seconds must be <= 86400, got {}..{}",
                self.start_sec, self.end_sec
            )));
        }
        if self.start_sec == self.end_sec {
            return Err(ScheduleError::InvalidRecurrence(
                "utc daytime band is empty (start_sec == end_sec)".into(),
            ));
        }
        Ok(())
    }

    /// `secs` is `0..86400` from [`utc_seconds_from_midnight`].
    #[inline]
    pub fn contains(self, secs: u32) -> bool {
        if self.start_sec <= self.end_sec {
            secs >= self.start_sec && secs < self.end_sec
        } else {
            secs >= self.start_sec || secs < self.end_sec
        }
    }
}

#[inline]
#[must_use]
pub fn weekday_bit(day: Weekday) -> u8 {
    // Mon = 0 .. Sun = 6 (chrono `num_days_from_monday` fits in u8)
    u8::try_from(day.num_days_from_monday()).unwrap_or(0)
}

#[inline]
fn weekday_selected(mask: u8, day: Weekday) -> bool {
    let bit = weekday_bit(day);
    (mask & (1 << bit)) != 0
}

#[inline]
#[must_use]
pub fn utc_seconds_from_midnight(dt: DateTime<Utc>) -> u32 {
    let t = dt.time();
    t.num_seconds_from_midnight() as u32
}

// --- Window (wire + engine) ---------------------------------------------------

/// Inclusive UTC policy window. Serialized as RFC 3339 / ISO 8601 strings via serde + chrono.
///
/// Optional [`RecurrenceGate`] narrows activity inside `[start, end]` without introducing local
/// calendars.
#[derive(Clone, Debug, PartialEq, Eq, Serialize, Deserialize)]
pub struct ScheduleWindow {
    pub start: DateTime<Utc>,
    pub end: DateTime<Utc>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub recurrence: Option<RecurrenceGate>,
}

impl ScheduleWindow {
    pub fn validate(&self) -> Result<(), ScheduleError> {
        if self.end < self.start {
            return Err(ScheduleError::InvalidPeriod);
        }
        if let Some(ref g) = self.recurrence {
            if !g.is_empty() {
                g.validate()?;
            }
        }
        Ok(())
    }

    /// Inclusive bounds with symmetric tolerance, or `None` if arithmetic overflows.
    #[must_use]
    pub fn effective_bounds(&self, tol: TimeTolerance) -> Option<(DateTime<Utc>, DateTime<Utc>)> {
        let s = self.start.checked_sub_signed(tol.0)?;
        let e = self.end.checked_add_signed(tol.0)?;
        Some((s, e))
    }

    /// **Hot path:** `true` iff `now` lies in the tolerance-expanded window and satisfies recurrence.
    #[must_use]
    pub fn is_active_at(&self, now: DateTime<Utc>, tol: TimeTolerance) -> bool {
        let Some((lo, hi)) = self.effective_bounds(tol) else {
            return false;
        };
        if now < lo || now > hi {
            return false;
        }
        let Some(ref gate) = self.recurrence else {
            return true;
        };
        if gate.is_empty() {
            return true;
        }
        if let Some(mask) = gate.weekday_mask {
            if !weekday_selected(mask, now.weekday()) {
                return false;
            }
        }
        if let Some(dom) = gate.month_day {
            if now.day() != u32::from(dom) {
                return false;
            }
        }
        if let Some(band) = gate.utc_daytime {
            let secs = utc_seconds_from_midnight(now);
            if !band.contains(secs) {
                return false;
            }
        }
        true
    }
}

// --- CEL snapshot -------------------------------------------------------------

/// Build a CEL `map` for variable `schedule`: `is_active`, bounds, `now`, tolerance (allocates for strings).
#[must_use]
pub fn schedule_to_cel_value(w: &ScheduleWindow, now: DateTime<Utc>, tol: TimeTolerance) -> Value {
    let active = w.is_active_at(now, tol);
    let (eff_lo, eff_hi) = w
        .effective_bounds(tol)
        .map(|(a, b)| (a.to_rfc3339(), b.to_rfc3339()))
        .unwrap_or_else(|| (String::new(), String::new()));
    let mut m: HashMap<&str, Value> = HashMap::new();
    m.insert("is_active", Value::Bool(active));
    m.insert("start", Value::String(w.start.to_rfc3339().into()));
    m.insert("end", Value::String(w.end.to_rfc3339().into()));
    m.insert("effective_start", Value::String(eff_lo.into()));
    m.insert("effective_end", Value::String(eff_hi.into()));
    m.insert("now", Value::String(now.to_rfc3339().into()));
    m.insert("tolerance_secs", Value::Int(tol.0.num_seconds()));
    Value::Map(m.into())
}

// --- Legacy helpers -----------------------------------------------------------

/// Add a signed day offset to `dt`, returning `None` on overflow.
pub fn add_days(dt: DateTime<Utc>, days: i64) -> Option<DateTime<Utc>> {
    dt.checked_add_signed(Duration::days(days))
}

/// Strict inclusive window (no tolerance).
#[must_use]
pub fn is_within(now: DateTime<Utc>, start: DateTime<Utc>, end: DateTime<Utc>) -> bool {
    now >= start && now <= end
}

/// Inclusive window with symmetric [`TimeTolerance`] on both bounds.
#[must_use]
pub fn is_active_simple(now: DateTime<Utc>, start: DateTime<Utc>, end: DateTime<Utc>, tol: TimeTolerance) -> bool {
    let Some(lo) = start.checked_sub_signed(tol.0) else {
        return false;
    };
    let Some(hi) = end.checked_add_signed(tol.0) else {
        return false;
    };
    now >= lo && now <= hi
}

#[cfg(test)]
mod tests {
    use super::*;
    use cel_interpreter::objects::Key;

    fn t(s: &str) -> DateTime<Utc> {
        DateTime::parse_from_rfc3339(s).unwrap().with_timezone(&Utc)
    }

    #[test]
    fn window_validate_rejects_inverted() {
        let w = ScheduleWindow {
            start: t("2026-06-01T00:00:00Z"),
            end: t("2026-05-01T00:00:00Z"),
            recurrence: None,
        };
        assert_eq!(w.validate(), Err(ScheduleError::InvalidPeriod));
    }

    #[test]
    fn tolerance_widens_window() {
        let start = t("2026-01-01T12:00:05Z");
        let end = t("2026-01-01T12:00:10Z");
        let tol = TimeTolerance::try_new(Duration::seconds(6)).unwrap();
        assert!(is_active_simple(t("2026-01-01T11:59:59Z"), start, end, tol));
        assert!(!is_within(t("2026-01-01T11:59:59Z"), start, end));
    }

    #[test]
    fn recurrence_weekday_and_band() {
        let w = ScheduleWindow {
            start: t("2026-01-01T00:00:00Z"),
            end: t("2026-12-31T23:59:59Z"),
            recurrence: Some(RecurrenceGate {
                weekday_mask: Some(1 << weekday_bit(Weekday::Wed)),
                utc_daytime: Some(UtcDaytimeBand { start_sec: 9 * 3600, end_sec: 17 * 3600 }),
                month_day: None,
            }),
        };
        w.validate().unwrap();
        // 2026-01-14 is Wednesday
        let now = t("2026-01-14T10:00:00Z");
        assert!(w.is_active_at(now, TimeTolerance::ZERO));
        let now_tue = t("2026-01-13T10:00:00Z");
        assert!(!w.is_active_at(now_tue, TimeTolerance::ZERO));
        let now_night = t("2026-01-14T20:00:00Z");
        assert!(!w.is_active_at(now_night, TimeTolerance::ZERO));
    }

    #[test]
    fn month_day_gate() {
        let w = ScheduleWindow {
            start: t("2026-01-01T00:00:00Z"),
            end: t("2026-12-31T23:59:59Z"),
            recurrence: Some(RecurrenceGate {
                weekday_mask: None,
                utc_daytime: None,
                month_day: Some(15),
            }),
        };
        assert!(w.is_active_at(t("2026-03-15T12:00:00Z"), TimeTolerance::ZERO));
        assert!(!w.is_active_at(t("2026-03-14T12:00:00Z"), TimeTolerance::ZERO));
    }

    #[test]
    fn schedule_cel_has_is_active() {
        let w = ScheduleWindow {
            start: t("2026-01-01T00:00:00Z"),
            end: t("2026-06-01T00:00:00Z"),
            recurrence: None,
        };
        let now = t("2026-03-01T00:00:00Z");
        let v = schedule_to_cel_value(&w, now, TimeTolerance::ZERO);
        match v {
            Value::Map(map) => {
                assert_eq!(map.get(&Key::from("is_active")), Some(&Value::Bool(true)));
            },
            _ => panic!("expected map"),
        }
    }

    #[test]
    fn serde_schedule_window_roundtrip() {
        let w = ScheduleWindow {
            start: t("2026-01-01T00:00:00Z"),
            end: t("2026-12-31T23:59:59Z"),
            recurrence: Some(RecurrenceGate {
                weekday_mask: Some(0b1111111),
                utc_daytime: None,
                month_day: None,
            }),
        };
        let j = serde_json::to_string(&w).unwrap();
        assert!(j.contains("2026"));
        let back: ScheduleWindow = serde_json::from_str(&j).unwrap();
        assert_eq!(back, w);
    }
}
