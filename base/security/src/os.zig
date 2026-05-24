//! OS abstraction: syscalls, process boundaries, sandbox glue, thread supervision.
const std = @import("std");
const builtin = @import("builtin");
const errors = @import("error.zig");
const audit = @import("audit.zig");

// [ ] — ptrace dev; seccomp prod; CLERK_SECURITY_ALLOWED_PATHS/HOSTS; NATS security.syscall.*
// [ ] — /proc tree; CLERK_SECURITY_PROC_WHITELIST; kill CLERK_SECURITY_KILL_ENABLED; ancestry NATS audit.clerk.kills
// [ ] — namespaces clone/setrlimit CLERK_SECURITY_*; chroot CLERK_SECURITY_JAIL_PATH; capability drop
// [ ] — CLERK_SECURITY_MAX_THREADS; runaway detection; affinity CLERK_SECURITY_SAGE_CORES; prctl names
// [ ] — /proc + policy sync; SIGKILL vs SIGTERM; NATS security.reaper.*

// ── Process reaper (non-whitelisted children vs .rice policy) ───────────────

pub const Reaper = struct {
    pub const Policy = struct {
        /// Executable basenames allowed to survive (extend from `.rice` policy file).
        whitelist_exec_basenames: []const []const u8 = &.{},
    };

    policy: Policy = .{},

    pub fn isWhitelisted(self: Reaper, exe_basename: []const u8) bool {
        for (self.policy.whitelist_exec_basenames) |w| {
            if (std.mem.eql(u8, exe_basename, w)) return true;
        }
        return false;
    }

    pub fn shouldReap(self: Reaper, exe_basename: []const u8) bool {
        return !self.isWhitelisted(exe_basename);
    }

    pub fn tickAndAudit(self: Reaper, writer: anytype) errors.SecurityError!void {
        const ts: i64 = @intCast(@divTrunc(std.time.nanoTimestamp(), 1_000_000));
        try audit.log(writer, .{
            .ts = ts,
            .kind = "reaper",
            .detail = "policy_tick",
        });
        _ = self;
    }

    /// Closed-loop prune: cryptographic proof, stderr witness, then `SIGKILL` (non-test Linux).
    pub fn killIfNotWhitelisted(self: Reaper, pid: std.posix.pid_t, exe_basename: []const u8) errors.SecurityError!void {
        if (self.isWhitelisted(exe_basename)) return;
        var stack: [512]u8 align(8) = undefined;
        var fba = std.heap.fixedBufferAllocator(&stack);
        var pr = std.ArrayList(u8).init(fba.allocator());
        defer pr.deinit();
        try audit.recordDefensive(pr.writer(), "reaper_prune", exe_basename);
        writeStderrSlice(pr.items);
        if (builtin.is_test) return error.Unimplemented;
        if (builtin.os.tag == .linux) {
            std.posix.kill(pid, std.posix.SIG.KILL) catch return error.PermissionDenied;
            return;
        }
        return error.Unimplemented;
    }
};

fn writeStderrSlice(bytes: []const u8) void {
    var off: usize = 0;
    while (off < bytes.len) {
        const n = std.posix.write(2, bytes[off..]) catch return;
        if (n == 0) return;
        off += n;
    }
}

// ── Sovereign syscall policy (behavioral kill-switch; no manual review gate) ─

pub const Module = enum {
    haskell_bridge,
    rust_clerk,
    zig_security,
};

pub const SovereignAction = enum {
    allowed,
    /// `execve` denied for this module — autonomous tree termination (non-test).
    terminated,
};

/// Per-module syscall posture. Default: **no `execve`** from Haskell or Rust CLERK surfaces.
pub const SovereignPolicy = struct {
    pub fn default() SovereignPolicy {
        return .{};
    }

    pub fn execveNr() u32 {
        return switch (builtin.cpu.arch) {
            .x86_64 => 59,
            .aarch64 => 221,
            else => 59,
        };
    }

    pub fn allowsExecve(_: SovereignPolicy, mod: Module) bool {
        return mod == .zig_security;
    }

    pub fn onSyscall(
        _: SovereignPolicy,
        writer: anytype,
        mod: Module,
        nr: u32,
        root_pid: std.posix.pid_t,
    ) errors.SecurityError!SovereignAction {
        const ex = execveNr();
        if (nr == ex and !SovereignPolicy.allowsExecve(.{}, mod)) {
            try audit.recordDefensive(writer, "sovereign_kill_switch", "execve_denied_autonomous_tree_kill");
            if (!builtin.is_test and builtin.os.tag == .linux) {
                terminateProcessTreeLinux(root_pid);
            }
            return .terminated;
        }
        return .allowed;
    }
};

fn terminateProcessTreeLinux(root_pid: std.posix.pid_t) void {
    _ = std.posix.kill(root_pid, std.posix.SIG.KILL) catch {};
}

// ── Syscall / seccomp (legacy `syscall.zig`) ─────────────────────────────

/// Minimal allowlist sketch: production uses seccomp_rule_add / seccomp_load.
pub const FilterMode = enum {
    /// Block everything not explicitly allowed.
    restrictive,
    /// Allow common libc + networking, block dangerous syscalls.
    permissive,
};

pub fn applyFilter(mode: FilterMode) errors.SecurityError!void {
    _ = mode;
    return error.Unimplemented;
}

