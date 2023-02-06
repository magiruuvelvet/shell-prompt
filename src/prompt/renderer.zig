const std = @import("std");
const modules = @import("modules");
const print = @import("utils").print;

const wcwidth_ascii = modules.term.wcwidth_ascii;

/// draws a line to the terminal with the given length and flushes the output
/// the character which should be drawn can be specified
/// the width of the character is taken into consideration
/// returns the occupied terminal columns
///
/// if the given character is a wide character and the requested length is exceeded,
/// the last occurence of the character will not be printed, in which case the returned
/// column counter doesn't match the requested length
pub fn draw_line(char: []const u8, length: u16) u16 {
    // get width of character to draw
    const char_width = wcwidth_ascii(char);

    var i: u16 = 0;

    if (char_width > 0)
    {
        const char_width_unsigned = @intCast(u16, char_width);
        while (i < length) : (i += char_width_unsigned)
        {
            if (i + char_width_unsigned > length)
            {
                break;
            }

            print.write_no_flush(char);
        }

        // flush when we are done
        print.flush();
    }

    return i;
}

/// prints a new line to the terminal and flushes the output
pub fn new_line() void {
    print.write_and_flush("\n");
}

/// draws the given text to the terminal and flushes the output
/// returns the occupied terminal columns
/// this function doesn't support new lines, use `new_line()` instead
pub fn draw_text(text: []const u8) u16 {
    const width = wcwidth_ascii(text);

    if (width > 0)
    {
        print.write_and_flush(text);
        return @intCast(u16, width);
    }

    return 0;
}

/// draws the given text to the terminal and flushes the output
/// using this function doesn't invoke `wcwidth_ascii()`
///
/// use this function when:
///  - the width is already known to avoid duplicate calculations
///  - the width isn't relevant
pub fn draw_text_with_known_width(text: []const u8) void {
    print.write_and_flush(text);
}
