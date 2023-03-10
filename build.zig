const std = @import("std");
const CrossTarget = std.zig.CrossTarget;
const Builder = std.build.Builder;

var target: CrossTarget = undefined;
var mode: std.builtin.Mode = undefined;

const deps = struct {
    /// https://github.com/JakubSzark/zig-string
    const zig_string = std.build.Pkg{
        .name = "zig-string",
        .source = .{ .path = "libs/zig-string/zig-string.zig" },
    };

    /// https://github.com/Hejsil/zig-clap
    const zig_clap = std.build.Pkg{
        .name = "zig-clap",
        .source = .{ .path = "libs/zig-clap/clap.zig" },
    };
};

const pkgs = struct {
    /// modules to collect data for the shell prompt
    /// contains operating system abstractions and other useful plugins
    ///
    /// the use of C code is allowed in this package
    const modules = std.build.Pkg{
        .name = "modules",
        .source = .{ .path = "src/modules/modules.zig" },
        .dependencies = &[_]std.build.Pkg{
            deps.zig_string,
        },
    };

    /// general purpose utilities
    ///
    /// avoid using C, pure Zig package
    const utils = std.build.Pkg{
        .name = "utils",
        .source = .{ .path = "src/utils/package.zig" },
    };

    /// shell prompt package
    ///
    /// avoid using C, pure Zig package
    const prompt = std.build.Pkg{
        .name = "prompt",
        .source = .{ .path = "src/prompt/package.zig" },
        .dependencies = &[_]std.build.Pkg{
            deps.zig_string,
            utils,
            modules,
        },
    };

    /// sourceable shell scripts for initialization
    const shell = std.build.Pkg{
        .name = "shell",
        .source = .{ .path = "shell/package.zig" },
    };
};

fn add_c_libraries(step: *std.build.LibExeObjStep) void {
    const c_source_files = [_][]const u8{
        "src/modules/term/wcwidth/wcwidth.c",
    };

    const c_include_paths = [_][]const u8{
        "src/modules/term/wcwidth",
    };

    const common_flags = [_][]const u8{
        "-std=c99",
    };

    for (c_source_files) |*c_source_file| {
        step.addCSourceFile(c_source_file.*, &common_flags);
    }

    for (c_include_paths) |*c_incude_path| {
        step.addIncludePath(c_incude_path.*);
    }
}

fn add_libc(step: *std.build.LibExeObjStep) void {
    step.linkLibC();
    //step.setLibCFile(.{ .path = "./musl.libc" });
}

fn add_libgit2(step: *std.build.LibExeObjStep) void {
    step.addIncludePath("deps/libgit2/include");
    step.addLibraryPath("deps/libgit2/lib64");
    step.addObjectFile("deps/libgit2/lib64/liblibgit2package.a");
}

/// Build the main application binary.
fn build_shell_prompt(b: *Builder) *std.build.LibExeObjStep {
    const exe = b.addExecutable("shell-prompt", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);

    add_libc(exe);
    add_libgit2(exe);

    add_c_libraries(exe);

    exe.addPackage(pkgs.shell);
    exe.addPackage(pkgs.modules);
    exe.addPackage(pkgs.prompt);
    exe.addPackage(pkgs.utils);
    exe.addPackage(deps.zig_string);

    exe.addPackage(deps.zig_clap);

    exe.install();
    return exe;
}

/// Build the additional tools.
fn build_tools(b: *Builder) void {
    const gitRepoInfo = b.addExecutable("git-repo-info", "src/tools/git-repo-info.zig");
    gitRepoInfo.setTarget(target);
    gitRepoInfo.setBuildMode(mode);
    add_libc(gitRepoInfo);
    add_libgit2(gitRepoInfo);
    gitRepoInfo.addPackage(pkgs.modules); // for the git module
    gitRepoInfo.addPackage(pkgs.utils);
    gitRepoInfo.addPackage(deps.zig_clap);
    gitRepoInfo.install();
}

/// Build the unit tests.
fn build_unit_tests(b: *Builder) *std.build.LibExeObjStep {
    const unit_tests = b.addExecutable("shell-prompt-tests", "tests/main.zig");
    unit_tests.setTarget(target);
    unit_tests.setBuildMode(mode);

    add_libc(unit_tests);
    add_libgit2(unit_tests);

    unit_tests.addPackage(pkgs.modules);
    unit_tests.addPackage(pkgs.prompt);
    unit_tests.addPackage(pkgs.utils);

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

    build_tools(b);

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
