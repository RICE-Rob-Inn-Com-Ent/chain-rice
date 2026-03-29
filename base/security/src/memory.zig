//! Memory isolation helpers: arenas, secure wipe, guard-page stubs.
const std = @import("std");
const errors = @import("error.zig");

// [ ] https://ziglang.org/documentation/master/std/ — mprotect, mlock, explicit_bzero, guard pages, RICE_SECURITY_ALLOC_THRESHOLD

/// Zero bytes (replace with platform secure_zero / libsodium in production).
pub fn secureWipe(bytes: []u8) void {
    @memset(bytes, 0);
}

/// Own an arena for short-lived security work (filters, audit batches). Caller must call `deinit`.
pub fn initArena(parent: std.mem.Allocator) std.heap.ArenaAllocator {
    return std.heap.ArenaAllocator.init(parent);
}

/// Placeholder: map a guard page below/above a region (requires mmap + mprotect).
pub fn guardPagePlaceholder() errors.SecurityError!void {
    return error.Unimplemented;
}
