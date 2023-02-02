const std = @import("std");
const winsize = @import("../winsize.zig").winsize;

const linux = std.os.linux;
const ioctl = linux.ioctl;
const ioctl_winsize_t = linux.winsize;

// for TIOCGWINSZ (0x5413)
// const c = @cImport({
//     @cInclude("sys/ioctl.h");
// });

const TIOCGWINSZ: usize = 0x5413;

// credits: https://github.com/shurizzle/zig-ioctl/blob/master/src/main.zig
// inline fn _cast(arg: anytype) usize {
//     const T = @TypeOf(arg);

//     return switch (@typeInfo(T)) {
//         .Pointer => |typ| if (switch (@typeInfo(typ.child)) {
//             .Int, .ComptimeInt => true,
//             .Struct => |s| s.layout == .Extern,
//             .Union => |u| u.layout == .Extern,
//             .Enum => |e| e.layout == .Extern,
//             else => false,
//         })
//             @ptrToInt(arg)
//         else
//             @compileError("Argument must me a pointer to an integer or an " ++
//                 "extern struct"),
//         .Int => if (@sizeOf(T) == @sizeOf(usize))
//             @bitCast(usize, arg)
//         else if (@sizeOf(T) < @sizeOf(usize))
//             @as(usize, arg)
//         else
//             @compileError("Invalid integer"),
//         else => @compileError("Invalid type"),
//     };
// }

pub fn get_winsize() winsize {
    // initialize empty ioctl winsize struct
    var ioctl_winsize = ioctl_winsize_t{
        .ws_col = 0,
        .ws_row = 0,
        .ws_xpixel = 0,
        .ws_ypixel = 0,
    };

    // get the terminal window size
    const result = ioctl(linux.STDOUT_FILENO, TIOCGWINSZ, @ptrToInt(&ioctl_winsize));

    // failed to get the window size from ioctl
    if (result != 0)
    {
        return winsize{};
    }

    // convert to unified winsize struct
    return winsize{
        .columns = ioctl_winsize.ws_col,
        .lines = ioctl_winsize.ws_row,
    };
}
