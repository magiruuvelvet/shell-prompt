const std = @import("std");

const c = @cImport({
    @cInclude("git2.h");
});

/// `git_tag_foreach_cb` return value to abort the iteration when a tag was found
const GIT_TAG_FOUND: c_int = 0xFD;

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

/// count of files changed in the working copy of a git repository
pub const GitRepositoryChanges = struct {
    /// number of files in the working tree which are not tracked by git yet
    untracked: u64 = 0,

    /// number of modified files in the working tree and index
    modified: u64 = 0,

    /// number of new files in the index
    new: u64 = 0,

    /// number of deleted files from the index and working tree
    deleted: u64 = 0,

    /// number of stashes found in the repository (not part of regular changes)
    stashed: u64 = 0,

    /// number of files with merge conflicts
    /// this number also includes "deleted" files with conflicts
    conflicts: u64 = 0,
};

/// a struct containing the entire git repository state
pub const GitRepositoryStatus = struct {
    /// count of files changed in the working copy of a git repository
    changes: ?GitRepositoryChanges = null,

    /// is the repository considered clean?
    /// meaning: no modified files, no deleted files
    clean: bool = false,
};

/// a struct keeping track of remote tracking branch differences
pub const GitRepositoryRemoteDifferences = struct {
    /// number of commits ahead the remote tracking branch
    /// meaning: commits which can be pushed to the remote
    commits_ahead: u64 = 0,

    /// number of commits behind the remote tracking branch
    /// meaning: commits which can be pulled from the remote
    commits_behind: u64 = 0,

    /// the repository history is diverged when it has commits ahead and behind at the same time
    /// meaning: it has commits which can be pushed and pulled, a rebase is necessary in that case
    pub fn diverged_history(self: *const GitRepositoryRemoteDifferences) bool {
        return self.commits_ahead != 0 and self.commits_behind != 0;
    }
};

/// payload for the `git_tag_foreach_cb` function
const GitTagCbPayload = struct {
    /// pointer to the git repository
    ptr: ?*c.git_repository = null,

    /// pointer to a `git_tag` object
    tag: ?*c.git_tag = null,

    /// pointer to the git object id
    oid: ?*const c.git_oid = null,

    /// copy of the git tag name without any prefixes
    out: ?[]u8 = null,
};

/// the maximum possible length of the formatted commit hash
pub const HashMaxLength = struct {
    const SHA1: usize = 40;
    const SHA256: usize = 64;
};

