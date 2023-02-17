const std = @import("std");
const modules = @import("modules");
const Prompt = @import("prompt.zig").Prompt;
const format = @import("utils").format.format;
const color = modules.term.color;

pub fn render_ssh_directory_component(_: *const Prompt) []const u8 {
    return format("{s}", .{
        color.rgb("[SSH] generate new key: 'ssh-keygen -f name -t rsa -b 4096'", 40, 40, 40, color.mode.foreground),
    });
}
