const std = @import("std");
const runner = @import("runner.zig");

/// primitive test runner to have tests in their own source directory
/// binary works in valgrind to detect memory leaks
pub fn main() !void {
    runner.print("running tests...", .{});

    try @import("modules/term.zig").run();
    try @import("modules/os.zig").run();
    try @import("modules/git.zig").run();

    try @import("prompt/renderer.zig").run();

    runner.print("{} tests executed.", .{runner.get_test_counter()});
}
