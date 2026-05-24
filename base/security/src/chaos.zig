//! Sovereign stressor & auto-penetration harness — hunts weak spots in Rust/Haskell/FFI before production.
const std = @import("std");
const errors = @import("error.zig");
const audit = @import("audit.zig");
const warden = @import("warden.zig");
const intercept = @import("intercept.zig");
const os_mod = @import("os.zig");

// [ ] — CLERK_CHAOS_RLIMIT_AS / setrlimit simulation; multi-process fault injection; CALC binary corpus
// [ ] — hook real Haskell CALC entry; record reproducer blobs to NATS security.chaos.*

// ── Memory pressure (fragmentation / soft ceiling; RLIMIT_AS wiring later) ─

pub const MemoryPressureConfig = struct {
    max_blocks: usize = 24,
    block_size: usize = 256,
};

/// Intentionally interleave alloc/free to stress allocator bookkeeping (bounded; safe in CI).
pub fn stressMemoryFragmentation(alloc: std.mem.Allocator, cfg: MemoryPressureConfig) errors.SecurityError!void {
    var slots = try alloc.alloc(?[]u8, cfg.max_blocks);
    defer {
        for (slots) |s| {
            if (s) |b| alloc.free(b);
        }
        alloc.free(slots);
    }
    @memset(slots, null);

    for (0..cfg.max_blocks) |i| {
        const b = try alloc.alloc(u8, cfg.block_size);
        @memset(b, @truncate(i));
        slots[i] = b;
    }
    var i: usize = 1;
    while (i < cfg.max_blocks) : (i += 2) {
        if (slots[i]) |b| {
            alloc.free(b);
            slots[i] = null;
        }
    }
    for (0..cfg.max_blocks) |j| {
        if (slots[j] == null and j % 2 == 1) {
            slots[j] = try alloc.alloc(u8, cfg.block_size / 2);
        }
    }
}

/// Placeholder for `RLIMIT_AS` / cgroup memory pressure (returns `Unimplemented` until wired).
pub fn stressRlimitAddressSpace() errors.SecurityError!void {
    return error.Unimplemented;
}

// ── Instruction / payload fuzzing (Warden + CALC-shaped bounds) ─────────────

/// Feed oversized principal length and edge `bps` through the same checks Rust/Haskell use pre-CALC.
pub fn fuzzCalcPayloadAgainstWarden(
    payload_len: usize,
    max_principal_len: usize,
    bps: i64,
    max_bps: i64,
) i32 {
    return warden.warden_check_leverage_limit(payload_len, max_principal_len, bps, max_bps);
}

// ── Latency injection (timing / race probes on FFI boundaries) ──────────────

/// Artificial delay on the FFI bridge path (nanoseconds). Use small values in CI.
pub fn injectBridgeLatencyNs(ns: u64) void {
    if (ns == 0) return;
    std.Thread.sleep(ns);
}

// ── Sovereign suite (audit every phase; invariant failures → `ChaosInvariantFailed`) ─

pub fn runSovereignStress(writer: anytype) errors.SecurityError!void {
    os_mod.Thread.resumeHotPath();
    try audit.logStress(writer, "sovereign_suite_start", "chaos engine armed");

    const over = fuzzCalcPayloadAgainstWarden(999_999, 4096, 0, 1_000_000);
    if (over != 1) return error.ChaosInvariantFailed;
    try audit.logStress(writer, "fuzz_warden_oversize", "warden rejected oversized principal (expected)");

    const bad_bps = fuzzCalcPayloadAgainstWarden(10, 4096, -1, 1_000_000);
    if (bad_bps != 2) return error.ChaosInvariantFailed;
    try audit.logStress(writer, "fuzz_warden_bad_bps", "warden rejected negative bps (expected)");

    injectBridgeLatencyNs(50_000);
    try audit.logStress(writer, "latency_injection", "50us synthetic FFI delay applied");

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    try stressMemoryFragmentation(gpa.allocator(), .{});
    try audit.logStress(writer, "memory_fragmentation", "bounded fragmentation cycle completed");

    var rw: intercept.RansomWatch = .{};
    const now_ms: i64 = @intCast(@divTrunc(std.time.nanoTimestamp(), 1_000_000));
    _ = try rw.onEncryptFileEvent(writer, now_ms, "base/foo.enc", .{});
    try audit.logStress(writer, "ransom_watch", "single encrypt under base/ observed");

    var lim = intercept.AgentRateLimiter.init();
    _ = lim.shouldDrop(.{ .sovereign_packets_per_sec = 100, .refill_interval_ms = 100 }, now_ms, 0xdeadbeef);
    try audit.logStress(writer, "anti_ddos", "rate limiter tick (stub)");

    const reaper = os_mod.Reaper{ .policy = .{ .whitelist_exec_basenames = &.{ "zig", "rustc" } } };
    try reaper.tickAndAudit(writer);
    if (!reaper.shouldReap("random-malware")) return error.ChaosInvariantFailed;
    if (reaper.shouldReap("zig")) return error.ChaosInvariantFailed;
    try audit.logStress(writer, "reaper_policy", "non-whitelisted exe flagged for reap");

    try audit.logStress(writer, "sovereign_suite_complete", "no invariant breaches");
    os_mod.Thread.resumeHotPath();
}

fn writeStderrAll(bytes: []const u8) void {
    var off: usize = 0;
    while (off < bytes.len) {
        const n = std.posix.write(2, bytes[off..]) catch return;
        if (n == 0) return;
        off += n;
    }
}

/// **Rust CLERK / CI:** run the full sovereign stress suite; writes audit trail to stderr. Returns `0` on success.
export fn security_stress_test() i32 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var log_buf = std.ArrayList(u8).init(alloc);
    defer log_buf.deinit();
    const w = log_buf.writer();

    runSovereignStress(w) catch |err| {
        audit.liabilityReport(w, @errorName(err), "sovereign_suite") catch {};
        writeStderrAll(log_buf.items);
        os_mod.Thread.resumeHotPath();
        return 1;
    };
    writeStderrAll(log_buf.items);
    return 0;
}

test "chaos warden fuzz rejects oversize" {
    try std.testing.expectEqual(@as(i32, 1), fuzzCalcPayloadAgainstWarden(10_000, 4096, 0, 1_000_000));
}

test "chaos sovereign suite invariants" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try runSovereignStress(list.writer());
    try std.testing.expect(std.mem.indexOf(u8, list.items, "sovereign_suite_complete") != null);
}

test "security_stress_test export returns success" {
    try std.testing.expectEqual(@as(i32, 0), security_stress_test());
}
