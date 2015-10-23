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
                err_string="\\[${X_TI_PURPLE_F}\\]${err}\\[${X_TI_RESET}\\]"
        }

        ## Build $bracket_{close,open}
        builtin typeset \
                bracket_open=[ \
                bracket_close=];

        ## Build $jbs
        builtin typeset jbs
        builtin typeset -i detached="$(
                command screen -ls 2>/dev/null \
                | command grep -c '[Dd]etach[^)]*)$'
        )"
        detached+=$(
                command tmux list-sessions 2>/dev/null \
                | command fgrep -cv 'attached'
        )
        (( detached )) && {
                jbs=\\[${X_TI_YELLOW_F}\\]${detached}d\\[${X_TI_RESET}\\]
        }
        builtin typeset -i running="$(
                builtin jobs -r \
                | command wc -l
        )"
        (( running )) && {
                jbs=${jbs:+${jbs}/}\\[${X_TI_YELLOW_F_BOLD}\\]${running}\&\\[${X_TI_RESET}\\]
        }
        builtin typeset -i stopped="$(
                builtin jobs -s \
                | command wc -l
        )"
        (( stopped )) && {
                jbs=${jbs:+${jbs}/}\\[${X_TI_YELLOW_F_BOLD}\\]${stopped}z\\[${X_TI_RESET}\\]
        }

        ## Build $user
        builtin typeset user
        if
                (( ! EUID ))
        then
                user=\\[${X_TI_YELLOW_F_BOLD}\\]\\u\\[${X_TI_RESET}\\]
        else
                if
                        [[ $USER == $LOGNAME ]]
                then
                        user=\\u
                else
                        user=\\[${X_TI_BOLD}\\]\\u\\[${X_TI_RESET}\\]
                fi
        fi

        ## Build $hst
        builtin typeset hst
        if
                [[ -r /etc/debian_chroot ]]
        then
                hst=$(</etc/debian_chroot)
        else
                hst=
        fi
        if
                [[ -n $DISPLAY ]]
        then
                hst=\\[${X_TI_GREEN_F}\\]${hst}@\\[${X_TI_RESET}\\]
        else
                hst=\\[${X_TI_YELLOW_F}\\]${hst}@\\[${X_TI_RESET}\\]
        fi
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
                hst=${hst}${color_host_hash}\\h\\[${X_TI_RESET}\\]
        else
                builtin typeset sess_src="$(
                        command who am i \
                        | command sed -n 's/.*(\(.*\))/\1/p'
                )"
                builtin typeset sess_parent="$(
                        command ps -o comm= -p "$PPID" 2>/dev/null
                )"
                if
                        [[ -z $sess_src || $sess_src == \:* ]]
                then
                        hst=${hst}${color_host_hash}\\h\\[${X_TI_RESET}\\]
                elif
                        [[ $sess_parent == su || $sess_parent == sudo ]]
                then
                        hst=${hst}\\[${X_TI_YELLOW_B}}\\]\\h\\[${X_TI_RESET}\\]
                else
                        hst=${hst}\\[${X_TI_BLACK_F}${X_TI_RED_B}\\]\\h\\[${X_TI_RESET}\\]
                fi
        fi

        ## Build $perm
        builtin typeset perm
        if
                [[ -w $PWD ]]
        then
                perm=\\[${X_TI_GREEN_F}\\]:\\[${X_TI_RESET}\\]
        else
                perm=\\[${X_TI_RED_F_BOLD}\\]:\\[${X_TI_RESET}\\]
        fi

        ## Build $shlvl
        builtin typeset shlvl=${SHLVL}l

        ## Build $git_ps1
        builtin typeset -F __git_ps1 >/dev/null && {
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
                        git_ps1=\(\\[${X_TI_RED_F}\\]${git_ps1}\\[${X_TI_RESET}\\]\)
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
        }

        builtin typeset -g +i PS1="${X_BLP_PS1_PREFIX:+${bracket_open}${X_BLP_PS1_PREFIX}${bracket_close}}${bracket_open}$-${bracket_close}${bracket_open}${shlvl}${jbs}${bracket_close}${bracket_open}${user}${hst}${perm}\\w${bracket_close}${err_string:+ ${err_string}}${git_ps1:+ ${git_ps1}} % "
        builtin typeset -g +i PS2="> "
}

__blp_prompt ()
case ${1//[0-9]/} in
off)
        builtin typeset -g +i X_BLP_PS1_OLD="$PS1"
        PS1="% "
;;
tag)
        if
                [[ -n $2 ]]
        then
                builtin typeset -g +i X_BLP_PS1_PREFIX="${@:2}"
        else
                builtin unset -v X_BLP_PS1_PREFIX
        fi
;;
on)
        builtin unset -v X_BLP_PS1_OLD
        __blp_main "$1"
;;
toggle)
        if
                [[ -n $X_BLP_PS1_OLD ]]
        then
                __blp_prompt on
        else
                __blp_prompt off
        fi
;;
"")
        [[ -n $X_BLP_PS1_OLD ]] || __blp_main "$1"
esac

alias prompt=__blp_prompt

__blp_prompt "$@"

# vim: set ts=8 sw=8 tw=0 et :
