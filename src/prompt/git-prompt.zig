const std = @import("std");
const modules = @import("modules");
const Prompt = @import("prompt.zig").Prompt;
const format = @import("utils").format.format;
const color = modules.term.color;
const wcwidth_ascii = modules.term.wcwidth_ascii;
const GitRepository = modules.git.GitRepository;
const GitBranchName = modules.git.GitBranchName;
const GitRepositoryStatus = modules.git.GitRepositoryStatus;
const GitRepositoryChanges = modules.git.GitRepositoryChanges;

pub const GitPromptOptions = struct {
    show_commit_count: bool = true,
};

/// `char` == the character which represents this changeset
/// `val`  == the value of the changeset
/// the remaining parameters are the RGB color code
///
/// NOTE: the trailing whitespace here is intentional
///
/// returns an empty string when the changeset is empty
fn render_changeset(char: []const u8, val: u64, r: u8, g: u8, b: u8) []const u8 {
    if (val > 0) {
        return format("{s}{s}{s}{s}{s}[{}]{s} ", .{
            color.ascii.bold,
            color.rgb_ascii(r, g, b, color.mode.foreground),
            char,
            color.ascii.normal,
            color.rgb_ascii(r, g, b, color.mode.foreground),
            val,
            color.ascii.normal,
        });
    } else {
        return "";
    }
}

pub fn render_git_prompt_component(_: *const Prompt, git: *const GitRepository, options: GitPromptOptions) ![] const u8 {
    // skip this entire function when the git repository is empty
    if (git.is_empty())
    {
        return format("{s}{s}{s}", .{
            color.rgb_ascii(145, 145, 145, color.mode.foreground),
            "[empty git repository]",
            color.ascii.normal});
    }

    const branch = git.current_branch_name();

    // determine what icon to use for the branch name
    const branch_icon = blk: {
        if (git.is_detached()) {
            break :blk "\u{e728}";
        } else {
            break :blk "\u{e725}";
        }
    };

    // determine what color to use for the branch name
    const branch_color = blk: {
        if (git.is_detached()) {
            break :blk format("{s}{s}", .{color.ascii.italic, color.rgb_ascii(34, 130, 181, color.mode.foreground)});
        } else {
            break :blk color.rgb_ascii(181, 32, 181, color.mode.foreground);
        }
    };

    // total commit count in the current branch, or "U" when counting is disabled
    // the "U" stands for unspecified or unknown commit count
    // commit counting is very slow in huge repositories
    const commit_count = format("{s}\u{f417}{s}{s}", .{
        color.rgb_ascii(174, 129, 174, color.mode.foreground),
        if (options.show_commit_count) blk: {
            break :blk format("{}", .{git.count_commits().?});
        } else blk: {
            break :blk "U";
        },
        color.ascii.normal,
    });

    // get basic details about the git repository
    const git_status = git.get_status() orelse GitRepositoryStatus{
        .changes = GitRepositoryChanges{},
    };
    // get changes between the working copy and the index
    const git_changes = git_status.changes orelse GitRepositoryChanges{};

    // print remote branch difference when the current branch has a remote tracking branch
    const remote_diff = if (git.get_remote_differences()) |git_remote_differences| blk: {
        break :blk format("{s}|{s}{s}{s}{}{s}{s}{s}{s}{s}{}{s}{s}{s}{s}", .{
            color.ascii.bold,
            color.ascii.normal,

            // pushable commits
            color.rgb_ascii(25, 134, 29, color.mode.foreground),
            color.rgb_ascii(242, 255, 243, color.mode.background),
            git_remote_differences.commits_ahead,
            color.ascii.bold,
            "⬆ ",
            color.ascii.normal,

            // pullable commits
            color.rgb_ascii(57, 142, 167, color.mode.foreground),
            color.rgb_ascii(246, 251, 253, color.mode.background),
            git_remote_differences.commits_behind,
            color.ascii.bold,
            "⬇ ",
            color.ascii.normal,

            // check if the local branch and remote branch have a different history
            if (git_remote_differences.diverged_history()) remote_diff_blk: {
                break :remote_diff_blk format("{s}{s}{s}〜{s}", .{
                    color.ascii.bold,
                    color.rgb_ascii(232, 0, 3, color.mode.foreground),
                    color.rgb_ascii(253, 243, 243, color.mode.background),
                    color.ascii.normal,
                });
            } else remote_diff_blk: {
                break :remote_diff_blk "";
            },
        });
    } else blk: {
        break :blk "";
    };

    // format the git prompt component
    return format(
        "{s}{s} {s}{s} ({s}{s}{s}) {s}[{s}{s}{s}{s}]{s} {s}{s}{s}{s}{s}{s}{s}", .{
            branch_color,
            branch_icon,

            branch.?.name,
            color.ascii.normal,

            // print the current commit hash
            color.rgb_ascii(127, 127, 50, color.mode.foreground),
            git.current_commit_hash(8),
            color.ascii.normal,

            // print commit count and remote branch differences
            color.ascii.bold,
            color.ascii.normal,
            commit_count,
            remote_diff,
            color.ascii.bold,
            color.ascii.normal,

            if (git_status.clean) blk_status: {
                // NOTE: the trailing whitespace here is intentional
                break :blk_status format("{s}{s}\u{f00c}{s} ", .{
                    color.ascii.bold,
                    color.rgb_ascii(8, 127, 0, color.mode.foreground),
                    color.ascii.normal,
                });
            } else blk_status: {
                break :blk_status "";
            },

            render_changeset("~",        git_changes.conflicts, 199,  37,  40),
            render_changeset("m",        git_changes.modified,  184, 147,  84),
            render_changeset("n",        git_changes.new,        59, 170,  47),
            render_changeset("d",        git_changes.deleted,   206,   0,   0),
            render_changeset("\u{f457}", git_changes.untracked,  77, 155, 232),
            render_changeset("\u{f475}", git_changes.stashed,    61, 126, 186),
        });
}

pub fn render_git_prompt_message(_: *const Prompt, git: *const GitRepository, _max_possible_length: u16) ![] const u8 {
    const message = git.get_commit_message();
    const message_length = wcwidth_ascii(message);

    // take the required spacing for the icon into account
    var max_possible_length = _max_possible_length - 2;

    // truncate the message if it's longer than max_possible_length
    const suffix = if (message_length > max_possible_length) blk: {
        max_possible_length -= 1;
        break :blk "…";
    } else blk: {
        max_possible_length = @intCast(u16, message_length);
        break :blk "";
    };

    return format("{s}{s}\u{f02b}{s} {s}", .{
        color.ascii.bold,
        color.rgb_ascii(69, 105, 158, color.mode.foreground),
        color.ascii.normal,

        if (message_length > 0) blk: {
            break :blk format("{s}{s}{s}{s}", .{
                color.rgb_ascii(49, 49, 49, color.mode.foreground),
                message[0..max_possible_length], suffix,
                color.ascii.normal,
            });
        } else blk: {
            break :blk format("{s}{s}(コミットメッセージなし){s}", .{
                color.ascii.italic,
                color.rgb_ascii(202, 202, 202, color.mode.foreground),
                color.ascii.normal,
            });
        },
    });
}
