//! Runtime monitor — ties eBPF probes (optional) to audit stream.
const std = @import("std");
const errors = @import("error.zig");
const audit = @import("audit.zig");
const probe = @import("probe.zig");

// [ ] — poll RICE_SECURITY_POLL_MS; CPU/mem/fd thresholds; inotify/kqueue; NATS security.monitor.*

pub const Config = struct {
    enable_ebpf: bool = false,
};

pub fn tick(writer: anytype, cfg: Config) errors.SecurityError!void {
    _ = cfg;
    if (probe.loadProgram("placeholder")) |_| {
        // would read counters
    } else |_| {}
    const now: i64 = @intCast(@divTrunc(std.time.nanoTimestamp(), 1_000_000));
    try audit.log(writer, .{
        .ts = now,
        .kind = "monitor",
        .detail = "tick",
    });
}
