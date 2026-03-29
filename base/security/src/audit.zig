//! Structured security event log — stdout today; NATS publish behind `features.nats_audit`.
const std = @import("std");
const errors = @import("error.zig");

// [ ] — RICE_SECURITY_AUDIT_LOG_PATH; rotate RICE_SECURITY_LOG_MAX_BYTES; NATS msgpack; hash chain tamper-evidence

pub const Event = struct {
    ts: i64,
    kind: []const u8,
    detail: []const u8,
};

pub fn log(writer: anytype, event: Event) errors.SecurityError!void {
    std.fmt.format(writer, "[{d}] {s}: {s}\n", .{ event.ts, event.kind, event.detail }) catch return error.AuditError;
}

/// Future: publish JSON to NATS `security.audit` subject.
pub fn publishNats(_: []const u8) errors.SecurityError!void {
    return error.Unimplemented;
}
