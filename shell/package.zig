/// sourceable shell scripts for initialization
pub const shell = struct {
    /// init script for fish shell
    pub const fish =
        @embedFile("fish/init.fish") ++
        @embedFile("fish/builtin.fish");

    /// init script for bash shell
    pub const bash =
        @embedFile("bash/init.bash") ++
        @embedFile("bash/builtin.bash");
};
