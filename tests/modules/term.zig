const std = @import("std");
const testing = std.testing;
const term = @import("modules").term;
const runner = @import("../runner.zig");

pub fn run() !void {
    try test_get_winsize();
}

fn test_get_winsize() !void {
    runner.notify("test term.get_winsize");

    const winsize = term.get_winsize();

    // need to get a size, should not be zero
    try testing.expect(winsize.columns != 0);
    try testing.expect(winsize.lines != 0);

    runner.print_diagnostics("winsize: columns={} lines={}", .{winsize.columns, winsize.lines});
}
