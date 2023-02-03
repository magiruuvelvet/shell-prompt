const std = @import("std");

const stdout_file = std.io.getStdOut().writer();
var bw = std.io.bufferedWriter(stdout_file);
const stdout = bw.writer();

pub inline fn print(comptime fmt: []const u8, args: anytype) void {
    stdout.print(fmt, args) catch unreachable;
    bw.flush() catch unreachable;
}
