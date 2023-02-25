const std = @import("std");
const os = @import("../os/os.zig");
const color = @import("../term/term.zig").color;
const mem = std.mem;
const FileEntry = os.dir.FileEntry;

const String = @import("zig-string").String;

/// formatting and matching options for an `Entry` object
const EntryItemOptions = struct {
    sort: usize = 0,
    bold: bool = true,
    exact_match: bool = true,
    starts_with: bool = false,
    ends_with: bool = false,
};

/// formatted entry with a sorting hint
const Entry = struct {
    value: []const u8,
    sort: usize,

    pub fn lessThan(context: void, lhs: Entry, rhs: Entry) bool {
        _ = context;
        return lhs.sort < rhs.sort;
    }
};

/// list of `Entry` objects
const EntryList = std.ArrayList(Entry);

/// `file`: the file entry to check against
/// `build_system_name`: the name of the build system
/// `display_name`: the display value of this build system
fn append_if_match(
    list: *EntryList, file: *const FileEntry, duplicate_checker: *bool, build_system_names: anytype, display_name: []const u8,
    r: u8, g: u8, b: u8, options: EntryItemOptions) void
{
    // return if already added
    if (duplicate_checker.*) {
        return;
    }

    // only match against entries of type "file"
    if (file.kind != .File) {
        return;
    }

    var should_append = false;

    inline for (build_system_names) |build_system_name| {
        if (options.exact_match and mem.eql(u8, file.name, build_system_name)) {
            should_append = true;
            break;
        } else if (options.starts_with and mem.startsWith(u8, file.name, build_system_name)) {
            should_append = true;
            break;
        } else if (options.ends_with and mem.endsWith(u8, file.name, build_system_name)) {
            should_append = true;
            break;
        }
    }

    if (should_append) {
        duplicate_checker.* = true;

        if (options.bold) {
            list.append(.{
                .value = color.rgb_bold(display_name, r, g, b, color.mode.foreground),
                .sort = options.sort,
            }) catch {};
        } else {
            list.append(.{
                .value = color.rgb(display_name, r, g, b, color.mode.foreground),
                .sort = options.sort,
            }) catch {};
        }
    }
}

/// `file`: the file entry to check against
/// `build_system_name`: the name of the build system
/// `display_name`: the display value of this build system
fn append_regardless(
    list: *EntryList, file: *const FileEntry, duplicate_checker: *bool, build_system_names: anytype, display_name: []const u8,
    r: u8, g: u8, b: u8, options: EntryItemOptions) void
{
    // discard unused parameters
    _ = file;
    _ = build_system_names;
    _ = duplicate_checker;

    if (options.bold) {
        list.append(.{
            .value = color.rgb_bold(display_name, r, g, b, color.mode.foreground),
            .sort = options.sort,
        }) catch {};
    } else {
        list.append(.{
            .value = color.rgb(display_name, r, g, b, color.mode.foreground),
            .sort = options.sort,
        }) catch {};
    }
}

