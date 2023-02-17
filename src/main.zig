const std = @import("std");
const clap = @import("zig-clap");

const print = @import("utils/print.zig").print;
const printError = @import("utils/print.zig").err;
const Prompt = @import("prompt/prompt.zig").Prompt;

const winsize = @import("modules").term.winsize;
const git = @import("modules").git;

const params =
    \\-h, --help                     Display this help and exit.
    \\
    \\General options:
    \\  --last-exit-status <u8>        Pass the last exit status to the shell prompt.
    \\  --hostname-color <str>         Color of the system hostname.
    \\  --input-line-terminator <str>  Use a custom input line terminator instead of the default one.
    \\  --columns <u16>                The number of available columns. (overrides autodetect)
    \\  --lines <u16>                  The number of available lines. (overrides autodetect)
    \\
    \\git prompt options:
    \\  --git-prompt-disable-commit-counting   Disable counting of commits. (recommended for huge repositories)
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

    // get custom window size
    const winsize_columns: ?u16 = res.args.columns;
    const winsize_lines: ?u16 = res.args.lines;
    const winsize_override: ?winsize = if (winsize_columns != null and winsize_lines != null) blk: {
        break :blk winsize{
            .columns = winsize_columns.?,
            .lines = winsize_lines.?,
        };
    } else null;

    // initialize libgit2 for git features
    _ = git.init();
    defer _ = git.shutdown();

    // initialize prompt
    var prompt = Prompt.init(last_exit_status) catch |err| { return error_handler(err); };
    prompt.hostname_color = hostname_color;

    // set custom window size
    if (winsize_override) |w| {
        prompt.winsize = w;
    }

    // set custom input line terminator
    if (res.args.@"input-line-terminator") |custom_input_line_terminator| {
        prompt.custom_input_line_terminator = custom_input_line_terminator;
    }

    // disable git commit counting when this option is enabled
    if (res.args.@"git-prompt-disable-commit-counting") {
        prompt.git_prompt_enable_commit_counting = false;
    }

    // render prompt to screen
    prompt.render() catch |err| { return error_handler(err); };

    return 0;
}

fn error_handler(err: anyerror) u8 {
    printError("{}\n", .{err});
    return 255;
}
