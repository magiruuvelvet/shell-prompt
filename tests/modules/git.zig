const std = @import("std");
const testing = std.testing;
const git = @import("modules").git;
const runner = @import("../runner.zig");

pub fn run() !void {
    try test_libgit2_init_and_shutdown();
    try test_libgit2_init_and_shutdown_multiple();
}

/// test a simple init and shutdown of libgit2
fn test_libgit2_init_and_shutdown() !void {
    runner.notify("test git.libgit2_init_and_shutdown");
    try testing.expectEqual(true, git.init());
    try testing.expectEqual(true, git.shutdown());
}

/// test subsequent initializations and shutdowns of libgit2
fn test_libgit2_init_and_shutdown_multiple() !void {
    runner.notify("test git.libgit2_init_and_shutdown_multiple");

    try testing.expectEqual(true, git.init());
    try testing.expectEqual(true, git.init());

    // only need to call shutdown once, as it loops internally
    // commenting this should show a memory leak in valgrind
    try testing.expectEqual(true, git.shutdown());
}
