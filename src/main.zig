const std = @import("std");
const clap = @import("clap");

const print = @import("utils/print.zig").print;

const params =
    \\-h, --help                   Display this help and exit.
    \\--last-exit-status <u8>      Pass the last exit status to the shell prompt.
;

pub fn main() u8 {
    // Specify what parameters the application can take.
    const cmd_params = comptime clap.parseParamsComptime(params);

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

    if (res.args.@"last-exit-status") |last_exit_status| {
        print("last_exit_status: {}\n", .{last_exit_status});
    }

    return 0;
}
