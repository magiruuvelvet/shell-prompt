const std = @import("std");

pub inline fn format(comptime fmt: []const u8, args: anytype) []const u8 {
    return std.fmt.allocPrint(std.heap.page_allocator, fmt, args) catch unreachable;
}
