const std = @import("std");
const os = std.os;

const c = @cImport({
    @cInclude("pwd.h");
    @cInclude("unistd.h");
});

/// cache the results of `getpwuid`
const passwd_cache = struct {
    passwd: [*c]c.struct_passwd = null,
    pw_name: []u8 = "",
    pw_gecos: []u8 = "",
    pw_dir: ?[]u8 = null,
};

/// global state cache for passwd
var cache = passwd_cache{};

/// receive the passwd entry from the current user
/// stores the result into a cache for later use
fn get_passwd() [*c]c.struct_passwd {
    if (cache.passwd == null)
    {
        cache.passwd = c.getpwuid(c.getuid());
    }

    return cache.passwd;
}

/// truncate possible trailing commas from the passwd full name entry (,)
/// not sure if this is a bug on my system, or if it has something to do
/// with UTF-8 characters (Japanese) in the name
fn truncate_garbage(str: *[]u8) void {
    if (str.*.len == 0)
    {
        return;
    }

    // scan string from right to left and find the last comma
    var pos = str.*.len - 1;
    while (pos != 0) : (pos -= 1) {
        if (str.*[pos] != ',') {
            break;
        }
    }

    // truncate the string
    str.* = str.*[0..pos+1];
}

// validate the correct behavior of the truncate_garbage function
test "truncate_garbage" {
    const testing = std.testing;

    const string = struct {
        buffer: []u8,
        allocator: std.mem.Allocator,
    };

    const helper = struct {
        /// create mutable string from literal which can be modified later
        pub fn create_string(literal: []const u8) !string {
            var buf = try std.heap.c_allocator.alloc(u8, literal.len);
            for (literal) |char, i| {
                buf[i] = char;
            }
            return string{
                .buffer = buf,
                .allocator = std.heap.c_allocator,
            };
        }
    };

    var empty_string = try helper.create_string("");
    defer empty_string.allocator.free(empty_string.buffer);
    truncate_garbage(&empty_string.buffer);
    try testing.expectEqualStrings("", empty_string.buffer);

    var ascii_string = try helper.create_string("username");
    defer ascii_string.allocator.free(ascii_string.buffer);
    truncate_garbage(&ascii_string.buffer);
    try testing.expectEqualStrings("username", ascii_string.buffer);

    var unicode_string = try helper.create_string("ユーザー名");
    defer unicode_string.allocator.free(unicode_string.buffer);
    truncate_garbage(&unicode_string.buffer);
    try testing.expectEqualStrings("ユーザー名", unicode_string.buffer);

    var unicode_string_with_trailing_comma = try helper.create_string("ユーザー名,,,");
    defer unicode_string_with_trailing_comma.allocator.free(unicode_string_with_trailing_comma.buffer);
    truncate_garbage(&unicode_string_with_trailing_comma.buffer);
    try testing.expectEqualStrings("ユーザー名", unicode_string_with_trailing_comma.buffer);
}

pub fn get_uid() u32 {
    return c.getuid();
}

pub fn get_username() []const u8 {
    const passwd = get_passwd();

    if (passwd == null) {
        return "";
    } else {
        if (cache.pw_name.len > 0) {
            return cache.pw_name;
        } else {
            cache.pw_name = std.mem.span(passwd.*.pw_name);
            return cache.pw_name;
        }
    }
}

pub fn get_user_display_name() []const u8 {
    const passwd = get_passwd();

    if (passwd == null) {
        return "";
    } else {
        if (cache.pw_gecos.len > 0) {
            return cache.pw_gecos;
        } else {
            cache.pw_gecos = std.mem.span(passwd.*.pw_gecos);
            truncate_garbage(&cache.pw_gecos);
            return cache.pw_gecos;
        }
    }
}

pub fn get_home_directory() ?[]const u8 {
    const passwd = get_passwd();

    if (passwd == null) {
        return null;
    } else {
        if (cache.pw_dir) |pw_dir| {
            return pw_dir;
        } else {
            cache.pw_dir = std.mem.span(passwd.*.pw_dir);
            return cache.pw_dir;
        }
    }
}

pub fn get_hostname() []const u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    //defer arena.deinit();

    const allocator = arena.allocator();

    if (allocator.create([os.HOST_NAME_MAX]u8)) |name_buffer| {
        const uts = os.uname();
        const hostname = std.mem.sliceTo(std.meta.assumeSentinel(&uts.nodename, 0), 0);
        std.mem.copy(u8, name_buffer, hostname);
        return name_buffer[0..hostname.len];
    } else |_| {
        return "";
    }
}
