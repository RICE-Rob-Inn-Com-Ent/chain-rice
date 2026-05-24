//! Clerk security — near-metal defense library root: re-exports and compile-time feature flags.

// [ ] https://ziglang.org/documentation/master/std/
// [ ] pub exports monitor..audit; main daemon CLERK_SECURITY_*; NATS; graceful shutdown SIGTERM/SIGINT

pub const errors = @import("error.zig");
pub const warden = @import("warden.zig");
pub const os = @import("os.zig");
pub const intercept = @import("intercept.zig");
pub const audit = @import("audit.zig");
pub const chaos = @import("chaos.zig");

/// Behavioral syscall policy (re-export for embedders).
pub const SovereignPolicy = os.SovereignPolicy;
pub const SovereignAction = os.SovereignAction;
pub const SovereignModule = os.Module;

/// Same symbols as legacy `memory.zig` (volatile wipe now lives in `warden`).
pub const memory = warden;

/// Legacy flat module paths — unchanged for `.rice` / downstream imports.
pub const thread = os.thread;
pub const process = os.process;
pub const syscall = os.syscall;
pub const isolate = os.isolate;
pub const network = intercept.network;
pub const filter = intercept.filter;
pub const probe = intercept.probe;
pub const monitor = intercept.monitor;

/// Enable heavy / platform-specific subsystems at compile time.
pub const features = struct {
    pub const pcap: bool = true;
    pub const seccomp: bool = true;
    pub const ebpf: bool = false;
    pub const nats_audit: bool = false;
};
