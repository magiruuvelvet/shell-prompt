const std = @import("std");
const clap = @import("zig-clap");

const print = @import("utils/print.zig").print;
const Prompt = @import("prompt/prompt.zig").Prompt;

const winsize = @import("modules").term.winsize;

const params =
    \\-h, --help                   Display this help and exit.
    \\--last-exit-status <u8>      Pass the last exit status to the shell prompt.
    \\--hostname-color <str>       Color of the system hostname.
    \\--columns <u16>              The number of available columns. (overrides autodetect)
    \\--lines <u16>                The number of available lines. (overrides autodetect)
;

pub fn main() u8 {
    // Specify what parameters the application can take.
    const cmd_params = comptime clap.parseParamsComptime(params);

    // const parsers = comptime .{
    //     .str = clap.parsers.string,
    //     .u8 = clap.parsers.int(u8, 0),
    // };

    // Initialize our diagnostics, which can be used for reporting useful errors.
    // This is optional. You can also pass `.{}` to `clap.parse` if you don't
    // care about the extra information `Diagnostics` provides.
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &cmd_params, clap.parsers.default, .{
        .diagnostic = &diag,
    }) catch |err| {
        // Report useful error and exit
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return 1;
    };
    defer res.deinit();

    // print help and exit
    if (res.args.help)
    {
        print("{s}\n", .{params});
        //clap.usage(std.io.getStdOut().writer(), clap.Help, &cmd_params) catch unreachable;
        return 0;
    }

    const last_exit_status: u8 = res.args.@"last-exit-status" orelse 0;
    const hostname_color: ?[]const u8 = res.args.@"hostname-color";

    const winsize_columns: ?u16 = res.args.columns;
    const winsize_lines: ?u16 = res.args.lines;
    const winsize_override: ?winsize = if (winsize_columns != null and winsize_lines != null) blk: {
        break :blk winsize{
            .columns = winsize_columns.?,
            .lines = winsize_lines.?,
        };
    } else null;

    var prompt = Prompt.init(last_exit_status);
    prompt.hostname_color = hostname_color;
    if (winsize_override) |w| {
        prompt.winsize = w;
    }
    prompt.render() catch |err| {
        print("{}\n", .{err});
        return 255;
    };

    return 0;
}
