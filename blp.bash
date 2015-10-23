#!/usr/bin/env bash

# blp [AGPLv3]
# https://github.com/D630/blp

# Most code has been stolen from liquidprompt [AGPLv3]
# https://github.com/nojhan/liquidprompt

__blp_main ()
{
        ## Work with $1 which is $? of the last command
        builtin typeset err_string
        (( $1 )) && {
                err_string="\\[${TI_PURPLE_F}\\]${err}\\[${TI_RESET}\\]"
        }

        ## Build $bracket_{close,open}
        builtin typeset \
                bracket_open=[ \
                bracket_close=];

        ## Build $jbs
        builtin typeset jbs

        ### detached
        builtin typeset -i detached=
        (( BLP_USE_SCREEN )) && {
                detached+=$(
                        command screen -ls 2>/dev/null \
                        | command grep -c '[Dd]etach[^)]*)$'
                )
        }

        (( BLP_USE_TMUX )) && {
                detached+=$(
                        command tmux list-sessions 2>/dev/null \
                        | command fgrep -cv 'attached'
                )
        }

        (( detached )) && {
                jbs=\\[${TI_YELLOW_F}\\]${detached}d\\[${TI_RESET}\\]
        }

        ### running
        builtin typeset -a running
        builtin mapfile -t running < <(
                builtin jobs -r
        )

        (( ${#running[@]} )) && {
                jbs=${jbs:+${jbs}/}\\[${TI_YELLOW_F_BOLD}\\]${#running[@]}\&\\[${TI_RESET}\\]
        }

        ### stopped
        builtin typeset -a stopped
        builtin mapfile -t stopped < <(
                builtin jobs -s
        )

        (( ${#stopped[@]} )) && {
                jbs=${jbs:+${jbs}/}\\[${TI_YELLOW_F_BOLD}\\]${#stopped[@]}z\\[${TI_RESET}\\]
        }

        ## Build $user
        builtin typeset user
        if
                (( ! EUID ))
        then
                user=\\[${TI_YELLOW_F_BOLD}\\]\\u\\[${TI_RESET}\\]
        else
                if
                        [[ $USER == $LOGNAME ]]
                then
                        user=\\u
                else
                        user=\\[${TI_BOLD}\\]\\u\\[${TI_RESET}\\]
                fi
        fi

        ## Build $hst
        builtin typeset hst

        ### debian
        if
                [[ -r /etc/debian_chroot ]]
        then
                hst=$(</etc/debian_chroot)
        else
                hst=
        fi

        ### X
        if
                [[ -n $DISPLAY ]]
        then
                hst=\\[${TI_GREEN_F}\\]${hst}@\\[${TI_RESET}\\]
        else
                hst=\\[${TI_YELLOW_F}\\]${hst}@\\[${TI_RESET}\\]
        fi

        ### session
        builtin typeset color_host_hash
        #declare host_cksum= color_host_hash=
        #read -r host_cksum _ < <(cksum <<<"$HOSTNAME")
        #declare color_host_hash=\\[$(tput setaf $((3 + host_cksum % 6 )))\\]
        if
                [[
                        -z $SSH_CLIENT &&
                        -z $SSH_CONNECTION &&
                        -z $SSH_TTY
                ]]
        then
                hst=${hst}${color_host_hash}\\h\\[${TI_RESET}\\]
        else
                builtin typeset sess_src="$(
                        command who am i \
                        | command sed -n 's/.*(\(.*\))/\1/p'
                )"
                builtin typeset sess_parent="$(
                        command ps -o comm= -p "$PPID" 2>/dev/null
                )"
                if
                        [[ -z ${sess_src/:*/} ]]
                then
                        hst=${hst}${color_host_hash}\\h\\[${TI_RESET}\\]
                elif
                        [[ $sess_parent =~ ^su(do|)$ ]]
                then
                        hst=${hst}\\[${TI_YELLOW_B}}\\]\\h\\[${TI_RESET}\\]
                else
                        hst=${hst}\\[${TI_BLACK_F}${TI_RED_B}\\]\\h\\[${TI_RESET}\\]
                fi
        fi

        ## Build $perm
        builtin typeset perm
        if
                [[ -w $PWD ]]
        then
                perm=\\[${TI_GREEN_F}\\]:\\[${TI_RESET}\\]
        else
                perm=\\[${TI_RED_F_BOLD}\\]:\\[${TI_RESET}\\]
        fi

        ## Build $shlvl
        builtin typeset shlvl=${SHLVL}l

        ## Build $git_ps1
        if
                (( BLP_USE_GIT )) &&
                builtin typeset -F __git_ps1 >/dev/null
        then
                builtin typeset git_ps1="$(
                        GIT_PS1_SHOWDIRTYSTATE=yes;
                        GIT_PS1_SHOWSTASHSTATE=yes;
                        GIT_PS1_SHOWUPSTREAM=auto;
                        GIT_PIBE_STYLE=branch;
                        GIT_PS1_SHOWCOLORHINTS=;
                        __git_ps1 "%s"
                )"
                if
                        [[ $git_ps1 == *\** ]]
                then
                        git_ps1=\(\\[${TI_RED_F}\\]${git_ps1}\\[${TI_RESET}\\]\)
                else
                        git_ps1=${git_ps1:+\(${git_ps1}\)}
                fi
                if
                        [[ -d ${PWD}/.git ]]
                then
                        git_ps1=${git_ps1:+± ${git_ps1}}
                else
                        git_ps1=${git_ps1:+(±) ${git_ps1}}
                fi
        fi

        ## Build $PS1
        builtin typeset -g +i PS1=
        PS1+=${BLP_PS1_PREFIX:+${bracket_open}${BLP_PS1_PREFIX}${bracket_close}}
        PS1+=${bracket_open}$-${bracket_close}
        PS1+=${bracket_open}${shlvl}${jbs}${bracket_close}
        PS1+=${bracket_open}${user}${hst}${perm}\\w${bracket_close}
        PS1+=${err_string:+ ${err_string}}
        PS1+="${git_ps1:+ ${git_ps1}} % "

        ## Build $PS2
        builtin typeset -g +i PS2="> "
}

__blp_prompt ()
case ${1//[0-9]/} in
off)
        builtin typeset -g +i BLP_PS1_OLD="$PS1"
        PS1="% "
;;
tag)
        if
                [[ -n $2 ]]
        then
                builtin typeset -g +i BLP_PS1_PREFIX="${@:2}"
        else
                builtin unset -v BLP_PS1_PREFIX
        fi
;;
on)
        builtin unset -v BLP_PS1_OLD
        __blp_main "$1"
;;
toggle)
        if
                [[ -n $BLP_PS1_OLD ]]
        then
                __blp_prompt on
        else
                __blp_prompt off
        fi
;;
"")
        [[ -n $BLP_PS1_OLD ]] || __blp_main "$1"
esac

alias prompt=__blp_prompt

__blp_prompt "$@"

# vim: set ts=8 sw=8 tw=0 et :
