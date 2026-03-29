//! eBPF program loading — requires libbpf / kernel BTF; stubs until linked.
const std = @import("std");
const errors = @import("error.zig");

// [ ] — RICE_SECURITY_EBPF_PROG; perf buffer; kprobe/uprobe; NATS security.probe.*

pub const ProbeId = u32;

pub fn loadProgram(_: []const u8) errors.SecurityError!ProbeId {
    return error.Unimplemented;
}

pub fn attachKprobe(_: ProbeId, _: []const u8) errors.SecurityError!void {
    return error.Unimplemented;
}

pub fn readMapU64(_: ProbeId, _: u32) errors.SecurityError!u64 {
    return error.Unimplemented;
}
