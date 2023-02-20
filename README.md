# shell-prompt

a fast and feature-rich dynamic shell prompt implementation in a single binary written in the Zig programming language

intended to be used as fish shell prompt together with [magiruuvelvet/fish-shell-config](https://github.com/magiruuvelvet/fish-shell-config)

## Features

 - reduces most of the work to a single process,
   instead of spawning multiple processes each time the
   prompt is displayed, which makes this prompt render noticeable faster than hundreds of lines of fish shell script

 - fast and modular shell prompt implementation which is easy to extend

 - context- and directory-aware features

 - support for git repositories, displays the current status of a git repository (commit hash, branch name, file changes, remote changes, the last commit message)

 - detects build systems in a directory and displays their name

 - displays a hint whenever the current shell is connected via ssh

## Building

You need the latest tagged release of the Zig compiler (0.10.1). The master branch of the compiler is not supported.

 - run `zig build`
 - binaries can be found in the `zig-out/bin/` directory
 - for optimized release builds execute `./build-release.sh`

## Testing

There are 2 type of unit tests:

 - end user tests: `zig-out/bin/shell-prompt-tests`
 - internal platform-specific tests: `zig build test` (runs tests for private functions not visible outside of the relevant source files)
