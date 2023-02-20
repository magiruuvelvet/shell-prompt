const std = @import("std");

/// check if we are connected to a server via ssh
pub fn is_ssh_session() bool {
    return std.os.getenv("SSH_CLIENT") != null;
}
