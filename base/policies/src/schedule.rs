//! Time-based scheduling — deadlines, contract windows, and simple recurrence.

use chrono::{DateTime, Duration, Utc};

// [ ] https://docs.rs/chrono/
// [ ] RICE_HOLIDAY_CALENDAR, RICE_SCHEDULE_TZ; recurring rules; deadlines RICE_GRACE_PERIOD_DAYS; RICE_BLACKOUT_WINDOWS

/// Add a signed day offset to `dt`, returning `None` on overflow.
pub fn add_days(dt: DateTime<Utc>, days: i64) -> Option<DateTime<Utc>> {
    dt.checked_add_signed(Duration::days(days))
}

/// Inclusive window check for contract-style periods.
pub fn is_within(now: DateTime<Utc>, start: DateTime<Utc>, end: DateTime<Utc>) -> bool {
    now >= start && now <= end
}
