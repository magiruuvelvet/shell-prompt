const std = @import("std");
const fmt = std.fmt;

pub const ascii = struct {
    pub const normal  = "\x1b[0m"; // reset all formatting
    pub const bold    = "\x1b[1m"; // bold text
    pub const italic  = "\x1b[3m"; // italic text
};

pub const mode = enum(u1) {
    foreground = 0,
    background = 1,
};

// pub const chain = struct {
//     buf: []u8,
//     allocator: std.mem.Allocator,

//     pub fn init() chain {
//         return chain{
//             .buf = "",
//             .allocator = std.heap.page_allocator,
//         };
//     }

//     pub inline fn to_string(self: chain) []const u8 {
//         return self.buf;
//     }

//     pub inline fn text(self: chain, str: []const u8) chain {
//         self.buf = std.mem.concat(self.allocator, u8, &[_][]u8{self.buf, str}) catch self.buf;
//         return self;
//     }

//     pub inline fn normal(self: chain) chain {
//         self.buf = std.mem.concat(self.allocator, u8, &[_][]u8{self.buf, ascii.normal}) catch self.buf;
//         return self;
//     }

//     pub inline fn bold(self: chain) chain {
//         self.buf = std.mem.concat(self.allocator, u8, &[_][]u8{self.buf, ascii.bold}) catch self.buf;
//         return self;
//     }

//     pub inline fn italic(self: chain) chain {
//         self.buf = std.mem.concat(self.allocator, u8, &[_][]u8{self.buf, ascii.italic}) catch self.buf;
//         return self;
//     }

//     pub inline fn rgb_fg(self: chain, r: u8, g: u8, b: u8) chain {
//         self.buf = std.mem.concat(self.allocator, u8, &[_][]u8{
//             self.buf, rgb(r, g, b, mode.foreground),
//         }) catch self.buf;
//         return self;
//     }
// };

inline fn rgb_ascii(r: u8, g: u8, b: u8, comptime m: mode) []const u8 {
    return switch(m) {
        .foreground => return fmt.allocPrint(std.heap.page_allocator, "\x1b[38;2;{};{};{}m", .{r, g, b}) catch "",
        .background => return fmt.allocPrint(std.heap.page_allocator, "\x1b[48;2;{};{};{}m", .{r, g, b}) catch "",
    };
}

pub inline fn rgb(text: []const u8, r: u8, g: u8, b: u8, comptime m: mode) []const u8 {
    return fmt.allocPrint(std.heap.page_allocator,
        "{s}{s}{s}", .{rgb_ascii(r, g, b, m), text, ascii.normal}) catch text;
}

pub inline fn rgb_bold(text: []const u8, r: u8, g: u8, b: u8, comptime m: mode) []const u8 {
    return fmt.allocPrint(std.heap.page_allocator,
        "{s}{s}{s}{s}", .{ascii.bold, rgb_ascii(r, g, b, m), text, ascii.normal}) catch text;
}

pub inline fn rgb_italic(text: []const u8, r: u8, g: u8, b: u8, comptime m: mode) []const u8 {
    return fmt.allocPrint(std.heap.page_allocator,
        "{s}{s}{s}{s}", .{ascii.italic, rgb_ascii(r, g, b, m), text, ascii.normal}) catch text;
}

pub inline fn bold(text: []const u8) []const u8 {
    return fmt.allocPrint(std.heap.page_allocator,
        "{s}{s}{s}", .{ascii.bold, text, ascii.normal}) catch text;
}

pub inline fn italic(text: []const u8) []const u8 {
    return fmt.allocPrint(std.heap.page_allocator,
        "{s}{s}{s}", .{ascii.italic, text, ascii.normal}) catch text;
}
