const std = @import("std");
const testing = std.testing;
const os = @import("modules").os;
const runner = @import("../runner.zig");

pub fn run() !void {
    try test_get_username();
}

fn test_get_username() !void {
    runner.notify("test os.get_username");

    const username = os.get_username();
    try testing.expect(username.len > 0);

    const username2 = os.get_username();
    try testing.expect(username2.len > 0);

    runner.print_diagnostics("username: {s}", .{username});

    // the display name may not be set on all platforms, as it is optional
    runner.print_diagnostics("displayName: {s}", .{os.get_user_display_name()});
}
