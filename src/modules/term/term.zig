const std = @import("std");
const unicode = std.unicode;
const builtin = @import("builtin");

pub const winsize = @import("winsize.zig").winsize;
pub const color = @import("color.zig");

/// platform-specific implementations
const impl = switch (builtin.target.os.tag) {
    .linux => @import("platform/linux.zig"),
    else => @compileError("unsupported platform"),
};

/// for `mk_wcwidth(ucs)`
/// see `wcwidth/wcwidth.c`
const c = @cImport({
    @cInclude("wcwidth.h");
});

/// get the terminal window size
pub fn get_winsize() winsize {
    return impl.get_winsize();
}

/// get the total required width of the given character sequence
/// input must be UTF-8 encoded
///
/// on success: returns the total required width of the character sequence
/// on UTF-8 failure: returns -255
/// on `wcwidth` failure: returns -1
pub fn wcwidth(str: []const u8) i32 {
    var width: i32 = 0;

    // initialize a UTF-8 view on the given character sequence
    var utf8: unicode.Utf8Iterator = undefined;
    if (unicode.Utf8View.init(str)) |utf8view| {
        utf8 = utf8view.iterator();
    } else |_| {
        // on UTF-8 errors, return -255
        return -0xFF;
    }

    // count the width of each character
    while (utf8.nextCodepoint()) |codepoint| {
        const wcw = c.mk_wcwidth(codepoint);
        if (wcw < 0) return -1;
        width += wcw;
    }

    return width;
}

/// get the total required width of the given character sequence
/// input must be UTF-8 encoded
///
/// this function supports ASCII escape sequences in the input string
///
/// on success: returns the total required width of the character sequence
/// on UTF-8 failure: returns -255
/// on `wcwidth` failure: returns -1
pub fn wcwidth_ascii(str: []const u8) i32 {
    return wcwidth(filter_ascii_escape_sequences(str) catch str);
}

pub const FilterAsciiEscapeSequenceError = error {
    // invalid data in string
    InvalidEscapeSequenceFound,
    InvalidUtf8,

    // string memory allocation
    OutOfMemory,
    InvalidRange,
};

/// filters ASCII escape sequences from the given string
/// input must be UTF-8 encoded
pub fn filter_ascii_escape_sequences(str: []const u8) FilterAsciiEscapeSequenceError![]const u8 {
    const String = @import("zig-string").String;

    // allocate enough memory for the filtered string
    var filtered = String.init(std.heap.page_allocator);
    try filtered.allocate(str.len);

    // initialize a UTF-8 view on the given character sequence
    var utf8: unicode.Utf8Iterator = undefined;
    if (unicode.Utf8View.init(str)) |utf8view| {
        utf8 = utf8view.iterator();
    } else |_| {
        // on UTF-8 errors, return
        return error.InvalidUtf8;
    }

    // tracker variable to check if we are inside an ESC sequence
    var in_sequence: bool = false;

    // process each UTF-8 character individually
    while (utf8.nextCodepointSlice()) |codepoint| {
        // check if the current character is an ESC character
        if (std.mem.eql(u8, codepoint, "\x1b"))
        {
            in_sequence = true;
        }

        // find end of ESC sequence character (m)
        if (in_sequence)
        {
            // code back here until we find the end of the sequence
            if (std.mem.eql(u8, codepoint, "m"))
            {
                // found end; allow appending characters to the filtered string again
                in_sequence = false;
                continue;
            }
            else
            {
                // ignore this character
                continue;
            }
        }

        // append visible characters to the filtered string
        try filtered.concat(codepoint);
    }

    // truncate the filtered string to the actual content
    try filtered.truncate();
    return filtered.buffer.?;
}
