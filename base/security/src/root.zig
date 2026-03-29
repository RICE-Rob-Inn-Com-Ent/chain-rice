//! Rice security — near-metal defense library root: re-exports and compile-time feature flags.
const std = @import("std");

// [ ] https://ziglang.org/documentation/master/std/
// [ ] pub exports monitor..audit; main daemon RICE_SECURITY_*; NATS; graceful shutdown SIGTERM/SIGINT

pub const errors = @import("error.zig");
pub const memory = @import("memory.zig");
pub const thread = @import("thread.zig");
pub const process = @import("process.zig");
pub const syscall = @import("syscall.zig");
pub const network = @import("network.zig");
pub const filter = @import("filter.zig");
pub const probe = @import("probe.zig");
pub const monitor = @import("monitor.zig");
pub const isolate = @import("isolate.zig");
pub const audit = @import("audit.zig");

/// Enable heavy / platform-specific subsystems at compile time.
pub const features = struct {
    pub const pcap: bool = true;
    pub const seccomp: bool = true;
    pub const ebpf: bool = false;
    pub const nats_audit: bool = false;
};

test "secure wipe zeroes memory" {
    var buf: [32]u8 = undefined;
    @memset(&buf, 0xAA);
    memory.secureWipe(&buf);
    try std.testing.expect(buf[0] == 0);
}

test "isolate.apply returns Unimplemented until wired" {
    try std.testing.expectError(error.Unimplemented, isolate.apply(.{}));
}
