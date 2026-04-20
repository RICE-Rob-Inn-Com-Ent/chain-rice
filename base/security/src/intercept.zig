//! Intercept: libpcap capture, BPF filter compilation, eBPF probes, and runtime monitoring (audit stream tie-in).
const std = @import("std");
const errors = @import("error.zig");
const audit = @import("audit.zig");
const os_mod = @import("os.zig");

// [ ] — libpcap RICE_SECURITY_MONITOR_IFACE; rate limit; zig-network abstraction; NATS security.network.*
// [ ] — pcap_compile BPF; RICE_SECURITY_BPF_FILTER; role-specific allowlists; violation NATS
// [ ] — RICE_SECURITY_EBPF_PROG; perf buffer; kprobe/uprobe; NATS security.probe.*
// [ ] — poll RICE_SECURITY_POLL_MS; CPU/mem/fd thresholds; inotify/kqueue; NATS security.monitor.*
// [ ] — inotify/fsnotify encryption velocity; SIGSTOP via pidfd; NATS security.ransom.*
// [ ] — XDP/BPF tc hook for per-agent hash; QUIC-aware token bucket; NATS security.ddos.*

// ── Anti-ransomware watchdog (high-frequency encrypt under `base/`) ───────

pub const SigPolicy = enum { observe, sigstop_target };

pub const RansomWatchConfig = struct {
    base_prefix: []const u8 = "base/",
    max_encrypt_events_per_window: u32 = 8,
    window_ms: i64 = 1000,
};

/// Sliding-window counter of encrypt-style events; production would SIGSTOP hot processes.
pub const RansomWatch = struct {
    times_ms: [32]i64 = undefined,
    count: usize = 0,

    pub fn onEncryptFileEvent(
        self: *RansomWatch,
        writer: anytype,
        now_ms: i64,
        path: []const u8,
        cfg: RansomWatchConfig,
    ) errors.SecurityError!SigPolicy {
        if (!std.mem.startsWith(u8, path, cfg.base_prefix)) return .observe;

        if (self.count < self.times_ms.len) {
            self.times_ms[self.count] = now_ms;
            self.count += 1;
        } else {
            std.mem.copyForwards(i64, self.times_ms[0 .. self.times_ms.len - 1], self.times_ms[1..]);
            self.times_ms[self.times_ms.len - 1] = now_ms;
        }

        var in_window: u32 = 0;
        for (self.times_ms[0..self.count]) |t| {
            if (now_ms - t <= cfg.window_ms) in_window += 1;
        }

        try audit.log(writer, .{
            .ts = now_ms,
            .kind = "ransom_watch",
            .detail = "encrypt_event",
        });

        if (in_window > cfg.max_encrypt_events_per_window) return .sigstop_target;
        return .observe;
    }
};

/// Autonomous escalation: suspend CLERK hot path + cryptographic audit (SIGSTOP to `pid` when wired).
pub fn applySigstopForRansom(policy: SigPolicy, pid: std.posix.pid_t) errors.SecurityError!void {
    if (policy != .sigstop_target) return;
    os_mod.Thread.suspendHotPath();
    var stack: [512]u8 align(8) = undefined;
    var fba = std.heap.fixedBufferAllocator(&stack);
    var pr = std.ArrayList(u8).init(fba.allocator());
    defer pr.deinit();
    try audit.recordDefensive(pr.writer(), "ransom_sigstop", "autonomous_hot_path_suspend");
    var off: usize = 0;
    while (off < pr.items.len) {
        const n = std.posix.write(2, pr.items[off..]) catch break;
        if (n == 0) break;
        off += n;
    }
    _ = pid;
}

// ── BPF / filter (legacy `filter.zig`) ──────────────────────────────────────

const filter_ns = struct {
    pub const BpfProgramImpl = struct {
        expression: []const u8,
    };

    pub fn init(expression: []const u8) BpfProgramImpl {
        return .{ .expression = expression };
    }

    /// Placeholder: would call `pcap_compile` / attach to capture handle.
    pub fn compile(_: BpfProgramImpl) errors.SecurityError!void {
        return error.Unimplemented;
    }

    /// Placeholder protocol tag for dissection helpers.
    pub fn summarizeTcpLike(_: []const u8) []const u8 {
        return "unimplemented";
    }
};
pub const filter = filter_ns;
pub const BpfProgram = filter_ns.BpfProgramImpl;

