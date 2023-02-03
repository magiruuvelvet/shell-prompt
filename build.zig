const std = @import("std");
const CrossTarget = std.zig.CrossTarget;
const Builder = std.build.Builder;

var target: CrossTarget = undefined;
var mode: std.builtin.Mode = undefined;

fn add_c_libraries(step: *std.build.LibExeObjStep) void {
    const c_source_files = [_][]const u8{
        "src/modules/term/wcwidth/wcwidth.c",
    };

    const common_flags = [_][]const u8{
        "-std=c99",
    };

    for (c_source_files) |*c_source_file| {
        step.addCSourceFile(c_source_file.*, &common_flags);
    }
}

/// Build the main application binary.
fn build_shell_prompt(b: *Builder) *std.build.LibExeObjStep {
    const exe = b.addExecutable("shell-prompt", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    exe.linkLibC();
    exe.linkSystemLibrary("git2");

    add_c_libraries(exe);

    exe.install();
    return exe;
}

/// Build the unit tests.
fn build_unit_tests(b: *Builder) *std.build.LibExeObjStep {
    const unit_tests = b.addExecutable("shell-prompt-tests", "tests/main.zig");
    unit_tests.setTarget(target);
    unit_tests.setBuildMode(mode);

    unit_tests.linkLibC();
    unit_tests.linkSystemLibrary("git2");

    unit_tests.addPackage(.{
        .name = "modules",
        .source = .{ .path = "src/modules/modules.zig" }
    });

    add_c_libraries(unit_tests);

    unit_tests.install();
    return unit_tests;
}

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    mode = b.standardReleaseOptions();

    _ = build_shell_prompt(b);
    _ = build_unit_tests(b);

    // internal tests are not relevant for library usage, but are still necessary
    // to validate correct function of platform-specific helper code within the code base
    const internal_tests = [_]*std.build.LibExeObjStep{
        b.addTest("src/modules/os/platform/posix.zig"),
    };
    const test_step = b.step("test", "Run internal tests");
    for (internal_tests) |*internal_test| {
        internal_test.*.linkLibC();
        test_step.dependOn(&internal_test.*.step);
    }
}
