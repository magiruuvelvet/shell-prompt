const std = @import("std");
const testing = std.testing;
const os = @import("modules").os;
const runner = @import("../runner.zig");

pub fn run() !void {
    try test_get_username();
    try test_get_hostname();
    try test_get_clock_time();
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
