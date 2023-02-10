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

    /// raw pointer to the current HEAD reference of the repository
    ref: ?*c.git_reference = null,

    /// absolute path to the discovered git repository
    /// can be different from the given `starting_path`
    path: ?[]const u8 = null,

    /// discovers a git repository in the given starting directory
    pub fn discover(starting_path: []const u8) GitRepositoryError!GitRepository {
        var git_repo_ptr: ?*c.git_repository = null;
        var git_repo_ref: ?*c.git_reference = null;

        // allocate git_buf and dispose it automatically when we're done
        var git_buf = c.git_buf{.ptr = undefined, .reserved = 0, .size = 0};
        defer c.git_buf_dispose(&git_buf);

        // discover a git repository from the given starting directory
        if (c.git_repository_discover(&git_buf, starting_path.ptr, 0, null) == 0) {
            // attempt to open the git repository
            if (c.git_repository_open(&git_repo_ptr, git_buf.ptr) == 0) {
                var path_owned: []u8 = std.heap.page_allocator.alloc(u8, git_buf.size) catch "";
                std.mem.copy(u8, path_owned, std.mem.span(git_buf.ptr));

                // Retrieve and resolve the reference pointed at by HEAD.
                //
                // returns: int
                //   0 on success,
                //   GIT_EUNBORNBRANCH when HEAD points to a non existing branch,
                //   GIT_ENOTFOUND when HEAD is missing;
                //   an error code otherwise
                const status = c.git_repository_head(&git_repo_ref, git_repo_ptr);
                if (!(status == 0 or status == c.GIT_EUNBORNBRANCH or status == c.GIT_ENOTFOUND))
                {
                    c.git_reference_free(git_repo_ref);
                    git_repo_ref = null;
                }

                // return a struct with the pointer and path on success
                return GitRepository{
                    .ptr = git_repo_ptr,
                    .ref = git_repo_ref,
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
    pub fn free(self: *GitRepository) void {
        if (self.ref != null) {
            c.git_reference_free(self.ref);
            self.ref = null;
        }
        if (self.ptr != null) {
            c.git_repository_free(self.ptr);
            std.heap.page_allocator.free(self.path.?);
            self.ptr = null;
        }
    }

    /// check if the repository is empty
    pub fn is_empty(self: *const GitRepository) bool {
        return c.git_repository_is_empty(self.ptr) == 1;
    }

    /// check if the repository is bare
    pub fn is_bare(self: *const GitRepository) bool {
        return c.git_repository_is_bare(self.ptr) == 1;
    }

    /// check if the repository is in detached HEAD state
    pub fn is_detached(self: *const GitRepository) bool {
        return c.git_repository_head_detached(self.ptr) == 1;
    }

    pub fn current_commit_hash(self: *const GitRepository, length: usize) []const u8 {
        if (self.ref == null) {
            return "";
        }

        if (c.git_reference_type(self.ref) == c.GIT_REFERENCE_DIRECT)
        {
            const oid = c.git_reference_target(self.ref);
            if (oid == null) {
                return "";
            }

            const hash: []u8 = std.heap.page_allocator.alloc(u8, 64) catch unreachable;
            if (c.git_oid_fmt(hash.ptr, oid) == 0) {
                return hash[0..length];
            }
        }

        return "";
    }

    pub fn current_branch_name(self: *const GitRepository) []const u8 {
        if (self.ref == null) {
            return "";
        }

        var out: [*c]const u8 = null;
        if (c.git_branch_name(&out, self.ref) == 0)
        {
            if (std.mem.span(out).len > 0)
            {
                var branch: []u8 = std.heap.page_allocator.alloc(u8, std.mem.span(out).len) catch "";
                std.mem.copy(u8, branch, std.mem.span(out));

                return branch;
            }
        }

        return self.current_commit_hash(8);
    }
};
