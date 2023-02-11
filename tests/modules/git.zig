const std = @import("std");
const testing = std.testing;
const git = @import("modules").git;
const runner = @import("../runner.zig");

pub fn run() !void {
    try test_libgit2_init_and_shutdown();
    try test_libgit2_init_and_shutdown_multiple();
    try test_git_repository_discover();
    try test_git_repository_tests();
}

/// test a simple init and shutdown of libgit2
fn test_libgit2_init_and_shutdown() !void {
    runner.notify("git.libgit2_init_and_shutdown");
    try testing.expectEqual(true, git.init());
    try testing.expectEqual(true, git.shutdown());
}

/// test subsequent initializations and shutdowns of libgit2
fn test_libgit2_init_and_shutdown_multiple() !void {
    runner.notify("git.libgit2_init_and_shutdown_multiple");

    try testing.expectEqual(true, git.init());
    try testing.expectEqual(true, git.init());

    // only need to call shutdown once, as it loops internally
    // commenting this should show a memory leak in valgrind
    try testing.expectEqual(true, git.shutdown());
}

fn test_git_repository_discover() !void {
    runner.notify("git.git_repository_discover");

    // init and shutdown libgit2
    _ = git.init();
    defer _ = git.shutdown();

    // this test should not fail when run inside the project repository
    var repo = try git.GitRepository.discover(".");
    defer repo.free();

    runner.print_diagnostics("gitPath: {s}", .{repo.path.?});
}

fn test_git_repository_tests() !void {
    runner.notify("git.git_repository_tests");

    // init and shutdown libgit2
    _ = git.init();
    defer _ = git.shutdown();

    var repo = try git.GitRepository.discover(".");
    defer repo.free();

    //================================================================
    // add all git tests here
    //================================================================

    // repo is not empty
    try testing.expectEqual(false, repo.is_empty());
    try testing.expectEqual(false, repo.is_bare());
    try testing.expectEqual(false, repo.is_detached());

    runner.print_diagnostics("branch: {?}", .{repo.current_branch_name()});
    runner.print_diagnostics("hash: {s}", .{repo.current_commit_hash(8)});
}
