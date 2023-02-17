const std = @import("std");
const os = @import("../os/os.zig");
const color = @import("../term/term.zig").color;
const eql = std.mem.eql;

const String = @import("zig-string").String;

/// `file`: the file entry to check against
/// `build_system_name`: the name of the build system
/// `display_name`: the display value of this build system
fn append_if_match(
    list: *std.ArrayList([]const u8), file: std.fs.IterableDir.Entry, build_system_name: []const u8, display_name: []const u8,
    r: u8, g: u8, b: u8, bold: bool) void
{
    // only match against entries of type "file"
    if (file.kind == .File and eql(u8, file.name, build_system_name)) {
        if (bold) {
            list.append(color.rgb_bold(display_name, r, g, b, color.mode.foreground)) catch {};
        } else {
            list.append(color.rgb(display_name, r, g, b, color.mode.foreground)) catch {};
        }
    }
}

/// `file`: the file entry to check against
/// `build_system_name`: the name of the build system
/// `display_name`: the display value of this build system
fn append_regardless(
    list: *std.ArrayList([]const u8), file: std.fs.IterableDir.Entry, build_system_name: []const u8, display_name: []const u8,
    r: u8, g: u8, b: u8, bold: bool) void
{
    // discard unused parameters
    _ = file;
    _ = build_system_name;

    if (bold) {
        list.append(color.rgb_bold(display_name, r, g, b, color.mode.foreground)) catch {};
    } else {
        list.append(color.rgb(display_name, r, g, b, color.mode.foreground)) catch {};
    }
}

/// build a pretty-printed list of build systems
/// if an entry is appended to the list is decided by the append function
fn build_list(
    list: *std.ArrayList([]const u8), files: *const []std.fs.IterableDir.Entry,
    comptime append_function: fn(*std.ArrayList([]const u8), std.fs.IterableDir.Entry, []const u8, []const u8, u8, u8, u8, bool) void) void
{
    // the order in this list kind of matters for optical reasons, so keep similar items together
    for (files.*) |file| {
        append_function(list, file, "CMakeLists.txt",   "cmake",    204, 204, 204, true); // universal build system
        append_function(list, file, "wscript",          "waf",      242, 225,   0, true); // universal build system
        append_function(list, file, "meson.build",      "meson",     57,  32, 124, true); // universal build system
        append_function(list, file, "build.gradle",     "gradle",     2,  48,  58, true); // JVM-based
        append_function(list, file, "pom.xml",          "maven",    176, 114,  25, true); // JVM-based
        append_function(list, file, "Cargo.toml",       "cargo",    222, 165, 132, true); // Rust
        append_function(list, file, "composer.json",    "composer",  79,  93, 149, true); // PHP
        append_function(list, file, "package.json",     "npm",      202, 187,  75, true); // NodeJS
        append_function(list, file, "dub.json",         "dub",      176,  57,  49, true); // D
        append_function(list, file, "build.zig",        "zig",      247, 164,  29, true); // Zig

        append_function(list, file, "setup.py",         "python",    53, 114, 165, true); // Python
        append_function(list, file, "requirements.txt", "pip",       53, 114, 165, true); // Python PIP

        append_function(list, file, "Gemfile",          "rubygems", 112,  21,  22, true); // Ruby
        append_function(list, file, "Rakefile",         "rake",     112,  21,  22, true); // Ruby

        // push duplicate to alert about an ambiguous makefile match
        append_function(list, file, "Makefile",         "makefile",  66, 120,  25, true);
        append_function(list, file, "makefile",         "makefile",  66, 120,  25, true);
        append_function(list, file, "configure",        "configure", 66, 120,  25, true);
    }
}

/// detects what build systems are present in the given directory and returns
/// a pretty-printed list of them, each build system name is separated with a vertical line
pub fn detect_build_systems(path: []const u8) []const u8 {
    const files = os.dir.get_filelist(path, std.heap.page_allocator) catch {
        return "";
    };
    defer std.heap.page_allocator.free(files);

    // return early when the list is empty
    if (files.len == 0) {
        return "";
    }

    var build_systems = String.init(std.heap.page_allocator);

    // push everything into a list to join it with a separator later
    var formatted_list = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer formatted_list.deinit();

    // execute builder and push all entries which have a match
    build_list(&formatted_list, &files, append_if_match);

    // join list together with a separator
    for (formatted_list.items) |item, i| {
        build_systems.concat(item) catch {};
        if (i < formatted_list.items.len - 1) {
            build_systems.concat("❘") catch {};
        }
    }

    return build_systems.str();
}

/// test function which ignores filesystem presence and returns all registered build systems
pub fn test_build_system_colors() []const u8 {
    var build_systems = String.init(std.heap.page_allocator);

    // push everything into a list to join it with a separator later
    var formatted_list = std.ArrayList([]const u8).init(std.heap.page_allocator);
    defer formatted_list.deinit();

    // create list with one entry; used to trigger the iteration in build_list
    var files = std.ArrayList(std.fs.IterableDir.Entry).init(std.heap.page_allocator);
    defer files.deinit();
    files.append(std.fs.IterableDir.Entry{.name = "", .kind = .File}) catch {};

    // execute builder and push all entries into the list, regardless of their existence on the filesystem
    build_list(&formatted_list, &files.items, append_regardless);

    // join list together with a separator
    for (formatted_list.items) |item, i| {
        build_systems.concat(item) catch {};
        if (i < formatted_list.items.len - 1) {
            build_systems.concat("❘") catch {};
        }
    }

    return build_systems.str();
}
