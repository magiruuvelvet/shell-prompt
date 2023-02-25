## add this to your config.fish file ###########################
#set -g SHELL_PROMPT_BINARY "shell-prompt"
#set -g SHELL_PROMPT_HOSTNAME_COLOR "r;g;b"
#"$SHELL_PROMPT_BINARY" --shell-init-source fish | source
## END #########################################################

# disable the prompt pwd limit / truncation
# (this ensures that the builtin `pwd` command always prints the entire working directory)
set -g fish_prompt_pwd_dir_length 0

# initialize static default options
set -e __fish_shell_prompt_default_options
set -g __fish_shell_prompt_default_options

# set custom hostname color when present
if [ -n "$SHELL_PROMPT_HOSTNAME_COLOR" ]
    set -a __fish_shell_prompt_default_options "--hostname-color=$SHELL_PROMPT_HOSTNAME_COLOR"
end

# checks if a given string starts with another string
function __shell_prompt_string_starts_with
    string match -i --regex '^'"$argv[2]"'.*$' "$argv[1]" >/dev/null 2>&1
end

# additional shell prompt arguments setup
function __fish_shell_prompt_options_setup
    set -e __fish_shell_prompt_options
    set -g __fish_shell_prompt_options
end

# print the actual shell prompt
function __fish_shell_prompt_launch
    printf "\n"
    "$SHELL_PROMPT_BINARY" \
        --columns=$COLUMNS \
        --lines=$LINES \
        --last-exit-status=$last_status \
        $__fish_shell_prompt_default_options \
        $__fish_shell_prompt_options
end

# git directory features
function __git_prompt_setup_directory_aliases
    if [ "$git_repo_present" = 1 ]
        function commit     --wraps "git commit";   git commit $argv; end
        function checkout   --wraps "git checkout"; git checkout $argv; end
        function pull       --wraps "git pull";     git pull $argv; end
        function push       --wraps "git push";     git push $argv; end
        function fetch      --wraps "git fetch";    git fetch $argv; end
        function stash      --wraps "git stash";    git stash $argv; end
        function add        --wraps "git add";      git add $argv; end
        function branch     --wraps "git branch";   git branch $argv; end
        function sdiff      --wraps "git sdiff";    git sdiff $argv; end
        function diff       --wraps "git diff";     git diff $argv; end
        function tag        --wraps "git tag";      git tag $argv; end
        function stag       --wraps "git stag";     git stag $argv; end
        function slog       --wraps "git slog";     git slog $argv; end
        function ls-files   --wraps "git ls-files"; git ls-files $argv; end
        function remote     --wraps "git remote";   git remote $argv; end
        function reset      --wraps "git reset";    git reset $argv; end
        function visit;                           __git_prompt_url_visit $argv; end

        # overwrite git with custom logic which should only be visible to the shell and nowhere else
        function git --wraps "git"
            if begin [ $argv[1] = "gui" ]; and [ (count $argv) = 1 ]; end
                # launch git gui in background and disown the process, we don't care about git gui blocking the shell
                command git gui &; disown
            else
                # otherwise forward arguments as-is
                command git $argv
            end
        end
    else
        functions --erase commit
        functions --erase checkout
        functions --erase pull
        functions --erase push
        functions --erase fetch
        functions --erase stash
        functions --erase add
        functions --erase branch
        functions --erase sdiff
        functions --erase diff
        functions --erase tag
        functions --erase stag
        functions --erase slog
        functions --erase ls-files
        functions --erase remote
        functions --erase reset
        functions --erase visit

        functions --erase git
    end
end

# normalize git url to http
function __git_prompt_url_convert
    set -l url "$argv[1]"

    if [ (string length $url) = 0 ]
        return 1
    end

    if __shell_prompt_string_starts_with "$url" "http"
        echo "$url"
        return 0
    else
        # convert ssh url to http url
        set -l domain_start 1
        set -l domain_end 1

        # find domain
        set -l index 1
        for char in (echo "$url" | string split "")
            if [ "$char" = "@" ]
                set domain_start (math $index + 1)
            else if [ "$char" = ":" ]
                set domain_end $index
            end
            set index (math $index + 1)
        end

        set -l domain (string sub $url -s $domain_start -l (math $domain_end - $domain_start))

        # find path
        set -l remaining_url (string sub $url -s (math $domain_end + 1))

        # print url
        echo "https://$domain/$remaining_url"
        return 0
    end
end

# visit git repositories in the default web browser
function __git_prompt_url_visit
    if [ (count $argv) = 0 ]
        set remote "origin"
    else
        set remote "$argv[1]"
    end

    set -l url (git remote get-url "$remote" 2>/dev/null)
    set -l url (__git_prompt_url_convert "$url")
    if [ $status = 0 ]
        xdg-open "$url" >/dev/null 2>&1
    else
        echo "エーラー: git repository has no remote '$remote'" >&2
    end
end

