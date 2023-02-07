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

/// git repository errors
pub const GitRepositoryError = error {
    NoRepositoryFound,
    OpenError,
};

pub const GitRepository = struct {
    /// raw pointer to libgit2 repository struct
    ptr: ?*c.git_repository = null,

    /// absolute path to the discovered git repository
    /// can be different from the given `starting_path`
    path: ?[]const u8 = null,

    /// discovers a git repository in the given starting directory
    pub fn discover(starting_path: []const u8) GitRepositoryError!GitRepository {
        var git_repo_ptr: ?*c.git_repository = null;

        // allocate git_buf and dispose it automatically when we're done
        var git_buf = c.git_buf{.ptr = undefined, .reserved = 0, .size = 0};
        defer c.git_buf_dispose(&git_buf);

        // discover a git repository from the given starting directory
        if (c.git_repository_discover(&git_buf, starting_path.ptr, 0, null) == 0) {
            // attempt to open the git repository
            if (c.git_repository_open(&git_repo_ptr, git_buf.ptr) == 0) {
                var path_owned: []u8 = std.heap.page_allocator.alloc(u8, git_buf.size) catch "";
                std.mem.copy(u8, path_owned, std.mem.span(git_buf.ptr));

                // return a struct with the pointer and path on success
                return GitRepository{
                    .ptr = git_repo_ptr,
                    .path = path_owned,
                };
            } else {
                git_repo_ptr = null; // ensure null
                return GitRepositoryError.OpenError;
            }
        } else {
            git_repo_ptr = null; // ensure null
            return GitRepositoryError.NoRepositoryFound;
        }
    }

    /// closes the git repository and cleans up resources
    pub fn free(self: GitRepository) void {
        if (self.ptr != null) {
            c.git_repository_free(self.ptr);
            std.heap.page_allocator.free(self.path.?);
        }
    }
};
