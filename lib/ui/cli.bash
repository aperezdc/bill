#! /usr/bin/env bill
#++
#   ======================
#   Command Line Interface
#   ======================
#   :Author: Adrian Perez <aperez@igalia.com>
#   :Copyright: 2008-2009 Igalia S.L.
#   :License: GPL3
#   :Abstract: User interaction using a command, line-oriented interface.
#
#   .. contents::
#--

use data/hash



#++ cli_optparse [ -h ] [ -n ] options destination
#
#   Parses command line options. Supports both short and long options, as
#   well as specifying defaults for options and generating help messages.
#   Valid options, default values and descriptive texts for them are
#   specified as an array of 3-tuples of the following:
#
#   * Short and long option, separated with a colon. For example ``q:quiet``
#     would allow the user to pass ``-q`` or ``--quiet``.
#   * Default value. For boolean options use ``true`` or ``false``,
#     otherwise the next argument will be consumed.
#   * Descriptive text for the option. This is only used to generate help
#     messages.
#
#   The *destination* parameter should be a `hash table
#   <../data/hash.html>`__ in which values for options will be stored. Make
#   sure it is initialized before calling this function.
#
#   As an example:
#
#   .. sourcecode:: bash
#
#       opts=(
#           q:quiet  false    'Quiet operation'
#           i:input  ''       'Takes one argument'
#           u:user   "$USER"  'User name'
#       )
#
#   The previous array defines options which allow all of the following
#   possibilities (among others):
#
#   .. sourcecode:: bash
#
#       --quiet
#       -q --input input-file
#       -u john --quiet -i foo
#
#   If the ``-h`` switch is given, a help message is generated when
#   unrecognized command line options are found, and the process **will
#   exit** with a non-zero status. If not given, the help message is not
#   printed, but the function will have a non-zero exit status.
#
#   Command line will be parsed until the first non-option is found. The
#   ``CLI_LAST_ARG`` variable will be set to the index of the last proper
#   option.
#
#--
cli_optparse ()
{
    CLI_LAST_ARG=0
    local showhelp=false
    if [ "$1" = "-h" ]
    then
        showhelp=true
        shift
    fi
    declare -r showhelp

    local applydefaults=true
    if [ "$1" = "-n" ]
    then
        applydefaults=false
        shift
    fi
    declare -r applydefaults

    # XXX This hacky way of obtaining array items is needed for proper
    #     operation in Bash versions prior to 3.2 -- expect more below.
    local -ar all="( \"\${$1[@]}\" )"

    local -r opt=$2
    local arg index k v
    shift 2

    $applydefaults && __cli_optparse_apply_defaults

    while [[ $# -gt 0 ]]
    do
        arg=$1
        shift
        case $arg in
            --*) index=$(__cli_optparse_find_long  "${arg#--}") ;;
            -* ) index=$(__cli_optparse_find_short "${arg#-}" ) ;;
            *  ) return ;;
        esac
        if [ -z "$index" ] ; then
            if $showhelp ; then
                __cli_optparse_help 1>&2
                exit 1
            fi
            return 1
        fi

        k=${all[$index]}
        v=${all[$((index+1))]}
        case $v in
        false)
            v=true
            ;;
        true)
            v=false
            ;;
        *)
            v=$1
            (( CLI_LAST_ARG++ ))
            shift
            ;;
        esac
        hash_set $opt "${k#*:}" "$v"
        (( CLI_LAST_ARG++ ))
    done
}



__cli_optparse_help ()
{
    local o d t i
    local -r l=${#all[@]}

    printf "Command options:\n"
    for (( i = 0 ; i < l ; i += 3 ))
    do
        o=${all[$i]}
        d=${all[$((i+1))]}
        t=${all[$((i+2))]}
        if [ -n "${o%%:*}" ] ; then
            printf "  -%1s,  --%-20s  %s [%s]\n" ${o%%:*} ${o#*:} "$t" "$d"
        else
            printf "       --%-20s  %s [%s]\n" ${o#*:} "$t" "$d"
        fi
    done
}


__cli_optparse_apply_defaults ()
{
    local k v i
    local -r l=${#all[@]}

    for (( i = 0 ; i < l ; i += 3 ))
    do
        k=${all[$i]}
        v=${all[$((i+1))]}
        k=${k#*:}
        hash_set $opt "$k" "$v"
    done
}


__cli_optparse_find_short ()
{
    local c i
    local -r l=${#all[@]}

    for (( i = 0 ; i < l ; i += 3 ))
    do
        c=${all[$i]}
        c=${c%%:*}
        if [[ $c = $1 ]]
        then
            echo "$i"
            return
        fi
    done
}


__cli_optparse_find_long ()
{
    local c i
    local -r l=${#all[@]}

    for (( i = 0 ; i < l ; i += 3 ))
    do
        c=${all[$i]}
        c=${c#*:}
        if [[ $c = $1 ]]
        then
            echo "$i"
            return
        fi
    done
}



#++ cli_qa_batch [ -f | --force-ask ] values questions
#
#   Performs a series of interactive questions, asking the user for answers
#   and gathering answers into a hash table. Question sets are arrays of
#   3-tuples with the following components:
#
#   * A key used to identify the question.
#   * The question itself.
#   * A suggested (or default) value.
#
#   As en example, the following could be used to input an user's
#   information:
#
#   .. sourcecode:: bash
#
#       questions=(
#           username  'User name'  "$USER"
#           firstname 'First name' ''
#           lastname  'Last name'  ''
#       )
#       values=$(hash_new)
#       cli_qa_batch $values questions
#       echo "Hello Mr. $(hash_get $values lastname)"
#
#   The above code would result in an interactive session like the
#   following, supposing your login name is ``john``::
#
#       User name [john] > ripper
#       First name > John
#       Last name > T. Ripper
#       Hello Mr. T. Ripper!
#
#   As you can see, default values are suggested between brackets, like in
#   the first question of the example, and if the user just taps the “enter”
#   key the default value will be used as input.
#
#   When requested values already have a key in the ``values`` hash table
#   its value will be used instead of asking the user. If you pass the
#   ``-f`` (also ``--force-ask``) flag the user will be prompted with the
#   value stored in the hash table as suggestion.
#--
cli_qa_batch ()
{
    local forceask=false
    if [[ $1 = -f ]] || [[ $1 = --force-ask ]]
    then
        forceask=true
        shift
    fi
    declare -r forceask

    local questions="$2[@]"
    local -ar questions=( "${!questions}" )
    local -r ql=${#questions[@]}
    local val i tmp

    for (( i = 0; i < ql; i += 3 ))
    do
        if hash_has "$1" "${questions[$i]}" && ! $forceask
        then
            continue
        fi
        val=${questions[$((i+1))]}
        tmp=$(hash_get "$1" "${questions[$i]}" || echo "${questions[$((i+2))]}")
        [[ -z $tmp ]] || val="$val [$tmp]"
        read -r -e -p "$val > " val
        [[ -z $val ]] && val=$tmp
        hash_set "$1" "${questions[$i]}" "$val"
    done
}



__cli_optparse_demo ()
{
    local -r args=$(hash_new)
    local -ar opts=(
        q:quiet false 'Be quiet'
        f:file  '-'   'Input file'
    )

    cli_optparse -h opts $args "$@"
    echo "quiet: $(hash_get $args quiet)"
    echo "file : $(hash_get $args file )"
    echo "last : $CLI_LAST_ARG"
    hash_clear $args
}

main __cli_optparse_demo "$@"

