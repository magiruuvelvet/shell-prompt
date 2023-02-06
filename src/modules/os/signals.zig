const std = @import("std");
const builtin = @import("builtin");

/// platform-specific implementations
const impl = switch (builtin.target.os.tag) {
    .linux => @import("platform/linux.zig"),
    else => @compileError("unsupported platform"),
};

/// maps the given exit status to a known signal name
/// if the given exit status is not a signal, it returns the number as string
/// note that the exit status may not be actually a signal (depends on the implementation)
pub fn map_exit_status_to_signal_name(exit_status: u8) [] const u8 {
    return impl.map_exit_status_to_signal_name(exit_status);
}
