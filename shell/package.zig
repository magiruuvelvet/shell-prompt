/// sourceable shell scripts for initialization
pub const shell = struct {
    /// init script for fish shell
    pub const fish = @embedFile("init.fish");

    /// init script for bash shell
    pub const bash = @embedFile("init.bash");
};