# shell-prompt

a work-in-progress Zig implementation of a [magiruuvelvet/fish-shell-config](https://github.com/magiruuvelvet/fish-shell-config) replacement intended to be used as fish shell prompt

## Goals

 - reduce most of the work to a single process,
   instead of spawning multiple processes each time the
   prompt is displayed

 - improve performance and modularity of my shell prompt

 - learn the [Zig programming language](https://ziglang.org/) and improve my skills
   in that language

## Building

 - run `zig build`
 - binaries can be found in the `zig-out/bin/` directory

## Testing

There are 2 type of unit tests:

 - end user tests: `zig-out/bin/shell-prompt-tests`
 - internal platform-specific tests: `zig build test` (runs tests for private functions not visible outside of the relevant source files)
