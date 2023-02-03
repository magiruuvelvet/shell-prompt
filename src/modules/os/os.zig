const std = @import("std");
const builtin = @import("builtin");

pub const time = @import("time.zig");

/// platform-specific implementations
const impl = switch (builtin.target.os.tag) {
    .linux, .macos, .watchos, .tvos, .ios, .freebsd, .netbsd, .openbsd, .haiku, .solaris => @import("platform/posix.zig"),
    else => @compileError("unsupported platform"),
};

/// get the username of the current user
pub fn get_username() []const u8 {
    return impl.get_username();
}

/// get the display name of the current user
pub fn get_user_display_name() []const u8 {
    return impl.get_user_display_name();
}

/// get the system hostname
pub fn get_hostname() []const u8 {
    return impl.get_hostname();
}
