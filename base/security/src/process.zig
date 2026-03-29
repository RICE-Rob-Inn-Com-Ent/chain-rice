//! Process boundaries: privilege drop, namespace/capability stubs (Linux-oriented).
const std = @import("std");
const errors = @import("error.zig");

// [ ] — /proc tree; RICE_SECURITY_PROC_WHITELIST; kill RICE_SECURITY_KILL_ENABLED; ancestry NATS audit.clerk.kills

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