/// container to store the git branch name together with its source
pub const GitBranchName = struct {
    /// the source from where the name was looked up
    pub const Source = enum {
        /// an existing git branch
        Branch,
        /// a git tag (detached state and a matching tag found)
        Tag,
        /// commit hash (detached state and no matching tag found)
        Commit,
    };

    pub inline fn format(value: @This(), comptime _: []const u8, _: std.fmt.FormatOptions, writer: anytype) std.os.WriteError!void {
        return writer.print("{{name={s}, src={}}}", .{ value.name, value.src });
    }

    /// display name
    name: []const u8,

    /// source from where the name was looked up
    src: Source,
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

    /// receive the current commit hash of the repository
    /// the length of the hash can be specified in the `length` parameter
    /// the maximum possible length depends on the repository hashing type
    /// see `HashMaxLength`
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

            const hash: []u8 = std.heap.page_allocator.alloc(u8, HashMaxLength.SHA256) catch unreachable;
            if (c.git_oid_fmt(hash.ptr, oid) == 0) {
                return hash[0..length];
            }
        }

        return "";
    }

    /// receive the current branch name of the repository
    /// if the current HEAD reference doesn't point to a branch name,
    /// it returns the first 8 characters of the commit hash instead
    pub fn current_branch_name(self: *const GitRepository) ?GitBranchName {
        if (self.ref == null) {
            return null;
        }

        if (self.is_detached())
        {
            // try to find a tag name pointing to current HEAD

            // get git_oid object of the current branch
            const oid = c.git_reference_target(self.ref);
            if (oid == null) {
                return null;
            }

            // lookup the tag name
            var payload = GitTagCbPayload{
                .ptr = self.ptr,
                .oid = oid,
            };
            if (c.git_tag_foreach(self.ptr, &git_tag_foreach_cb, &payload) == GIT_TAG_FOUND) {
                // if (payload.tag != null) {
                //     defer c.git_tag_free(payload.tag);

                //     const git_tag_name = c.git_tag_name(payload.tag);

                //     var tag_name: []u8 = std.heap.page_allocator.alloc(u8, std.mem.span(git_tag_name).len) catch "";
                //     std.mem.copy(u8, tag_name, std.mem.span(git_tag_name));

                //     return tag_name;
                // } else {
                    return GitBranchName{
                        .name = payload.out.?,
                        .src = GitBranchName.Source.Tag,
                    };
                // }
            }
        }
        else
        {
            // try to find the branch name of current HEAD

            var out: [*c]const u8 = null;
            if (c.git_branch_name(&out, self.ref) == 0)
            {
                if (std.mem.span(out).len > 0)
                {
                    var branch: []u8 = std.heap.page_allocator.alloc(u8, std.mem.span(out).len) catch "";
                    std.mem.copy(u8, branch, std.mem.span(out));

                    return GitBranchName{
                        .name = branch,
                        .src = GitBranchName.Source.Branch,
                    };
                }
            }
        }

        // return the first 8 characters of the commit hash
        // when the current ref has no branch name or tag name
        return GitBranchName{
            .name = self.current_commit_hash(8),
            .src = GitBranchName.Source.Commit,
        };
    }

    /// receive the current commit count, starting from the current HEAD reference
    /// returns `null` if there were errors during counting, or when the repository doesn't
    /// have any commits yet
    pub fn count_commits(self: *const GitRepository) ?u64 {
        var walk: ?*c.git_revwalk = null;
        if (c.git_revwalk_new(&walk, self.ptr) != 0) {
            return null;
        }
        defer c.git_revwalk_free(walk);

        if (c.git_revwalk_sorting(walk, c.GIT_SORT_TOPOLOGICAL | c.GIT_SORT_TIME) != 0) {
            return null;
        }

        if (c.git_revwalk_push_head(walk) != 0) {
            return null;
        }

        var count: u64 = 0;

        var oid: c.git_oid = undefined;
        while (c.git_revwalk_next(&oid, walk) == 0) : (count += 1) {}
        return count;
    }

    /// get the status of the git repository
    pub fn get_status(self: *const GitRepository) ?GitRepositoryStatus {
        if (self.is_bare()) {
            return null;
        }

        const changes = self.count_changes();
        const clean = if (changes) |ch| blk: {
            break :blk ch.modified == 0 and ch.deleted == 0;
        } else false;

        return GitRepositoryStatus{
            .changes = changes,
            .clean = clean,
        };
    }

    /// count the number of total changes in the git repository
    pub fn count_changes(self: *const GitRepository) ?GitRepositoryChanges {
        // a bare repository can't have any changes
        if (self.is_bare()) {
            return null;
        }

        // initialize empty changes counter
        var changes = GitRepositoryChanges{};

        // process all repository changes and populate the counter
        _ = c.git_status_foreach(self.ptr, &git_status_cb, &changes);

        // process all stashes and count them too
        _ = c.git_stash_foreach(self.ptr, &git_stash_cb, &changes);

        return changes;
    }

    /// callback for the `git_status_foreach` function.
    ///
    /// C signature: `int git_status_cb(const char *path, unsigned int status_flags, void *payload);`
    /// Zig: `?*const fn ([*c]const u8, c_uint, ?*anyopaque) callconv(.C) c_int;`
    fn git_status_cb(_: [*c]const u8, status_flags: c.git_status_t, payload: ?*anyopaque) callconv(.C) c_int {
        // get readwrite pointer to GitRepositoryChanges struct
        var changes: *GitRepositoryChanges = @ptrCast(*GitRepositoryChanges,
            @alignCast(@alignOf(*GitRepositoryChanges), payload));

        // GIT_STATUS_CURRENT
        // GIT_STATUS_INDEX_NEW
        // GIT_STATUS_INDEX_MODIFIED
        // GIT_STATUS_INDEX_DELETED
        // GIT_STATUS_INDEX_RENAMED
        // GIT_STATUS_INDEX_TYPECHANGE
        // GIT_STATUS_WT_NEW
        // GIT_STATUS_WT_MODIFIED
        // GIT_STATUS_WT_DELETED
        // GIT_STATUS_WT_TYPECHANGE
        // GIT_STATUS_WT_RENAMED
        // GIT_STATUS_WT_UNREADABLE
        // GIT_STATUS_IGNORED
        // GIT_STATUS_CONFLICTED

        // new files in the index are counted as new
        if ((status_flags & c.GIT_STATUS_INDEX_NEW) > 0) {
            changes.new += 1;
        }

        // new files in the working tree are counted as untracked
        if ((status_flags & c.GIT_STATUS_WT_NEW) > 0) {
            changes.untracked += 1;
        }

        // any modified files (index or working tree) are counted as modified
        if ((status_flags & c.GIT_STATUS_INDEX_MODIFIED) > 0 or (status_flags & c.GIT_STATUS_WT_MODIFIED) > 0) {
            changes.modified += 1;
        }

        // any deleted files (index or working tree) are counted as deleted
        if ((status_flags & c.GIT_STATUS_INDEX_DELETED) > 0 or (status_flags & c.GIT_STATUS_WT_DELETED) > 0) {
            changes.deleted += 1;
        }

        // files with merge conflicts are counted separately
        if ((status_flags & c.GIT_STATUS_CONFLICTED) > 0) {
            changes.conflicts += 1;
        }

        return 0;
    }

    /// callback for the `git_stash_foreach` function.
    ///
    /// C signature: `int git_stash_cb(size_t index, const char *message, const git_oid *stash_id, void *payload);`
    /// Zig: `?*const fn (usize, [*c]const u8, [*c]const git_oid, ?*anyopaque) callconv(.C) c_int;`
    fn git_stash_cb(_: usize, _: [*c]const u8, _: [*c]const c.git_oid, payload: ?*anyopaque) callconv(.C) c_int {
        // get readwrite pointer to GitRepositoryChanges struct
        var changes: *GitRepositoryChanges = @ptrCast(*GitRepositoryChanges,
            @alignCast(@alignOf(*GitRepositoryChanges), payload));

        // visiting this function increases the stashed count, nothing to do here otherwise
        changes.stashed += 1;

        return 0;
    }

    /// callback for the `git_tag_foreach_cb` function.
    ///
    /// C signature: `int git_tag_foreach_cb(const char *name, git_oid *oid, void *payload);`
    /// Zig: `?*const fn ([*c]const u8, [*c]git_oid, ?*anyopaque) callconv(.C) c_int;`
    fn git_tag_foreach_cb(name: [*c]const u8, oid: [*c]c.git_oid, payload: ?*anyopaque) callconv(.C) c_int {
        // get readwrite pointer to GitTagCbPayload struct
        var tag_cb_payload: *GitTagCbPayload = @ptrCast(*GitTagCbPayload,
            @alignCast(@alignOf(*GitTagCbPayload), payload));

        // compare the two git_oid objects for equality
        if (c.git_oid_equal(oid, tag_cb_payload.oid) == 1) {
            // var tag: ?*c.git_tag = null;
            // if (c.git_tag_lookup(&tag, tag_cb_payload.ptr, oid) == 0) {
            //     std.debug.print("here\n", .{});
            //     tag_cb_payload.tag = tag;
            // } else {
            //     tag_cb_payload.tag = null;
            // }

            tag_cb_payload.out = std.heap.page_allocator.alloc(u8, std.mem.span(name).len) catch "";
            std.mem.copy(u8, tag_cb_payload.out.?, std.mem.span(name));

            // remove "refs/tags/" prefix
            if (std.mem.startsWith(u8, tag_cb_payload.out.?, "refs/tags/")) {
                tag_cb_payload.out = tag_cb_payload.out.?[10..];
            }

            // tag found, abort iteration
            return GIT_TAG_FOUND;
        }

        return 0;
    }

    /// receive differences between the local branch and the remote tracking branch
    /// if the current branch doesn't have a remote tracking branch, `null` is returned
    /// this function also returns `null` when the repository doesn't have any remotes at all
    pub fn get_remote_differences(self: *const GitRepository) ?GitRepositoryRemoteDifferences {
        // detached HEAD or bare doesn't have a remote tracking branch
        if (self.is_detached() or self.is_bare()) {
            return null;
        }

        // find the matching remote tracking branch for the current local branch
        var upstream_ref: ?*c.git_reference = null;
        if (c.git_branch_upstream(&upstream_ref, self.ref) != 0) {
            return null;
        }
        defer c.git_reference_free(upstream_ref);

        // get git_oid object of the current branch
        const local_oid = c.git_reference_target(self.ref);
        if (local_oid == null) {
            return null;
        }

        // get git_oid object of the remote tracking branch
        const upstream_oid = c.git_reference_target(upstream_ref);
        if (upstream_oid == null) {
            return null;
        }

        // get the difference between the local branch and the remote tracking branch
        var ahead: usize = 0;
        var behind: usize = 0;
        if (c.git_graph_ahead_behind(&ahead, &behind, self.ptr, local_oid, upstream_oid) != 0) {
            return null;
        }

        return GitRepositoryRemoteDifferences{
            .commits_ahead = ahead,
            .commits_behind = behind,
        };
    }
};
