const std = @import("std");
const modules = @import("modules");
const renderer = @import("renderer.zig");
const Prompt = @import("prompt.zig").Prompt;
const format = @import("utils").format.format;
const color = modules.term.color;
const wcwidth_ascii = modules.term.wcwidth_ascii;
const GitRepository = modules.git.GitRepository;
const GitBranchName = modules.git.GitBranchName;

pub fn render_git_prompt_component(_: *const Prompt, git: *const GitRepository) ![] const u8 {
    if (git.is_empty())
    {
        return format("{s}{s}{s}", .{
            color.rgb_ascii(145, 145, 145, color.mode.foreground),
            "[empty git repository]",
            color.ascii.normal});
    }

    const branch = git.current_branch_name();

    const branch_icon = blk: {
        if (git.is_detached()) {
            break :blk "\u{e728}";
        } else {
            break :blk "\u{e725}";
        }
    };

    const branch_color = blk: {
        if (git.is_detached()) {
            break :blk format("{s}{s}", .{color.ascii.italic, color.rgb_ascii(34, 130, 181, color.mode.foreground)});
        } else {
            break :blk color.rgb_ascii(181, 32, 181, color.mode.foreground);
        }
    };

    // format the git prompt component
    return format(
        "{s}{s} {s}{s} ({s}{s}{s}) ", .{
            branch_color,
            branch_icon,
            branch.?.name,
            color.ascii.normal,
            color.rgb_ascii(127, 127, 50, color.mode.foreground),
            git.current_commit_hash(8),
            color.ascii.normal});
}

pub fn render_git_prompt_message(_: *const Prompt, git: *const GitRepository) ![] const u8 {
    _ = git;
    return "";
}
