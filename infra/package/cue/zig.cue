package package

languageZig: {
  manager:      "zig"
  manifestFile: "build.zig"
  ecosystem:    "zig"
  manifests: [
    "base/build.zig",
    "base/build.zig.zon",
    "base/security/build.zig.zon",
  ]

  build: {
    buildZigPath: "base/build.zig"
    buildZonPath: "base/build.zig.zon"
    optimizeModes: ["Debug", "ReleaseSafe", "ReleaseFast", "ReleaseSmall"]
    targets: {
      security: {
        entry: "base/security/src/root.zig"
        kind:  "static-lib"
      }
      audit: {
        entry: "base/security/src/audit.zig"
        kind:  "exe"
      }
    }
  }

  constraints: {
    _hasDebugMode: build.optimizeModes[0] == "Debug"
  }

  render: {
    buildZig: {
      name: "build-zig"
      path: build.buildZigPath
      kind: "zig-build"
      data: build
    }
    buildZon: {
      name: "build-zon"
      path: build.buildZonPath
      kind: "zig-zon"
      data: {
        name: "rice-base"
        version: "0.1.0"
      }
    }
  }

  emitFiles: [
    {
      path: "base/build.zig"
      content: #"""
const std = @import("std");

// [ ] https://ziglang.org/documentation/master/std/
// [ ] security target: addLibrary / createModule — name from env CLERK_ZIG_SECURITY_LIB_NAME; root path security/src/root.zig
// [ ] target + optimize: standardTargetOptions / standardOptimizeOption — no hardcoded triple
// [ ] linkSystemLibrary("pcap"), ("seccomp"), linkLibC — optional per OS; feature flags from env
// [ ] conditional: linux → eBPF + seccomp + inotify; macos → kqueue + sandbox — cfg by target.result.os.tag
// [ ] addTest — same module + system libs; test filter from env if needed
// [ ] installArtifact — prefix from CLERK_ZIG_INSTALL_PREFIX / ZIG_OUT_DIR
// [ ] cache_root / global_cache_dir — ZIG_CACHE_DIR env
// [ ] addExecutable run step for security daemon — CLERK_SECURITY_* config; run step name from env
/// Sole Zig orchestrator for CLERK (`base/`). Zig code lives only under module dirs (e.g. `security/`).
/// Run `zig build` only from `base/` — never from a submodule directory.
/// API targets Zig 0.15 (`addLibrary`, `createModule`, `root_module`).
///
/// Quality gates (all Zig under this tree today: `build.zig` + `security/**`):
/// - `zig build fmt` — `zig fmt` in place on `build.zig`, `build.zig.zon`, and `security/`.
/// - `zig build fmt-check` — `zig fmt --check` on the same paths.
/// - `zig build lint` — `zig ast-check` on `build.zig` and every `*.zig` under `security/`.
/// - `zig build verify` — `fmt-check` + `lint` + `test` (use in CI).
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const fmt_paths = [_][]const u8{ "build.zig", "build.zig.zon", "security" };

    const fmt_write = b.addFmt(.{
        .paths = &fmt_paths,
        .exclude_paths = &.{},
        .check = false,
    });
    const fmt_check = b.addFmt(.{
        .paths = &fmt_paths,
        .exclude_paths = &.{},
        .check = true,
    });

    const fmt_step = b.step("fmt", "Apply zig fmt to build.zig, build.zig.zon, and security/");
    fmt_step.dependOn(&fmt_write.step);

    const fmt_check_step = b.step("fmt-check", "Verify zig fmt (--check) on the same paths");
    fmt_check_step.dependOn(&fmt_check.step);

    const lint_step = b.step("lint", "Run zig ast-check on build.zig and every .zig under security/");
    addLintAstCheckSteps(b, lint_step);

    // ── security quality gates ─────────────────────────────────────────────
    // Build of the static `clerk-security` artifact is owned by `//base/security:check` (Buck).
    // `build.zig` stays focused on fmt/lint/test for Zig sources.
    const security_mod = b.createModule(.{
        .root_source_file = b.path("security/src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const security_tests = b.addTest(.{
        .root_module = security_mod,
    });
    security_tests.linkSystemLibrary("pcap");
    security_tests.linkSystemLibrary("seccomp");
    security_tests.linkLibC();

    const run_security_tests = b.addRunArtifact(security_tests);
    const test_step = b.step("test", "Run all Zig tests");
    test_step.dependOn(&run_security_tests.step);

    const verify_step = b.step("verify", "fmt-check + lint + test (CI-oriented)");
    verify_step.dependOn(&fmt_check.step);
    verify_step.dependOn(lint_step);
    verify_step.dependOn(test_step);

    // New Zig modules: add `createModule` / `addLibrary` or `addExecutable` here;
    // add `module/build.zig.zon` next to `module/src/` (Zig 0.15 zon schema);
    // extend `fmt_paths` / `addLintAstCheckSteps` (or walk roots) so fmt + ast-check stay repo-wide.
}

fn addLintAstCheckSteps(b: *std.Build, lint_root: *std.Build.Step) void {
    const zig_exe = b.graph.zig_exe;

    const run_build_zig = b.addSystemCommand(&.{ zig_exe, "ast-check" });
    run_build_zig.addFileArg(b.path("build.zig"));
    lint_root.dependOn(&run_build_zig.step);

    var sec_dir = b.build_root.handle.openDir("security", .{ .iterate = true }) catch |err| {
        std.debug.panic("openDir(\"security\"): {any}", .{err});
    };
    defer sec_dir.close();

    var walker = sec_dir.walk(b.allocator) catch |err| {
        std.debug.panic("walk allocator: {any}", .{err});
    };
    defer walker.deinit();

    while (true) {
        const maybe_entry = walker.next() catch |err| {
            std.debug.panic("security walk: {any}", .{err});
        };
        const entry = maybe_entry orelse break;
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.basename, ".zig")) continue;

        const rel_path = std.fs.path.join(b.allocator, &.{
            "security",
            std.mem.sliceTo(entry.path, 0),
        }) catch |err| {
            std.debug.panic("path join: {any}", .{err});
        };

        const run = b.addSystemCommand(&.{ zig_exe, "ast-check" });
        run.addFileArg(b.path(rel_path));
        lint_root.dependOn(&run.step);
    }
}
"""#
    },
    {
      path: "base/build.zig.zon"
      content: #"""
.{
    // Identity — declares the Clerk root package for the .rice sovereign machine (resolver id + semver).
    .name = .clerk,
    .version = "0.1.0",

    // Toolchain — compiler floor so ZON fields and package manifests match the supported matrix.
    .minimum_zig_version = "0.15.0",

    // Security Envelope — immutable package fingerprint (rotate when `.name` / graph changes; `zig build` may suggest a value).
    .fingerprint = 0xe82fa413605bee27,

    // Security Envelope — external roots: watchdog module binds financial / logical operations to audited Zig.
    .dependencies = .{
        .security = .{
            .path = "security",
        },
        // Enable via CLERK_SECURITY_NETWORK; requires .url and .hash from zig fetch.
        // .@"zig-network" = .{
        //     .url = "https://github.com/MasterQ32/zig-network/archive/refs/heads/master.tar.gz",
        //     .hash = "1220…",
        // },
    },

    // Security Envelope — publish set: ship build scripts plus nested security tree for recursive dependency builds.
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "security",
    },
}
"""#
    },
    {
      path: "base/security/build.zig.zon"
      content: #"""
.{
    .name = .security,
    .version = "0.1.0",
    // Unique package id; regenerate if you fork or rename `.name` (see Zig 0.15 release notes).
    .fingerprint = 0xc59bd5c11ed465d7,
    .minimum_zig_version = "0.15.0",
    .dependencies = .{},
    .paths = .{
        "build.zig.zon",
        "src",
    },
}
"""#
    },
  ]
}
