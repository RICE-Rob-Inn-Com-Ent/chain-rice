//! Warden: C-ABI surface for Rust CLERK + memory “scalpel” (volatile secure wipe, arenas, guard stubs).
//! Called from `util` around Haskell CALC FFI when the `zig-warden` feature is enabled.
const std = @import("std");
const errors = @import("error.zig");

// [ ] https://ziglang.org/documentation/master/std/ — mprotect, mlock, explicit_bzero, guard pages, RICE_SECURITY_ALLOC_THRESHOLD
// [ ] — platform secure_zero / libsodium; RICE_SECURITY_* caps in CI

/// Zero sensitive bytes with per-store `volatile` stores (compiler must not elide).
pub fn secureWipeVolatile(bytes: []u8) void {
    for (bytes) |*byte| {
        const p: *volatile u8 = @ptrCast(byte);
        p.* = 0;
    }
    std.atomic.fence(.seq_cst);
}

/// Zig API: same semantics as legacy `memory.secureWipe` (now volatile-backed).
pub fn secureWipe(bytes: []u8) void {
    secureWipeVolatile(bytes);
}

/// Own an arena for short-lived security work (filters, audit batches). Caller must call `deinit`.
pub fn initArena(parent: std.mem.Allocator) std.heap.ArenaAllocator {
    return std.heap.ArenaAllocator.init(parent);
}

/// Placeholder: map a guard page below/above a region (requires mmap + mprotect).
pub fn guardPagePlaceholder() errors.SecurityError!void {
    return error.Unimplemented;
}

/// Reject oversize principal or out-of-range basis points (mirrors CALC Haskell bounds).
/// Returns `0` if ok; `1` if `principal_len > max_principal_len`; `2` if `bps` outside `[0, max_bps]`.
export fn rice_warden_check_leverage_limit(
    principal_len: usize,
    max_principal_len: usize,
    bps: i64,
    max_bps: i64,
) i32 {
    if (principal_len > max_principal_len) return 1;
    if (bps < 0 or bps > max_bps) return 2;
    return 0;
}

fn wipeOpaque(ptr: ?*anyopaque, len: usize) void {
    if (len == 0) return;
    const raw = ptr orelse return;
    const bytes: [*]u8 = @ptrCast(@alignCast(raw));
    secureWipeVolatile(bytes[0..len]);
}

/// Zero `len` bytes at `ptr` (no-op if `ptr` is null or `len == 0`). Caller must own the memory.
/// **Rust CLERK:** stable `export fn` symbol — keep name and ABI.
export fn rice_warden_prune_memory_remnants(ptr: ?*anyopaque, len: usize) void {
    wipeOpaque(ptr, len);
}

/// Explicit volatile secure wipe for C/Rust callers (same effect as `rice_warden_prune_memory_remnants`).
/// **Rust CLERK:** stable `export fn` symbol.
export fn rice_warden_secure_wipe(ptr: ?*anyopaque, len: usize) void {
    wipeOpaque(ptr, len);
}

test "warden rejects oversized principal" {
    try std.testing.expectEqual(@as(i32, 1), rice_warden_check_leverage_limit(5000, 4096, 100, 1_000_000));
}

test "warden rejects negative bps" {
    try std.testing.expectEqual(@as(i32, 2), rice_warden_check_leverage_limit(10, 4096, -1, 1_000_000));
}

test "warden accepts in-range input" {
    try std.testing.expectEqual(@as(i32, 0), rice_warden_check_leverage_limit(10, 4096, 250, 1_000_000));
}

test "warden prune zeroes buffer" {
    var buf: [16]u8 = undefined;
    @memset(&buf, 0xAB);
    rice_warden_prune_memory_remnants(@ptrCast(@alignCast(buf[0..].ptr)), buf.len);
    try std.testing.expectEqual(@as(u8, 0), buf[0]);
}

test "secure wipe volatile zeroes memory" {
    var buf: [32]u8 = undefined;
    @memset(&buf, 0xAA);
    secureWipeVolatile(&buf);
    try std.testing.expect(buf[0] == 0);
}

test "secureWipe api matches legacy memory module" {
    var buf: [8]u8 = undefined;
    @memset(&buf, 0xFF);
    secureWipe(&buf);
    try std.testing.expect(buf[0] == 0);
}
