const std = @import("std");
const testing = std.testing;
const build_system = @import("modules").build_system;
const runner = @import("../runner.zig");

pub fn run() !void {
    try test_build_system_colors();
}

fn test_build_system_colors() !void {
    runner.notify("build_system.build_system_colors");
    runner.print_diagnostics("{s}", .{build_system.test_build_system_colors()});
}
