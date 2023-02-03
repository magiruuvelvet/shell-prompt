const std = @import("std");
const testing = std.testing;
const term = @import("modules").term;
const runner = @import("../runner.zig");

pub fn run() !void {
    try test_get_winsize();
    try test_wcwidth_valid();
    try test_wcwidth_invalid();
}

fn test_get_winsize() !void {
    runner.notify("term.get_winsize");

    const winsize = term.get_winsize();

    // need to get a size, should not be zero
    try testing.expect(winsize.columns != 0);
    try testing.expect(winsize.lines != 0);

    runner.print_diagnostics("winsize: columns={} lines={}", .{winsize.columns, winsize.lines});
}

/// test valid input and expected output
///
/// **DON'T "FIX" THESE TESTS, ON FAILURE THE `wcwidth` Zig BINDINGS ARE BROKEN!!**
fn test_wcwidth_valid() !void {
    runner.notify("term.wcwidth_valid");

    var wcwidth = term.wcwidth("hello world");
    try testing.expect(wcwidth == 11);

    wcwidth = term.wcwidth("hello 世界！");
    try testing.expect(wcwidth == 12);

    wcwidth = term.wcwidth("マギルゥーベルベット");
    try testing.expect(wcwidth == 20);

    wcwidth = term.wcwidth(" 　"); // U+20, U+3000
    try testing.expect(wcwidth == 3);

    wcwidth = term.wcwidth("小猫");
    try testing.expect(wcwidth == 4);

    wcwidth = term.wcwidth("한국어");
    try testing.expect(wcwidth == 6);
}

/// test broken input
///
/// **DON'T "FIX" THESE TESTS, ON FAILURE THE `wcwidth` Zig BINDINGS ARE BROKEN!!**
fn test_wcwidth_invalid() !void {
    runner.notify("term.wcwidth_invalid");

    // invalid utf-8
    var wcwidth = term.wcwidth("\x20\x21\x93");
    try testing.expect(wcwidth == -0xFF);
}
