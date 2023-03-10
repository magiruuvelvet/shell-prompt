//! a small command line utility to test the correctness of the git module.
//! this application is supposed to be executed in different git repositories
//! to collect the results of the git module and print them to stdout.

const std = @import("std");
const clap = @import("zig-clap");
const print = @import("utils").print.print;
const printError = @import("utils").print.err;
const git = @import("modules").git;

const params =
    \\-h, --help                   Display this help and exit.
    \\--git-repo-path <str>        Path to a git repository. (defaults to the current working directory)
;

pub fn main() u8 {
    const cmd_params = comptime clap.parseParamsComptime(params);

    // command line arguments
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
        return 0;
    }

    // get the path to the git repository to analyze
    const git_repo_path: []const u8 = res.args.@"git-repo-path" orelse ".";

    // initialize libgit2
    if (git.init() == false) {
        printError("Failed to initialize libgit2!\n", .{});
        return 1;
    }
    defer _ = git.shutdown();

    // discover git repository
    var repo = git.GitRepository.discover(git_repo_path) catch |err| {
        switch (err)
        {
            git.GitRepositoryError.NoRepositoryFound => {
                printError("{s}: no git repository found!\n", .{git_repo_path});
            },
            git.GitRepositoryError.OpenError => {
                printError("{s}: unable to open git repository!\n", .{git_repo_path});
            },
        }

        return 1;
    };
    defer repo.free();

    print("git.path:                    {s}\n", .{repo.path.?});
    print("git.is_empty:                {}\n", .{repo.is_empty()});
    print("git.is_bare:                 {}\n", .{repo.is_bare()});
    print("git.is_detached:             {}\n", .{repo.is_detached()});
    print("git.current_commit_hash:     {s}\n", .{repo.current_commit_hash(8)});
    print("git.current_branch_name:     {?}\n", .{repo.current_branch_name()});
    print("git.count_commits:           {?}\n", .{repo.count_commits()});

    if (repo.get_status()) |status| {
        print("git.clean:                   {}\n", .{status.clean});

        if (status.changes) |changes| {
            print("git.changes.untracked:       {}\n", .{changes.untracked});
            print("git.changes.modified:        {}\n", .{changes.modified});
            print("git.changes.new:             {}\n", .{changes.new});
            print("git.changes.deleted:         {}\n", .{changes.deleted});
            print("git.changes.stashed:         {}\n", .{changes.stashed});
            print("git.changes.conflicts:       {}\n", .{changes.conflicts});
        }
    } else {
        print("git.status:                  null\n", .{});
    }

    if (repo.get_remote_differences()) |diff| {
        print("git.remote_differences.commits_ahead:    {}\n", .{diff.commits_ahead});
        print("git.remote_differences.commits_behind:   {}\n", .{diff.commits_behind});
        print("git.remote_differences.diverged_history: {}\n", .{diff.diverged_history()});
    } else {
        print("git.remote_differences:      null\n", .{});
    }

    print("git.commit_message: {s}\n", .{repo.get_commit_message()});

    return 0;
}
