const std = @import("std");

// [ ] https://ziglang.org/documentation/master/std/
// [ ] security target: addLibrary / createModule — name from env RICE_ZIG_SECURITY_LIB_NAME; root path security/src/root.zig
// [ ] target + optimize: standardTargetOptions / standardOptimizeOption — no hardcoded triple
// [ ] linkSystemLibrary("pcap"), ("seccomp"), linkLibC — optional per OS; feature flags from env
// [ ] conditional: linux → eBPF + seccomp + inotify; macos → kqueue + sandbox — cfg by target.result.os.tag
// [ ] addTest — same module + system libs; test filter from env if needed
// [ ] installArtifact — prefix from RICE_ZIG_INSTALL_PREFIX / ZIG_OUT_DIR
// [ ] cache_root / global_cache_dir — ZIG_CACHE_DIR env
// [ ] addExecutable run step for security daemon — RICE_SECURITY_* config; run step name from env
// [ ] bench step — criterion integration path via rice-bench / env

/// Sole Zig orchestrator for CLERK (`base/`). Zig code lives only under module dirs (e.g. `security/`).
/// Run `zig build` only from `base/` — never from a submodule directory.
/// API targets Zig 0.15 (`addLibrary`, `createModule`, `root_module`).
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ── security ───────────────────────────────────────────────────────────
    const security_mod = b.createModule(.{
        .root_source_file = b.path("security/src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const security_lib = b.addLibrary(.{
        .name = "clerk-security",
        .root_module = security_mod,
        .linkage = .static,
    });
    security_lib.linkSystemLibrary("pcap");
    security_lib.linkSystemLibrary("seccomp");
    security_lib.linkLibC();
    b.installArtifact(security_lib);

    const security_tests = b.addTest(.{
        .root_module = security_mod,
    });
    security_tests.linkSystemLibrary("pcap");
    security_tests.linkSystemLibrary("seccomp");
    security_tests.linkLibC();

    const run_security_tests = b.addRunArtifact(security_tests);
    const test_step = b.step("test", "Run all CLERK Zig tests");
    test_step.dependOn(&run_security_tests.step);

    const bench_mod = b.createModule(.{
        .root_source_file = b.path("security/src/bench.zig"),
        .target = target,
        .optimize = .ReleaseFast,
    });

    const security_bench = b.addExecutable(.{
        .name = "clerk-security-bench",
        .root_module = bench_mod,
    });
    security_bench.linkSystemLibrary("pcap");
    security_bench.linkSystemLibrary("seccomp");
    security_bench.linkLibC();
    b.installArtifact(security_bench);

    const run_security_bench = b.addRunArtifact(security_bench);
    const bench_step = b.step("bench", "Run all CLERK Zig benchmarks");
    bench_step.dependOn(&run_security_bench.step);

    // New Zig modules: add `createModule` / `addLibrary` or `addExecutable` here;
    // add `module/build.zig.zon` next to `module/src/` (Zig 0.15 zon schema).
}
