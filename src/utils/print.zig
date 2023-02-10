const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var stdout_bw = std.io.bufferedWriter(stdout_file);
const stdout = stdout_bw.writer();

const stderr_file = std.io.getStdErr().writer();
var stderr_bw = std.io.bufferedWriter(stderr_file);
const stderr = stderr_bw.writer();

pub inline fn print(comptime fmt: []const u8, args: anytype) void {
    stdout.print(fmt, args) catch unreachable;
    stdout_bw.flush() catch unreachable;
}

pub inline fn err(comptime fmt: []const u8, args: anytype) void {
    stderr.print(fmt, args) catch unreachable;
    stderr_bw.flush() catch unreachable;
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
    stdout_bw.flush() catch unreachable;
}
