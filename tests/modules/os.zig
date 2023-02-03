const std = @import("std");
const testing = std.testing;
const os = @import("modules").os;
const runner = @import("../runner.zig");

pub fn run() !void {
    try test_get_username();
    try test_get_hostname();
    try test_get_clock_time();
    try test_get_pwd();
    try test_get_directory_stats();
}

fn test_get_username() !void {
    runner.notify("os.get_username");

    const username = os.get_username();
    try testing.expect(username.len > 0);

    const username2 = os.get_username();
    try testing.expect(username2.len > 0);

    runner.print_diagnostics("username: {s}", .{username});

    // the display name may not be set on all platforms, as it is optional
    runner.print_diagnostics("displayName: {s}", .{os.get_user_display_name()});
}

fn test_get_hostname() !void {
    runner.notify("os.get_hostname");

    const hostname = os.get_hostname();
    try testing.expect(hostname.len > 0);

    const hostname2 = os.get_hostname();
    try testing.expect(hostname2.len > 0);

    runner.print_diagnostics("hostname: {s}", .{hostname});
}

fn test_get_clock_time() !void {
    runner.notify("os.get_clock_time");

    const time = os.time.get_clock_time();
    if (time) |t| {
        runner.print_diagnostics("clockTime: {s}", .{t});
    } else |e| {
        // abort test run on failure
        return e;
    }
}

fn test_get_pwd() !void {
    runner.notify("os.get_pwd");

    const cwd = os.dir.get_pwd() catch |err| {
        return err;
    };

    try testing.expect(cwd.len > 0);

    runner.print_diagnostics("pwd: {s}", .{cwd});
}

fn test_get_directory_stats() !void {
    runner.notify("os.get_directory_stats");

    const cwd = try os.dir.get_pwd();

    const stats = os.dir.get_directory_stats(cwd);
    if (stats) |s| {
        // assume that at least the test binary exists in the working directory
        try testing.expect(s.visible > 0);

        runner.print_diagnostics("directoryStats: visible={}, hidden={}", .{s.visible, s.hidden});
    } else |e| {
        // abort test run on failure
        return e;
    }
}
