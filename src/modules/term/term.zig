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
    return wcwidth(filter_ascii_escape_sequences(str));
}

/// filters ASCII escape sequences from the given string
pub fn filter_ascii_escape_sequences(str: []const u8) error{InvalidEscapeSequenceFound,InvalidUtf8,OutOfMemory}![]const u8 {
    const allocator = std.heap.page_allocator;

    const memory = try allocator.alloc(u8, str.len);
    //defer allocator.free(memory);

    var i: usize = 0;
    var pos: usize = 0;
    var in_sequence: bool = false;
    while (i < str.len) : (i += 1) {
        // check if the current character is an ESC character
        if (str[pos] == "\x1b"[0])
        {
            in_sequence = true;
        }

        // find end of ESC sequence character (m)
        if (in_sequence)
        {
            if (std.mem.indexOf(u8, str[pos..], "m")) |end| {
                pos += end + 1;
                in_sequence = false;
            } else {
                // found start, but no end [abort and return error]
                return error.InvalidEscapeSequenceFound;
            }
        }

        memory[i] = str[pos];
        pos += 1;

        if (pos >= str.len)
        {
            break;
        }
    }

    return memory[0..i+1];
}
