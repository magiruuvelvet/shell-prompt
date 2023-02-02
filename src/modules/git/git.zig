const std = @import("std");

const c = @cImport({
    @cInclude("git2.h");
});

/// Initialize libgit2 global state.
pub fn init() bool {
    return (c.git_libgit2_init() > 0);
}

/// Clean up libgit2 global state.
pub fn shutdown() bool {
    // call the shutdown function as often as there are initializations
    while (c.git_libgit2_shutdown() != 0) {}
    return true;
}
