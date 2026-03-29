const std = @import("std");
const sec = @import("root.zig");

// [ ] — microbench syscall filter, pcap, eBPF, audit; std.time.Timer; output for criterion rice-bench

pub fn main() !void {
    var buf: [4096]u8 = undefined;
    @memset(&buf, 0x5a);
    var timer = try std.time.Timer.start();
    for (0..1000) |_| {
        sec.memory.secureWipe(&buf);
    }
    const ns = timer.read();
    std.debug.print("secureWipe x1000: {} ns\n", .{ns});
}
