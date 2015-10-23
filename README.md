##### README

[blp](https://github.com/D630/blp) is my stripped down version of [liquidprompt](https://github.com/nojhan/liquidprompt) (Linux only, `GNU bash >= 3.2`).

It takes account into:
- current option flags as specified upon invocation
- git-prompt via `__git_ps1()`
- hostname
- started bash/shell instances
- last error code
- permission
- pwd
- detached sessions; running/suspended jobs
- user and session info
- coloring
- user-defined general-purpose prefix tag

##### BUGS & REQUESTS

Feel free to open an issue or put in a pull request on https://github.com/D630/blp

##### GIT

To download the very latest source code:

```
git clone https://github.com/D630/blp
```

In order to use the latest tagged version, do also something like this:

```
cd -- ./blp
git checkout $(git describe --abbrev=0 --tags)
```

##### INSTALL

Feed bash with something like this:

```sh
shopt -s promptvars
PROMPT_DIRTRIM=12

shopt -q promptvars && {
    __prompt_command ()
    {
        typeset -i err=$?

        if typeset -F __blp_main 1>/dev/null
        then
            __blp_prompt "$err"
        else
            source "PATH/TO/blp.bash" "$err"
            #__blp_prompt off
        fi
    }

    typeset -ix BLP_USE_COLOR=1
    typeset -ix BLP_USE_GIT=1
    typeset -ix BLP_USE_SCREEN=0
    typeset -ix BLP_USE_TMUX=0

    PROMPT_COMMAND=__prompt_command
}

```

##### USAGE

The script will set up an alias for the function `__blp_prompt()`. Use it this way in an interactive instance:

```sh
% prompt on
% prompt off
% prompt toggle
% prompt tag ARG1 ...
% prompt tag
```

To check detached sessions, export these environment variables:
- BLP_USE_SCREEN=1
- BLP_USE_TMUX=1

Color support:
- BLP_USE_COLOR=1

Git info:
- BLP_USE_GIT=1

##### NOTICE

blp has been written in [GNU bash](http://www.gnu.org/software/bash/) on [Debian GNU/Linux 9 (stretch/sid)](https://www.debian.org) using these programs/packages:

- GNU Screen version 4.03.01
- GNU bash 4.3.42(1)-release
- GNU coreutils 8.23: who
- GNU grep 2.21
- GNU sed 4.2.2
- ncurses 6.0.20150810: tput
- procps-ng version 3.3.10: ps
- tmux 2.0

##### CREDITS

Most code has been stolen from liquidprompt, and been modified.

##### LICENCE

GNU AGPLv3