/// Emit an audit line when the kernel would kill the process (userspace simulation hook).
pub fn onViolationLog(writer: anytype, syscall_nr: i32) !void {
    try std.fmt.format(writer, "seccomp: blocked syscall {}\n", .{syscall_nr});
}

const FilterMode_Type = FilterMode;
const apply_filter_fn = applyFilter;
const on_violation_log_fn = onViolationLog;

// ── Process (legacy `process.zig`) ───────────────────────────────────────

pub const Proc = struct {
    pub fn currentPid() std.posix.pid_t {
        return std.posix.getpid();
    }

    /// Drop privileges after binding sockets / opening capture devices.
    pub fn dropPrivileges(target_uid: std.posix.uid_t, target_gid: std.posix.gid_t) errors.SecurityError!void {
        _ = target_uid;
        _ = target_gid;
        return error.Unimplemented;
    }

    /// Unshare / namespace setup belongs here (clone flags, mount ns, etc.).
    pub fn isolateProcessNamespace() errors.SecurityError!void {
        return error.Unimplemented;
    }
};

// ── Thread (legacy `thread.zig`) ───────────────────────────────────────────

/// CLERK hot-path gate: when set, Rust/Haskell must not enter CALC FFI until cleared (autonomous suspend).
var hot_path_mu: std.Thread.Mutex = .{};
var hot_path_suspended: bool = false;

pub const Thread = struct {
    pub const Monitor = struct {
        name: []const u8 = "rice-security-thread",
    };

    pub fn spawnSupervised(comptime f: fn () void) errors.SecurityError!std.Thread {
        return std.Thread.spawn(.{}, f, .{}) catch return error.OutOfMemory;
    }

    pub fn requestHighPriority() errors.SecurityError!void {
        return error.Unimplemented;
    }

    pub fn deadlockWatchdogTick() void {}

    /// Immediate **suspend** of the financial hot path (algorithmic pressure / DDoS reaction).
    pub fn suspendHotPath() void {
        hot_path_mu.lock();
        hot_path_suspended = true;
        hot_path_mu.unlock();
    }

    pub fn resumeHotPath() void {
        hot_path_mu.lock();
        hot_path_suspended = false;
        hot_path_mu.unlock();
    }

    pub fn hotPathSuspended() bool {
        hot_path_mu.lock();
        const s = hot_path_suspended;
        hot_path_mu.unlock();
        return s;
    }
};

// ── Sandbox (legacy `isolate.zig`) ─────────────────────────────────────────

pub const Sandbox = struct {
    seccomp_mode: FilterMode = .restrictive,

    pub fn apply(self: Sandbox) errors.SecurityError!void {
        _ = self;
        return error.Unimplemented;
    }
};

fn applySandbox(sb: Sandbox) errors.SecurityError!void {
    return sb.apply();
}

const Sandbox_Type = Sandbox;

// ── Legacy module namespaces (non-breaking `root.zig` re-exports) ─────────

const syscall_legacy = struct {
    pub const FilterMode = FilterMode_Type;
    pub const applyFilter = apply_filter_fn;
    pub const onViolationLog = on_violation_log_fn;
};
pub const syscall = syscall_legacy;

const process_legacy = struct {
    pub const currentPid = Proc.currentPid;
    pub const dropPrivileges = Proc.dropPrivileges;
    pub const isolateProcessNamespace = Proc.isolateProcessNamespace;
};
pub const process = process_legacy;

pub const thread = struct {
    pub const Monitor = Thread.Monitor;
    pub const spawnSupervised = Thread.spawnSupervised;
    pub const requestHighPriority = Thread.requestHighPriority;
    pub const deadlockWatchdogTick = Thread.deadlockWatchdogTick;
    pub const suspendHotPath = Thread.suspendHotPath;
    pub const resumeHotPath = Thread.resumeHotPath;
    pub const hotPathSuspended = Thread.hotPathSuspended;
};

pub const isolate = struct {
    pub const Sandbox = Sandbox_Type;
    pub fn apply(sb: Sandbox_Type) errors.SecurityError!void {
        return applySandbox(sb);
    }
    pub const syscall = syscall_legacy;
    pub const process = process_legacy;
};

test "isolate.apply returns Unimplemented until wired" {
    try std.testing.expectError(error.Unimplemented, isolate.apply(.{}));
}

test "reaper marks unknown exe for removal" {
    const r = Reaper{ .policy = .{ .whitelist_exec_basenames = &.{"zig"} } };
    try std.testing.expect(r.shouldReap("evil"));
    try std.testing.expect(!r.shouldReap("zig"));
}

test "sovereign policy terminates execve from haskell bridge (no kill in test)" {
    const saved_tip = audit.chain_tip;
    defer audit.chain_tip = saved_tip;

    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    const w = list.writer();
    const act = try SovereignPolicy.onSyscall(w, .haskell_bridge, SovereignPolicy.execveNr(), 1);
    try std.testing.expect(act == .terminated);
    try std.testing.expect(std.mem.indexOf(u8, list.items, "proof_sha256:") != null);
}

test "sovereign policy allows execve from zig_security" {
    const saved_tip = audit.chain_tip;
    defer audit.chain_tip = saved_tip;

    var list = std.ArrayList(u8).init(std.testing.allocator);
    defer list.deinit();
    const act = try SovereignPolicy.onSyscall(list.writer(), .zig_security, SovereignPolicy.execveNr(), 1);
    try std.testing.expect(act == .allowed);
}
