const std = @import("std");
const format = @import("utils").format.format;
const renderer = @import("renderer.zig");
const modules = @import("modules");
const winsize = modules.term.winsize;
const term = modules.term;
const color = term.color;
const os = modules.os;
const time = modules.os.time;
const signals = modules.os.signals;
const wcwidth_ascii = modules.term.wcwidth_ascii;

fn get_colored_bold(text: []const u8, rgb_code: ?[]const u8) []const u8 {
    if (rgb_code != null) {
        return color.rgb_bold_text(text, rgb_code.?, color.mode.foreground);
    } else {
        return text;
    }
}

pub const Prompt = struct {
    /// terminal window size
    winsize: winsize,

    /// the exit status of the last program
    last_exit_status: u8 = 0,

    /// cached user id
    uid: ?u32,

    /// prefix of the additional prompt lines for the root user
    root_prefix: ?[]const u8,

    /// the color of the hostname in r;g;b format
    hostname_color: ?[]const u8 = null,

    /// initialize a new prompt struct
    pub fn init(last_exit_status: u8) Prompt {
        return Prompt{
            .winsize = term.get_winsize(),
            .last_exit_status = last_exit_status,
            .uid = os.get_uid(),
            .root_prefix = get_root_prefix(),
        };
    }

    /// render the prompt to the terminal window
    pub fn render(self: Prompt) !void {
        try self.render_line1();
        try self.render_line2();
        try self.render_context_lines();
        try self.render_input_line();
    }

    /// determine the prefix of the additional prompt lines
    fn get_root_prefix() []const u8 {
        // const S = struct {
        //     const prefix: []const u8 = if (os.get_uid() == 0) blk: {
        //         break :blk color.rgb_bold("▌", 182, 0, 0, color.mode.foreground);
        //     } else blk: {
        //         break :blk " ";
        //     };
        // };

        // return S.prefix;

        if (os.get_uid() == 0) {
            return color.rgb_bold("▌", 182, 0, 0, color.mode.foreground);
        } else {
            return " ";
        }
    }

    /// formats the last exit status
    ///
    /// TODO: don't hardcode ranges for colorization here, move to platform-specific implementation
    fn format_last_exit_status(self: Prompt) [] const u8 {
        const signal_name = signals.map_exit_status_to_signal_name(self.last_exit_status);

        // exit status of zero is printed normally
        if (self.last_exit_status == 0) {
            return signal_name;
        }
        // abnormal execution errors are colorized with a blue-ish background and white text
        else if (self.last_exit_status >= 125 and self.last_exit_status <= 128) {
            return format("{s}{s}{s}{s}", .{
                color.rgb_ascii(105, 157, 157, color.mode.background), // #699d9d
                color.rgb_ascii(255, 255, 255, color.mode.foreground), // #ffffff
                signal_name,
                color.ascii.normal,
            });
        }
        // exit by signal is colorized with a purple background and white text
        else if (self.last_exit_status >= 129 and self.last_exit_status <= 158) {
            return format("{s}{s}{s}{s}", .{
                color.rgb_ascii(178, 24, 178, color.mode.background),  // #b218b2
                color.rgb_ascii(255, 255, 255, color.mode.foreground), // #ffffff
                signal_name,
                color.ascii.normal,
            });
        }
        // all other exit codes are colorized with a red foreground
        else {
            return color.rgb(signal_name, 177, 50, 28, color.mode.foreground); // #b1321c
        }
    }

    /// user: `┌───[username@hostname]───...───[時間HH:MM:SS]─┐`
    /// root: `┌───[hostname]─────────...───[時間HH:MM:SS]─┐`
    fn render_line1(self: Prompt) !void {
        // username is only shown for non-root users
        const rendered_username = if (self.uid.? != 0) blk: {
            var username = os.get_user_display_name();
            if (username.len == 0) {
                username = os.get_username();
            }
            break :blk try std.mem.concat(std.heap.page_allocator, u8, &[_][]const u8{username, "@"});
        } else blk: {
            break :blk "";
        };

        const hostname = os.get_hostname();
        const current_time = try time.get_clock_time();

        var cols: u16 = 0;

        // format left side of the line
        const left = format(
            "┌───[{s}{s}]─", .{rendered_username, get_colored_bold(hostname, self.hostname_color)});

        // format right side of the line
        const right = format(
            "─[{s}{s}時間{d:0>2}:{d:0>2}:{d:0>2}{s}]─┐", .{
                color.ascii.bold,
                color.rgb_ascii(86, 86, 86, color.mode.foreground),
                current_time.hours, current_time.minutes, current_time.seconds,
                color.ascii.normal});
        cols += @intCast(u16, wcwidth_ascii(right));

        // draw everything to the terminal
        cols += renderer.draw_text(left);
        _ = renderer.draw_line("─", self.winsize.columns - cols);
        renderer.draw_text_with_known_width(right);
        renderer.new_line();
    }

    /// `│ [0][8/4]: /data/projects/shell-prompt  ...  │`
    /// `[last_exit_status][visible files/hidden files]: working directory`
    fn render_line2(self: Prompt) !void {
        const pwd = try os.dir.get_pwd_home_tilde();
        const pwd_stats = try os.dir.get_directory_stats(try os.dir.get_pwd());

        var cols: u16 = 0;

        // display hidden file counter only when hidden files are present
        const pwd_stats_hidden = if (pwd_stats.hidden > 0) blk: {
            break :blk format("{s}/{}{s}", .{
                color.rgb_ascii(213, 213, 213, color.mode.foreground),
                pwd_stats.hidden,
                color.ascii.normal});
        } else blk: {
            break :blk "";
        };

        // format left side of the line
        const left = format(
            "│{s}[{s}][{}{s}]: ", .{
                self.root_prefix.?,
                self.format_last_exit_status(),
                pwd_stats.visible,
                pwd_stats_hidden});
        cols += @intCast(u16, wcwidth_ascii(left));

        // format right side of the line
        const right = format(
            " │", .{});
        cols += 2; // @intCast(u16, wcwidth_ascii(right));

        // shorten the working directory when it doesn't fit into the line
        const max_possible_pwd_width = self.winsize.columns - cols;
        const pwd_width = @intCast(u16, wcwidth_ascii(pwd));
        if (pwd_width > max_possible_pwd_width) {
            // TODO: implement this feature
        }

        // append the new calculated pwd width for the draw_line() function
        cols += pwd_width;

        // draw everything to the terminal
        renderer.draw_text_with_known_width(left);
        renderer.draw_text_with_known_width(pwd);
        _ = renderer.draw_line(" ", self.winsize.columns - cols);
        renderer.draw_text_with_known_width(right);
        renderer.new_line();
    }

    /// additional lines depending on the current directory and directory contents
    /// when the context is not known for the directory, an empty line is rendered
    /// this is were all the fun features of this prompt are rendered
    fn render_context_lines(_: Prompt) !void {
        // TODO: prompt context lines
    }

    /// renders the final line of the prompt which contains the user input
    /// the content of this line depends on the user id
    fn render_input_line(_: Prompt) !void {
        // TODO: prompt input line
    }
};