// ── eBPF probe (legacy `probe.zig`) ─────────────────────────────────────────

const probe_ns = struct {
    pub const ProbeIdImpl = u32;

    pub fn loadProgram(_: []const u8) errors.SecurityError!ProbeIdImpl {
        return error.Unimplemented;
    }

    pub fn attachKprobe(_: ProbeIdImpl, _: []const u8) errors.SecurityError!void {
        return error.Unimplemented;
    }

    pub fn readMapU64(_: ProbeIdImpl, _: u32) errors.SecurityError!u64 {
        return error.Unimplemented;
    }
};
pub const probe = probe_ns;
pub const ProbeId = probe_ns.ProbeIdImpl;

// ── Packet capture (legacy `network.zig`) ───────────────────────────────────

pub const CaptureHandle = struct {
    device: [:0]const u8 = "any",
    bpf: ?BpfProgram = null,
};

pub fn openLive(device: [:0]const u8) errors.SecurityError!CaptureHandle {
    _ = device;
    return error.Unimplemented;
}

/// Very small anomaly score placeholder (bytes/sec variance would live here).
pub fn scoreAnomaly(_: usize, _: usize) f32 {
    return 0;
}

// ── Anti-DDoS: sovereign rate limit (userspace stub → BPF string for kernel drop) ─

pub const AgentRateLimiterConfig = struct {
    sovereign_packets_per_sec: u32 = 100,
    refill_interval_ms: i64 = 100,
};

pub const AgentRateLimiter = struct {
    tokens: i64,
    last_refill_ms: i64,

    pub fn init() AgentRateLimiter {
        return .{ .tokens = 100, .last_refill_ms = 0 };
    }

    /// Returns `true` if the packet should be dropped at capture/BPF boundary.
    pub fn shouldDrop(self: *AgentRateLimiter, cfg: AgentRateLimiterConfig, now_ms: i64, agent_hash: u64) bool {
        _ = agent_hash;
        if (self.last_refill_ms == 0) self.last_refill_ms = now_ms;
        if (now_ms - self.last_refill_ms >= cfg.refill_interval_ms) {
            self.tokens = @intCast(cfg.sovereign_packets_per_sec);
            self.last_refill_ms = now_ms;
        }
        if (self.tokens <= 0) return true;
        self.tokens -= 1;
        return false;
    }

    /// Placeholder BPF for `pcap_compile` / XDP — drop when a single agent exceeds sovereign QPS.
    pub fn bpfDropRuleExpression(cfg: AgentRateLimiterConfig) []const u8 {
        _ = cfg;
        return "(placeholder) per-agent throttle — compile with pcap/XDP in prod";
    }
};

// ── Adaptive pressure (algorithmic “DDoS” on CLERK transaction path) ─────────
// Uses elapsed **nanoseconds per transaction** as a portable proxy for CPU-cycle pressure
// (wire `perf` / `rdtsc` in platform layer for exact cycles).

pub const PressureGaugeConfig = struct {
    /// Treat as attack if current txn cost exceeds baseline by this factor (e.g. 100×).
    spike_multiplier: u64 = 100,
    /// Transactions used to learn baseline before enforcement.
    baseline_warmup_txns: u32 = 4,
};

pub const PressureReaction = enum {
    normal,
    /// Hot path suspended — CLERK must gate FFI until `Thread.resumeHotPath`.
    suspended,
};

pub const PressureGauge = struct {
    ema_ns: u64 = 0,
    warmup_left: u32 = 0,

    pub fn init(cfg: PressureGaugeConfig) PressureGauge {
        return .{ .ema_ns = 0, .warmup_left = cfg.baseline_warmup_txns };
    }

    pub fn onTxnDurationNs(
        self: *PressureGauge,
        cfg: PressureGaugeConfig,
        writer: anytype,
        duration_ns: u64,
    ) errors.SecurityError!PressureReaction {
        if (cfg.baseline_warmup_txns == 0) {
            if (self.ema_ns == 0) {
                self.ema_ns = @max(1, duration_ns);
                return .normal;
            }
        } else if (self.warmup_left > 0) {
            if (self.ema_ns == 0) {
                self.ema_ns = duration_ns;
            } else {
                self.ema_ns = (self.ema_ns * 7 + duration_ns) / 8;
            }
            self.warmup_left -= 1;
            return .normal;
        }
        const threshold = self.ema_ns *| cfg.spike_multiplier;
        if (duration_ns > threshold) {
            os_mod.Thread.suspendHotPath();
            try audit.recordDefensive(writer, "pressure_gauge", "algorithmic_txn_spike_suspend");
            return .suspended;
        }
        self.ema_ns = (self.ema_ns * 7 + duration_ns) / 8;
        return .normal;
    }
};

