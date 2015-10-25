#!/usr/bin/env bash

# blp [AGPLv3]
# https://github.com/D630/blp

# Most code has been stolen from liquidprompt [AGPLv3]
# https://github.com/nojhan/liquidprompt

__blp_color ()
{
        {
                builtin typeset +i -gx \
                        BLP_TI_BOLD="$(command tput bold || command tput md)" \
                        BLP_TI_RESET="$(command tput sgr0 || command tput me)";
        } 2>/dev/null

        [[ $TERM == *-m ]] || {
                builtin typeset +i -gx \
                        BLP_TI_BLACK_F="$(command tput setaf 0)" \
                        BLP_TI_GREEN_F="$(command tput setaf 2 || command tput AF 2)" \
                        BLP_TI_PURPLE_F="$(command tput setaf 5)" \
                        BLP_TI_RED_B="$(command tput setab 1)" \
                        BLP_TI_RED_F="$(command tput setaf 1)" \
                        BLP_TI_RED_F_BOLD="${BLP_TI_BOLD}${BLP_TI_RED_F}"\
                        BLP_TI_YELLOW_B="$(command tput setab 3)" \
                        BLP_TI_YELLOW_F="$(command tput setaf 3)" \
                        BLP_TI_YELLOW_F_BOLD="${BLP_TI_BOLD}${BLP_TI_YELLOW_F}";
        } 2>/dev/null
}

__blp_main ()
{
        ## Work with $1 which is $? of the last command
        builtin typeset err_string
        (( $1 )) && {
                err_string="\\[${BLP_TI_PURPLE_F}\\]${err}\\[${BLP_TI_RESET}\\]"
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
                jbs=\\[${BLP_TI_YELLOW_F}\\]${detached}d\\[${BLP_TI_RESET}\\]
        }

        ### running
        builtin typeset -a running
        builtin mapfile -t running < <(
                builtin jobs -pr
        )

        (( ${#running[@]} )) && {
                jbs=${jbs:+${jbs}/}\\[${BLP_TI_YELLOW_F_BOLD}\\]${#running[@]}\&\\[${BLP_TI_RESET}\\]
        }

        ### stopped
        builtin typeset -a stopped
        builtin mapfile -t stopped < <(
                builtin jobs -ps
        )

        (( ${#stopped[@]} )) && {
                jbs=${jbs:+${jbs}/}\\[${BLP_TI_YELLOW_F_BOLD}\\]${#stopped[@]}z\\[${BLP_TI_RESET}\\]
        }

        ## Build $user
        builtin typeset user
        if
                (( ! EUID ))
        then
                user=\\[${BLP_TI_YELLOW_F_BOLD}\\]\\u\\[${BLP_TI_RESET}\\]
        else
                if
                        [[ $USER == $LOGNAME ]]
                then
                        user=\\u
                else
                        user=\\[${BLP_TI_BOLD}\\]\\u\\[${BLP_TI_RESET}\\]
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
                hst=\\[${BLP_TI_GREEN_F}\\]${hst}@\\[${BLP_TI_RESET}\\]
        else
                hst=\\[${BLP_TI_YELLOW_F}\\]${hst}@\\[${BLP_TI_RESET}\\]
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
                hst=${hst}${color_host_hash}\\h\\[${BLP_TI_RESET}\\]
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
                        hst=${hst}${color_host_hash}\\h\\[${BLP_TI_RESET}\\]
                elif
                        [[ $sess_parent =~ ^su(do|)$ ]]
                then
                        hst=${hst}\\[${BLP_TI_YELLOW_B}}\\]\\h\\[${BLP_TI_RESET}\\]
                else
                        hst=${hst}\\[${BLP_TI_BLACK_F}${BLP_TI_RED_B}\\]\\h\\[${BLP_TI_RESET}\\]
                fi
        fi

        ## Build $perm
        builtin typeset perm
        if
                [[ -w $PWD ]]
        then
                perm=\\[${BLP_TI_GREEN_F}\\]:\\[${BLP_TI_RESET}\\]
        else
                perm=\\[${BLP_TI_RED_F_BOLD}\\]:\\[${BLP_TI_RESET}\\]
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
                        git_ps1=\(\\[${BLP_TI_RED_F}\\]${git_ps1}\\[${BLP_TI_RESET}\\]\)
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
        if
                (( BLP_USE_COLOR ))
        then
                __blp_color
        else
                builtin unset -v ${!BLP_TI_*}
        fi
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
