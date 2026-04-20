//! Security-wide error sets, tracing hooks, and optional panic routing.
const std = @import("std");

// [ ] — full SecurityError surface; stderr + NATS security.errors; fatal vs continue policy

/// Errors returned by sandboxing, syscall filtering, capture, and audit paths.
pub const SecurityError = error{
    OutOfMemory,
    PermissionDenied,
    UnsupportedPlatform,
    SyscallFiltered,
    PcapError,
    SeccompError,
    EbpfError,
    IsolateError,
    AuditError,
    ChaosInvariantFailed,
    Unimplemented,
};

/// Optional user hook: called before process exit on panic.
pub var on_panic: ?*const fn (msg: []const u8) void = null;

/// Custom panic handler — register with `std.debug.setPanicHandler(panicHook)` once at startup (API varies by Zig std version).
pub fn panicHook(msg: []const u8, stack_trace: ?*std.builtin.StackTrace, ret_addr: ?usize) noreturn {
    _ = stack_trace;
    _ = ret_addr;
    if (on_panic) |hook| hook(msg);
    std.debug.print("rice-security panic: {s}\n", .{msg});
    std.process.exit(1);
}
