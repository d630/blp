## blp v0.1.1.0 [AGPLv3]

`blp`(1) is my minimal [liquidprompt](https://github.com/nojhan/liquidprompt) (Linux only, `GNU bash`(1) >= 3.2).

It takes account into:
- current option flags as specified upon invocation
- git-prompt via `__git_ps1()`
- hostname
- started bash/shell instances
- last error code
- permission
- pwd
- screen sessions/running jobs/suspended jobs
- user
- user-defined general-purpose prefix tag

### Install

md5sum 8abe738341f3474c31efde773b3f736c blp.bash

Get the script with `$ git clone https://github.com/D630/blp.git` and feed `bash`(1) with something like that:

```sh
shopt -s promptvars
PROMPT_DIRTRIM=12

shopt -q promptvars && {
    __prompt_command ()
    {
        declare -i err=$?

        if declare -F __blp_main 1>/dev/null
        then
            __blp_prompt "$err"
        else
            source "PATH/TO/blp.bash" "$err"
        fi
    }

    PROMPT_COMMAND=__prompt_command
}

```

Further, we need some infos from the `terminfo`(5) database, which need to be set before executing `__blp_man`():

```sh
{
    declare -x \
        X_TI_BOLD=$(tput bold || tput md) \
        X_TI_RESET=$(tput sgr0 || tput me) \
        X_TI_WHITE_F=$(tput setaf 7 || tput AF 7) \
        X_TI_WHITE_F_BOLD=${X_TI_BOLD}${X_TI_WHITE_F}
} 2>/dev/null

[[ $TERM == *-m ]] || {
    declare -x \
        X_TI_BLACK_F=$(tput setaf 0) \
        X_TI_BLACK_F_BOLD=${X_TI_BOLD}${X_TI_BLACK_F} \
        X_TI_BLUE_F=$(tput setaf 4|| tput AF 4) \
        X_TI_BLUE_F_BOLD=${X_TI_BOLD}${X_TI_BLUE_F} \
        X_TI_CYAN_F=$(tput setaf 6) \
        X_TI_CYAN_F_BOLD=${X_TI_BOLD}${X_TI_CYAN_F} \
        X_TI_GREEN_B=$(tput setab 2) \
        X_TI_GREEN_F=$(tput setaf 2 || tput AF 2) \
        X_TI_GREEN_F_BOLD=${X_TI_BOLD}${X_TI_GREEN_F} \
        X_TI_PURPLE_F=$(tput setaf 5) \
        X_TI_PURPLE_F_BOLD=${X_TI_BOLD}${X_TI_PURPLE_F} \
        X_TI_RED_B=$(tput setab 1) \
        X_TI_RED_F=$(tput setaf 1) \
        X_TI_RED_F_BOLD=${X_TI_BOLD}${X_TI_RED_F} \
        X_TI_WHITE_B=$(tput setab 7) \
        X_TI_YELLOW_B=$(tput setab 3) \
        X_TI_YELLOW_F=$(tput setaf 3) \
        X_TI_YELLOW_F_BOLD=${X_TI_BOLD}${X_TI_YELLOW_F}
} 2>/dev/null
```

### Help

The script will set up an alias for the function `__blp_prompt()`. Use it this way in an interactive instance:

```
    % prompt on
    % prompt off
    % prompt tag ARG1 ...
    % prompt tag
```

### Bugs & Requests

Report it on https://github.com/D630/blp/issues

### Credits

Most code has been stolen from `liquidprompt`(1)
