
# default builtins and aliases
if [[ "$SHELL_PROMPT_LOAD_BUILTINS" == "true" ]]; then
    # cd to parent directory by typing '..'
    alias ..='cd ..'

    alias ls='ls --color'
    alias ll='ls -lla'
    alias dir='dir --color'
    alias vdir='vdir --color'

    alias grep='grep --color'
    alias fgrep='fgrep --color'
    alias egrep='egrep --color'

    # create and switch to directory in one go
    function mkdircd() {
        if [ $# -eq 0 ]; then
            echo "mkdircd: argument required"
            return 1
        elif [ $# -gt 1 ]; then
            echo "mkdircd: too many arguments"
            return 1
        fi

        mkdir -p "$1"
        cd "$1"
    }
fi
