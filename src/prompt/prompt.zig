const std = @import("std");
const renderer = @import("renderer.zig");
const winsize = @import("modules").term.winsize;

const Prompt = struct {
    winsize: winsize,
    last_exit_status: u8 = 0,

    pub fn init(window_size: winsize, last_exit_status: u8) Prompt {
        return Prompt{
            .winsize = window_size,
            .last_exit_status = last_exit_status,
        };
    }

    pub fn render(self: Prompt) void {
        _ = self;
    }
};
