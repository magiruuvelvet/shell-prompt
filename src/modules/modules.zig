//! modules to collect data for the shell prompt
//! contains operating system abstractions and other useful plugins

// import of all modules

pub const term = @import("term/term.zig");
pub const os = @import("os/os.zig");
pub const git = @import("git/git.zig");
