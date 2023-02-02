const std = @import("std");
const builtin = @import("builtin");
const winsize = @import("winsize.zig").winsize;

/// platform-specific implementations
const impl = switch (builtin.target.os.tag) {
    .linux => @import("platform/linux.zig"),
    else => @compileError("unsupported platform"),
};

/// get the terminal window size
pub fn get_winsize() winsize {
    return impl.get_winsize();
}
