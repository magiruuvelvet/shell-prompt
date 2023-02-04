const std = @import("std");
const testing = std.testing;
const modules = @import("modules");
const renderer = @import("prompt").renderer;
const runner = @import("../runner.zig");

const get_winsize = modules.term.get_winsize;

inline fn print_rendering_test_name(test_name: []const u8) void {
    _ = renderer.draw_text(test_name);
    renderer.new_line();
}

pub fn run() !void {
    try test_draw_text();
    try test_draw_line();
}

fn test_draw_text() !void {
    runner.notify("renderer.draw_text");

    const cols_drawn = renderer.draw_text("hello 世界!");
    try testing.expect(11 == cols_drawn);

    renderer.new_line();
}

fn test_draw_line() !void {
    runner.notify("renderer.draw_line");

    var cols_drawn: u16 = 0;

    //==============================================================================

    print_rendering_test_name("BOX DRAWINGS LIGHT HORIZONTAL (U+2500)");
    cols_drawn = renderer.draw_line("─", get_winsize().columns);

    // character has a width of 1, printed columns must match the terminal columns
    try testing.expectEqual(get_winsize().columns, cols_drawn);

    renderer.new_line();
    runner.print_diagnostics("colsDrawn: {}", .{cols_drawn});

    //==============================================================================

    print_rendering_test_name("FULLWIDTH LOW LINE (U+FF3F)");
    cols_drawn = renderer.draw_line("＿", get_winsize().columns);

    // character has a width of 2, printed columns must either match the terminal columns (even terminal width)
    // or must be exactly {terminal columns - 1} on odd terminal width
    if (get_winsize().columns % 2 == 0) {
        try testing.expectEqual(get_winsize().columns, cols_drawn);
    } else {
        try testing.expectEqual(get_winsize().columns - 1, cols_drawn);
    }

    renderer.new_line();
    runner.print_diagnostics("colsDrawn: {}", .{cols_drawn});
}
