const std = @import("std");
const fs = std.fs;
const get_home_directory = @import("os.zig").get_home_directory;

pub const DirStats = struct {
    /// visible files (no dot prefix)
    visible: u64 = 0,

    /// hidden .dotfiles
    hidden: u64 = 0,
};

/// counts the number of visible and hidden files in a directory
pub fn get_directory_stats(path: []const u8) fs.File.OpenError!DirStats {
    // open iteratable directory
    var dir = fs.openIterableDirAbsolute(path, .{}) catch |err| {
        return err;
    };

    // close directory when done
    defer dir.close();

    // get directory iterator
    var dirIterator = dir.iterate();

    var stats = DirStats{};

    // count all visible and hidden files in the directory
    var file = try dirIterator.next();
    while (file != null) : (file = try dirIterator.next()) {
        if (file) |f| {
            if (f.name.len > 0 and f.name[0] == '.') {
                stats.hidden += 1;
            } else {
                stats.visible += 1;
            }
        }
    }

    return stats;
}

/// get the process working directory
pub fn get_pwd() std.os.GetCwdError![]const u8 {
    // need to implement this wrapper around std.os.getcwd(),
    // otherwise valgrind shows invalid memory read errors

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();

    if (allocator.create([std.fs.MAX_PATH_BYTES]u8)) |pwd_buffer| {
        return std.os.getcwd(pwd_buffer);
    } else |_| {
        return std.os.GetCwdError.Unexpected;
    }
}

/// get the process working directory
/// with the user's home directory replaced with a tilde (~) symbol
pub fn get_pwd_home_tilde() std.os.GetCwdError![]const u8 {
    const pwd = try get_pwd();
    const home_dir = get_home_directory();

    if (home_dir) |home| {
        if (std.mem.startsWith(u8, pwd, home)) {
            return std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{"~", pwd[home.len..]}) catch {
                return pwd;
            };
        } else {
            return pwd;
        }
    } else {
        return pwd;
    }
}
