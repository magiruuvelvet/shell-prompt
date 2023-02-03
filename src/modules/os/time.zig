const std = @import("std");

const c = @cImport({
    @cInclude("time.h");
});

/// struct to store time values
pub const time = struct {
    hours: u8,
    minutes: u8,
    seconds: u8,

    /// formats this time struct into a HH:MM:SS (hours, minutes, seconds) string with 0 padding as needed
    pub fn format(value: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) std.os.WriteError!void {
        return writer.print("{d:0>2}:{d:0>2}:{d:0>2}", .{ value.hours, value.minutes, value.seconds });
    }
};

/// returns the current system time in hours, minutes and seconds
/// the local system timezone is used
pub fn get_clock_time() error{GetClockTimeFailed}!time {
    // get current UNIX timestamp
    const timestamp = std.time.timestamp();

    // use the system localtime() function to convert UNIX timestamp
    const tm = c.localtime(&timestamp);

    // localtime() returned a null pointer
    if (tm == null)
    {
        return error.GetClockTimeFailed;
    }

    return time{
        .hours = @intCast(u8, tm.*.tm_hour),
        .minutes = @intCast(u8, tm.*.tm_min),
        .seconds = @intCast(u8, tm.*.tm_sec),
    };
}
