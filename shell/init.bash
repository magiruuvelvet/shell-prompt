## add this to your .bashrc file ###############################
#export SHELL_PROMPT_BINARY="shell-prompt"
#export SHELL_PROMPT_HOSTNAME_COLOR="r;g;b"
#eval "$("$SHELL_PROMPT_BINARY" --shell-init-source bash)"
## END #########################################################

__shell_prompt_init() {
    # additional arguments for the shell prompt
    local __shell_prompt_args=(
        "--columns=\$COLUMNS"
        "--lines=\$LINES"
    )

    # set custom hostname color when present
    if [ ! -z "${SHELL_PROMPT_HOSTNAME_COLOR}" ]; then
        __shell_prompt_args+=("--hostname-color='${SHELL_PROMPT_HOSTNAME_COLOR}'")
    fi

    # set custom prompt when path to the binary is known
    if [ ! -z "${SHELL_PROMPT_BINARY}" ]; then
        # set the shell prompt input line
        PS1="\n\$($SHELL_PROMPT_BINARY "${__shell_prompt_args[@]}")"

        # set the shell prompt continuation line
        PS2="    "
    fi
}

__shell_prompt_init
