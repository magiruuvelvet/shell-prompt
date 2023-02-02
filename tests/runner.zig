const std = @import("std");
const stdout = std.io.getStdOut().writer();

/// global test counter
var test_counter: u32 = 0;

/// print a message
pub fn print(comptime message: []const u8, args: anytype) void {
    stdout.print(message, args) catch unreachable;
    stdout.print("\n", .{}) catch unreachable;
}

pub fn print_diagnostics(comptime message: []const u8, args: anytype) void {
    stdout.print("   > ", .{}) catch unreachable;
    stdout.print(message, args) catch unreachable;
    stdout.print("\n", .{}) catch unreachable;
}

/// print test message and increase the test counter by one
pub fn notify(comptime message: []const u8) void {
    print(message, .{});
    test_counter += 1;
}

/// returns the global test counter
pub fn get_test_counter() u32 {
    return test_counter;
}
