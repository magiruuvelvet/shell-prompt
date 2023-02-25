
# default builtins and aliases
if [ "$SHELL_PROMPT_LOAD_BUILTINS" = "true" ]
    if [ (uname) = "FreeBSD" ]
        alias ls='ls --color'
        alias ll='ls -lla'
    else
        alias ls='ls -v --color'
        alias ll='ls -llav'
    end

    alias dir='dir --color'
    alias vdir='vdir --color'

    alias grep='grep --color'
    alias fgrep='fgrep --color'
    alias egrep='egrep --color'

    # create and switch to directory in one go
    function mkdircd
        mkdir -p $argv
        cd $argv
    end
end
