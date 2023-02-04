const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

pub inline fn print(comptime fmt: []const u8, args: anytype) void {
    stdout.print(fmt, args) catch unreachable;
    bw.flush() catch unreachable;
}

/// directy write text to terminal without formatting
/// flush the output stream after the write operation
pub inline fn write_and_flush(text: []const u8) void {
    write_no_flush(text);
    flush();
}

/// directly write text to terminal without formatting
pub inline fn write_no_flush(text: []const u8) void {
    stdout.writeAll(text) catch unreachable;
}

/// flush the output stream
pub inline fn flush() void {
    bw.flush() catch unreachable;
}
