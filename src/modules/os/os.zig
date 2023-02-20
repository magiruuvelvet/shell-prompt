const std = @import("std");
const builtin = @import("builtin");

pub const dir = @import("dir.zig");
pub const time = @import("time.zig");
pub const signals = @import("signals.zig");
pub const ssh = @import("ssh.zig");

/// platform-specific implementations
const impl = switch (builtin.target.os.tag) {
    .linux, .macos, .watchos, .tvos, .ios, .freebsd, .netbsd, .openbsd, .haiku, .solaris => @import("platform/posix.zig"),
    else => @compileError("unsupported platform"),
};

/// get the user id
pub fn get_uid() u32 {
    return impl.get_uid();
}

/// get the username of the current user
pub fn get_username() []const u8 {
    return impl.get_username();
}

/// get the display name of the current user
pub fn get_user_display_name() []const u8 {
    return impl.get_user_display_name();
}

/// get the user's home directory
pub fn get_home_directory() ?[]const u8 {
    return impl.get_home_directory();
}

/// get the system hostname
pub fn get_hostname() []const u8 {
    return impl.get_hostname();
}
