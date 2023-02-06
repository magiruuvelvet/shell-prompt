const std = @import("std");

pub fn map_exit_status_to_signal_name(exit_status: u8) []const u8 {
    switch (exit_status)
    {
        125 => return "EXEC", // exec error
        126 => return "EXEC", // not executable
        127 => return "CNF",  // no such command
        128 => return "EXIT", // exit with signal + signal number
        129 => return "SIGHUP",
        130 => return "SIGINT",
        131 => return "SIGQUIT",
        132 => return "SIGILL",
        133 => return "SIGTRAP",
        134 => return "SIGABRT",
        135 => return "SIGBUS",
        136 => return "SIGFPE",
        137 => return "SIGKILL",
        138 => return "SIGUSR1",
        139 => return "SIGSEGV",
        140 => return "SIGUSR2",
        141 => return "SIGPIPE",
        142 => return "SIGALRM",
        143 => return "SIGTERM",
        144 => return "SIGSTKFLT",
        145 => return "SIGCHLD",
        146 => return "SIGCONT",
        147 => return "SIGSTOP",
        148 => return "SIGTSTP",
        149 => return "SIGTTIN",
        150 => return "SIGTTOU",
        151 => return "SIGURG",
        152 => return "SIGXCPU",
        153 => return "SIGXFSZ",
        154 => return "SIGVTALRM",
        155 => return "SIGPROF",
        156 => return "SIGWINCH",
        157 => return "SIGIO",
        158 => return "SIGPWR",
        else => return std.fmt.allocPrint(std.heap.page_allocator, "{}", .{exit_status}) catch unreachable,
    }
}