const CaptureHandle_Type = CaptureHandle;
const open_live_fn = openLive;
const score_anomaly_fn = scoreAnomaly;
const AgentRateLimiter_Type = AgentRateLimiter;
const AgentRateLimiterConfig_Type = AgentRateLimiterConfig;
const PressureGauge_Type = PressureGauge;
const PressureGaugeConfig_Type = PressureGaugeConfig;
const PressureReaction_Type = PressureReaction;

const network_ns = struct {
    pub const CaptureHandle = CaptureHandle_Type;
    pub const openLive = open_live_fn;
    pub const scoreAnomaly = score_anomaly_fn;
    pub const filter = filter_ns;
    pub const AgentRateLimiter = AgentRateLimiter_Type;
    pub const AgentRateLimiterConfig = AgentRateLimiterConfig_Type;
    pub const PressureGauge = PressureGauge_Type;
    pub const PressureGaugeConfig = PressureGaugeConfig_Type;
    pub const PressureReaction = PressureReaction_Type;
};
pub const network = network_ns;

// ── Runtime monitor (legacy `monitor.zig`) ───────────────────────────────────

const monitor_ns = struct {
    pub const Config = struct {
        enable_ebpf: bool = false,
    };

    pub fn tick(writer: anytype, cfg: Config) errors.SecurityError!void {
        _ = cfg;
        if (probe_ns.loadProgram("placeholder")) |_| {
            // would read counters
        } else |_| {}
        const now: i64 = @intCast(@divTrunc(std.time.nanoTimestamp(), 1_000_000));
        try audit.log(writer, .{
            .ts = now,
            .kind = "monitor",
            .detail = "tick",
        });
    }
};
pub const monitor = monitor_ns;

test "monitor tick writes audit line" {
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    try monitor.tick(list.writer(), .{});
    try std.testing.expect(std.mem.indexOf(u8, list.items, "monitor") != null);
}

test "ransom watch escalates on burst encrypt under base/" {
    var rw: RansomWatch = .{};
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    const w = list.writer();
    const cfg = RansomWatchConfig{
        .base_prefix = "base/",
        .max_encrypt_events_per_window = 2,
        .window_ms = 60_000,
    };
    var last: SigPolicy = .observe;
    var i: i64 = 0;
    while (i < 10) : (i += 1) {
        last = try rw.onEncryptFileEvent(w, 1_000_000 + i, "base/victim.bin", cfg);
        if (last == .sigstop_target) break;
    }
    try std.testing.expect(last == .sigstop_target);
}

test "pressure gauge suspends on 100x spike after warmup" {
    const saved_tip = audit.chain_tip;
    defer audit.chain_tip = saved_tip;

    os_mod.Thread.resumeHotPath();
    var g = PressureGauge.init(.{ .spike_multiplier = 100, .baseline_warmup_txns = 2 });
    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    const w = list.writer();
    _ = try g.onTxnDurationNs(.{ .spike_multiplier = 100, .baseline_warmup_txns = 2 }, w, 100);
    _ = try g.onTxnDurationNs(.{ .spike_multiplier = 100, .baseline_warmup_txns = 2 }, w, 100);
    const r = try g.onTxnDurationNs(.{ .spike_multiplier = 100, .baseline_warmup_txns = 2 }, w, 100 * 100 + 50);
    try std.testing.expect(r == .suspended);
    try std.testing.expect(os_mod.Thread.hotPathSuspended());
    os_mod.Thread.resumeHotPath();
}

test "agent rate limiter drops after token exhaustion" {
    var lim = AgentRateLimiter{ .tokens = 2, .last_refill_ms = 1 };
    const cfg = AgentRateLimiterConfig{
        .sovereign_packets_per_sec = 2,
        .refill_interval_ms = 10_000,
    };
    const t: i64 = 10_000;
    try std.testing.expect(!lim.shouldDrop(cfg, t, 1));
    try std.testing.expect(!lim.shouldDrop(cfg, t, 1));
    try std.testing.expect(lim.shouldDrop(cfg, t, 1));
}
