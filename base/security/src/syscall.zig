//! Seccomp-oriented syscall policy (link with libseccomp; wire real filters in production).
const std = @import("std");
const errors = @import("error.zig");

// [ ] — ptrace dev; seccomp prod; RICE_SECURITY_ALLOWED_PATHS/HOSTS; NATS security.syscall.*

/// Minimal allowlist sketch: production uses seccomp_rule_add / seccomp_load.
pub const FilterMode = enum {
    /// Block everything not explicitly allowed.
    restrictive,
    /// Allow common libc + networking, block dangerous syscalls.
    permissive,
};

pub fn applyFilter(mode: FilterMode) errors.SecurityError!void {
    _ = mode;
    // seccomp_init / seccomp_rule_add / seccomp_load would go here.
    return error.Unimplemented;
}

/// Emit an audit line when the kernel would kill the process (userspace simulation hook).
pub fn onViolationLog(writer: anytype, syscall_nr: i32) !void {
    try std.fmt.format(writer, "seccomp: blocked syscall {}\n", .{syscall_nr});
}
