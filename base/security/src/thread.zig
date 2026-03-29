//! Thread supervision: spawn hooks, priority hints, deadlock watchdog stubs.
const std = @import("std");
const errors = @import("error.zig");

// [ ] — RICE_SECURITY_MAX_THREADS; runaway detection; affinity RICE_SECURITY_SAGE_CORES; prctl names

pub const Monitor = struct {
    name: []const u8 = "rice-security-thread",
};

/// Spawn a supervised worker (extend with signals / join policy).
pub fn spawnSupervised(comptime f: fn () void) errors.SecurityError!std.Thread {
    return std.Thread.spawn(.{}, f, .{}) catch return error.OutOfMemory;
}

/// Hint only — real policy needs OS scheduler APIs.
pub fn requestHighPriority() errors.SecurityError!void {
    return error.Unimplemented;
}

/// Placeholder deadlock detector (would sample thread stacks periodically).
pub fn deadlockWatchdogTick() void {}
