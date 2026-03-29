//! BPF filter strings for libpcap — compile/match stubs until wired to `pcap_compile`.
const std = @import("std");
const errors = @import("error.zig");

// [ ] — pcap_compile BPF; RICE_SECURITY_BPF_FILTER; role-specific allowlists; violation NATS

pub const BpfProgram = struct {
    expression: []const u8,
};

pub fn init(expression: []const u8) BpfProgram {
    return .{ .expression = expression };
}

/// Placeholder: would call `pcap_compile` / attach to capture handle.
pub fn compile(_: BpfProgram) errors.SecurityError!void {
    return error.Unimplemented;
}

/// Placeholder protocol tag for dissection helpers.
pub fn summarizeTcpLike(_: []const u8) []const u8 {
    return "unimplemented";
}
