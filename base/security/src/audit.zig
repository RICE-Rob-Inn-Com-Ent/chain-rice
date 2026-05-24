//! Structured security event log — stdout today; NATS publish behind `features.nats_audit`.
const std = @import("std");
const errors = @import("error.zig");
const Sha256 = std.crypto.hash.sha2.Sha256;

// [ ] — CLERK_SECURITY_AUDIT_LOG_PATH; rotate CLERK_SECURITY_LOG_MAX_BYTES; NATS msgpack; append-only persistence
// [ ] — remote witness / notary; dual-write to WORM storage

/// Tip of the tamper-evident chain (SHA-256 over `prev || canonical_record`). Starts at zero.
pub var chain_tip: [32]u8 = [_]u8{0} ** 32;

pub const Event = struct {
    ts: i64,
    kind: []const u8,
    detail: []const u8,
};

pub fn log(writer: anytype, event: Event) errors.SecurityError!void {
    std.fmt.format(writer, "[{d}] {s}: {s}\n", .{ event.ts, event.kind, event.detail }) catch return error.AuditError;
}

fn fmtSha256Hex(hash: [32]u8, out: *[64]u8) void {
    const hex = "0123456789abcdef";
    for (hash, 0..) |b, i| {
        out[i * 2] = hex[b >> 4];
        out[i * 2 + 1] = hex[b & 15];
    }
}

/// Self-reporting cryptographic proof for every autonomous defensive act (kill, wipe, block, suspend).
/// Extends `chain_tip`; suitable as tamper-evident evidence without human sign-off.
pub fn recordDefensive(writer: anytype, kind: []const u8, detail: []const u8) errors.SecurityError!void {
    const ts: i64 = @intCast(@divTrunc(std.time.nanoTimestamp(), 1_000_000));

    var canon: [384]u8 = undefined;
    const canon_slice = std.fmt.bufPrint(&canon, "{s}|{d}|{s}", .{ kind, ts, detail }) catch return error.AuditError;

    var digest: [32]u8 = undefined;
    var h = Sha256.init(.{});
    h.update(&chain_tip);
    h.update(canon_slice);
    h.final(&digest);
    chain_tip = digest;

    var hex_buf: [64]u8 = undefined;
    fmtSha256Hex(digest, &hex_buf);

    std.fmt.format(writer, "[{d}] defensive:{s}: {s}\nproof_sha256: {s}\n", .{
        ts, kind, detail, hex_buf,
    }) catch return error.AuditError;
}

/// Autonomous witness path (no manual approval queue) — NATS / WORM mirror when wired.
pub fn publishNats(_: []const u8) errors.SecurityError!void {
    return error.Unimplemented;
}

/// Sovereign audit loop: log a stress phase (every chaos / penetration step should call this).
pub fn logStress(writer: anytype, phase: []const u8, detail: []const u8) errors.SecurityError!void {
    const ts: i64 = @intCast(@divTrunc(std.time.nanoTimestamp(), 1_000_000));
    try log(writer, .{ .ts = ts, .kind = "stress", .detail = phase });
    try std.fmt.format(writer, "  stress_detail: {s}\n", .{detail});
}

/// Human-readable liability block when a stressor detects failure or invariant breach (before exit).
pub fn liabilityReport(writer: anytype, failure: []const u8, last_phase: []const u8) errors.SecurityError!void {
    const ts: i64 = @intCast(@divTrunc(std.time.nanoTimestamp(), 1_000_000));
    try log(writer, .{ .ts = ts, .kind = "liability", .detail = "report_begin" });
    try std.fmt.format(writer,
        \\=== CLERK SOVEREIGN LIABILITY REPORT ===
        \\timestamp_ms: {d}
        \\last_phase: {s}
        \\failure: {s}
        \\action: autonomous_isolate_and_prune — no human gate; evidence chain below
        \\=== END LIABILITY REPORT ===
        \\
    , .{ ts, last_phase, failure });
    try recordDefensive(writer, "liability_autonomous", last_phase);
}

test "defensive record extends hash chain" {
    const saved = chain_tip;
    defer chain_tip = saved;

    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    chain_tip = [_]u8{0} ** 32;
    const tip0 = chain_tip;
    try recordDefensive(list.writer(), "wipe", "buffer_a");
    try std.testing.expect(!std.mem.eql(u8, &chain_tip, &tip0));
    try std.testing.expect(std.mem.indexOf(u8, list.items, "proof_sha256:") != null);
}
