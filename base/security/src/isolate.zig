//! Sandbox glue: syscall filters + process hooks + cgroup/resource limits (stubs).
const std = @import("std");
const errors = @import("error.zig");
const syscall_mod = @import("syscall.zig");
const process_mod = @import("process.zig");

// [ ] — namespaces clone/setrlimit RICE_SECURITY_*; chroot RICE_SECURITY_JAIL_PATH; capability drop

pub const Sandbox = struct {
    seccomp_mode: syscall_mod.FilterMode = .restrictive,
};

pub fn apply(sb: Sandbox) errors.SecurityError!void {
    _ = sb;
    // Chain `syscall.applyFilter` + namespace/cgroup setup when implementations land.
    return error.Unimplemented;
}

pub const syscall = syscall_mod;
pub const process = process_mod;
