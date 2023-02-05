const std = @import("std");
const testing = std.testing;
const term = @import("modules").term;
const color = term.color;
const runner = @import("../runner.zig");

pub fn run() !void {
    try test_get_winsize();
    try test_wcwidth_valid();
    try test_wcwidth_invalid();
    try test_color();
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

    // BOX DRAWINGS LIGHT HORIZONTAL (U+2500)
    wcwidth = term.wcwidth("─");
    try testing.expect(wcwidth == 1);

    // FULLWIDTH LOW LINE (U+FF3F)
    wcwidth = term.wcwidth("＿");
    try testing.expect(wcwidth == 2);
}

/// test broken input
///
/// **DON'T "FIX" THESE TESTS, ON FAILURE THE `wcwidth` Zig BINDINGS ARE BROKEN!!**
fn test_wcwidth_invalid() !void {
    runner.notify("term.wcwidth_invalid");

    // invalid utf-8
    var wcwidth = term.wcwidth("\x20\x21\x93");
    try testing.expect(wcwidth == -0xFF);

    // ESC sequence
    wcwidth = term.wcwidth("\x1b1m");
    try testing.expect(wcwidth == -1);
}

fn test_color() !void {
    runner.notify("term.color");

    runner.print_diagnostics("{s}", .{color.bold("this is bold")});
    runner.print_diagnostics("{s}", .{color.italic("this is italic")});

    runner.print_diagnostics("{s}", .{color.rgb_bold("this is bold and red (#cd0000)", 205, 0, 0, color.mode.foreground)});
    runner.print_diagnostics("{s}", .{color.rgb_italic("this is italic and blue (#1383a5)", 20, 131, 165, color.mode.foreground)});
    runner.print_diagnostics("{s}", .{color.rgb("this is green", 15, 154, 20, color.mode.foreground)});

    runner.print_diagnostics("{s}", .{color.rgb("this has gray background", 211, 211, 211, color.mode.background)});

    // var chain = color.chain.init()
    //     .text("normal text ")
    //     .bold().text("bold text").normal()
    //     .text(" ")
    //     .italic().text("italic text").normal();

    // runner.print_diagnostics("{s}", .{chain});
}