/// build a pretty-printed list of build systems
/// if an entry is appended to the list is decided by the append function
fn build_list(
    list: *EntryList, files: *const []FileEntry,
    comptime append_function: fn(*EntryList, *const FileEntry, duplicate_checker: *bool, anytype,
        []const u8, u8, u8, u8, EntryItemOptions) void) void
{
    // duplicate tracker variables, should be hopefully faster than checking the entire list with each iteration
    var cmake = false;
    var waf = false;
    var meson = false;
    var ninja = false;
    var build2 = false;
    var boost = false;
    var gradle = false;
    var maven = false;
    var cargo = false;
    var composer = false;
    var npm = false;
    var deno = false;
    var typescript = false;
    var dub = false;
    var zig = false;
    var crystal = false;
    var docker = false;
    var docker_compose = false;
    var python = false;
    var ruby = false;
    var makefile = false;
    var configure = false;
    var msbuild = false;
    var go = false;
    var elixir = false;

    // the order in this list kind of matters for optical reasons, so keep similar items together
    for (files.*) |*file| {
        // CMake, universal build system
        append_function(list, file, &cmake,
            .{"CMakeLists.txt"}, "cmake", 204, 204, 204, .{.sort = 100});

        // waf, universal build system
        append_function(list, file, &waf,
            .{"wscript"}, "waf", 242, 225, 0, .{.sort = 140});

        // meson, universal build system
        append_function(list, file, &meson,
            .{"meson.build"}, "meson", 57, 32, 124, .{.sort = 130});

        // Ninja
        append_function(list, file, &ninja,
            .{"build.ninja"}, "ninja", 44, 44, 44, .{.sort = 120});

        // build2, C++ build system (https://build2.org/)
        append_function(list, file, &build2,
            .{"buildfile"}, "build2", 44, 44, 44, .{.sort = 121});

        // boost build system
        append_function(list, file, &boost,
            .{"Jamroot", "Jamfile"}, "boost", 44, 44, 44, .{.sort = 122});

        // Gradle, JVM-based
        append_function(list, file, &gradle,
            .{"build.gradle"}, "gradle", 2, 48, 58, .{.sort = 400});

        // Maven, JVM-based
        append_function(list, file, &maven,
            .{"pom.xml"}, "maven", 176, 114, 25, .{.sort = 500});

        // Rust
        append_function(list, file, &cargo,
            .{"Cargo.toml"}, "cargo", 222, 165, 132, .{.sort = 600});

        // PHP
        append_function(list, file, &composer,
            .{"composer.json"}, "composer", 79, 93, 149, .{.sort = 700});

        // NodeJS
        append_function(list, file, &npm,
            .{"package.json"}, "npm", 202, 187, 75, .{.sort = 800});

        // Deno
        append_function(list, file, &deno,
            .{"deno.json", "deno.jsonc"}, "deno", 18, 18, 75, .{.sort = 810});

        // TypeScript
        append_function(list, file, &typescript,
            .{"tsconfig.json"}, "typescript", 49, 120, 198, .{.sort = 900});

        // D
        append_function(list, file, &dub,
            .{"dub.json", "dub.sdl"}, "dub", 176, 57, 49, .{.sort = 1000});

        // Zig
        append_function(list, file, &zig,
            .{"build.zig"}, "zig", 247, 164, 29, .{.sort = 1100});

        // Crystal
        append_function(list, file, &crystal,
            .{"shard.yml"}, "crystal", 0, 1, 0, .{.sort = 1150});

        // Docker
        append_function(list, file, &docker,
            .{"Dockerfile"},         "docker",  13, 183, 237, .{.sort = 20});
        append_function(list, file, &docker_compose,
            .{"docker-compose.yml"}, "compose", 13, 183, 237, .{.sort = 21});

        // Python
        append_function(list, file, &python,
            .{"setup.py", "requirements.txt"}, "python", 53, 114, 165, .{.sort = 1400});

        // Ruby
        append_function(list, file, &ruby,
            .{"Gemfile", "Rakefile"}, "ruby", 112, 21, 22, .{.sort = 1500});

        // makefile, configure
        append_function(list, file, &makefile,
            .{"Makefile", "makefile"}, "makefile",  66, 120, 25, .{.sort = 190});
        append_function(list, file, &configure,
            .{"configure"},            "configure", 66, 120, 25, .{.sort = 191});

        // MSBuild
        append_function(list, file, &msbuild,
            .{".sln"}, "msbuild", 56, 145, 223, .{.ends_with = true, .sort = 110});

        // Go
        append_function(list, file, &go,
            .{"go.mod", "go.sum", "go.work"}, "go", 0, 125, 156, .{.sort = 1800});

        // Elixir
        append_function(list, file, &elixir,
            .{"mix.exs"}, "elixir", 85, 55, 100, .{.sort = 1900});
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
    var formatted_list = EntryList.init(std.heap.page_allocator);
    defer formatted_list.deinit();

    // execute builder and push all entries which have a match
    build_list(&formatted_list, &files, append_if_match);

    // sort the list according to the sorting hints
    std.sort.sort(Entry, formatted_list.items, {}, Entry.lessThan);

    // join list together with a separator
    for (formatted_list.items) |item, i| {
        build_systems.concat(item.value) catch {};
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
    var formatted_list = EntryList.init(std.heap.page_allocator);
    defer formatted_list.deinit();

    // create list with one entry; used to trigger the iteration in build_list
    var files = std.ArrayList(FileEntry).init(std.heap.page_allocator);
    defer files.deinit();
    files.append(FileEntry{.name = "", .kind = .File}) catch {};

    // execute builder and push all entries into the list, regardless of their existence on the filesystem
    build_list(&formatted_list, &files.items, append_regardless);

    // sort the list according to the sorting hints
    std.sort.sort(Entry, formatted_list.items, {}, Entry.lessThan);

    // join list together with a separator
    for (formatted_list.items) |item, i| {
        build_systems.concat(item.value) catch {};
        if (i < formatted_list.items.len - 1) {
            build_systems.concat("❘") catch {};
        }
    }

    return build_systems.str();
}
