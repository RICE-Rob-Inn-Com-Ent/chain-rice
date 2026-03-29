//! Packet capture and light traffic metrics — libpcap-backed when `features.pcap` is enabled.
const std = @import("std");
const errors = @import("error.zig");
const filter_mod = @import("filter.zig");

// [ ] — libpcap RICE_SECURITY_MONITOR_IFACE; rate limit; zig-network abstraction; NATS security.network.*

pub const CaptureHandle = struct {
    device: [:0]const u8 = "any",
    bpf: ?filter_mod.BpfProgram = null,
};

pub fn openLive(device: [:0]const u8) errors.SecurityError!CaptureHandle {
    _ = device;
    return error.Unimplemented;
}

/// Very small anomaly score placeholder (bytes/sec variance would live here).
pub fn scoreAnomaly(_: usize, _: usize) f32 {
    return 0;
}

pub const filter = filter_mod;
