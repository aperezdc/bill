#! /usr/bin/env bill
#++
#   ===================
#   Config file parsing
#   ===================
#   :Author: Adrian Perez <aperez@igalia.com>
#   :Copyright: 2008-2009 Igalia S.L.
#   :License: GPL3
#   :Abstract: Parse configuration files in key-value pairs and INI-style.
#
#   .. contents::
#--

use data/hash
use text/string


#++ config_filter_uneeded [ commentchar ]
#
#   This function acts as a filter, stripping lines which start with a given
#   ``commentchar``, and blank lines as well. By default the command
#   character is ``#`` (hash), but can be changed to any other string.
#--
config_filter_unneeded ()
{
    local -r cchr=${1:-'#'}
    local line

    while read -r line ; do
        if [[ -z $line || $(string_lstrip <<< "${line}") = ${cchr}* ]] ; then
            continue
        else
            echo "$line"
        fi
    done
}


#++ config_keyval destination [ separator [ commentchar ] ]
#
#   Parses text in a key-value fashion, and stores key-value pairs in a hash
#   table. Text input must be given as standard input. Arguments:
#
#   * ``destination``: Hash table where parsed values will be stored.
#   * ``separator``: Character used to split key-value pairs. By default
#     this is set to ``=``.
#   * ``commentchar``: Character used as comment delimiter. By default this
#     is set to ``#`` (hash).
#
#   The default settings will be able of parsing input like the following:
#
#   .. sourcecode:: ini
#
#       # This is a comment
#       key1 = value1
#       key2 = value2
#       # ...
#       keyN = valueN
#
#   Note that spaces around *both* keys and values will be strippped.
#--
config_keyval ()
{
    local -r old_IFS=$IFS
    local k v

    IFS=${2:-'='}
    while read k v ; do
        k=$(string_strip <<< "$k")
        [ "$k" ] || return 1
        hash_set "$1" "$k" "$(string_strip <<< "$v")"
    done < <(config_filter_unneeded "${3:-'#'}")
    IFS=$old_IFS
}


#++ config_ini destination [ separator [ commentchar ] ]
#
#   Parses text from standard in a `INI-like`__ fashion. Read values are
#   stored into a hash table which has a nested hash table for each section
#   found. Helper functions for getting values and full sections
#   (config_ini_get_). Arguments:
#
#   __ http://en.wikipedia.org/wiki/INI_file
#
#   * ``destination``: Hash table where parsed values will be stored.
#   * ``separator``: Character used to split key-value pairs. By default
#     this is set to ``=``.
#   * ``commentchar``: Character used as comment delimiter. By default this
#     is set to ``#`` (hash).
#
#   The default settings will be able of parsing input like the following:
#
#   .. sourcecode:: ini
#
#       # Comments are started like this line, with hash symbols
#       # Sections are enclosed in brackets
#       [section1]
#       key1 = one
#
#       # This is another section
#       [section2]
#       key1 = uno
#       anotherkey = another value
#
#   Note that spaces around *both* keys and values will be strippped.
#--
config_ini ()
{
    local -r old_IFS=$IFS
    local section='[]'
    local k v

    IFS=${2:-'='}
    while read k v ; do
        k=$(string_strip <<< "$k")
        if string_startswith "$k" "["
        then
            section=$k
            continue
        fi
        [ "$k" ] || return 1
        hash_has "$1" "$section" || hash_set "$1" "$section" "$(hash_new)"
        hash_set $(hash_get "$1" "$section") "$k" "$(string_strip <<< "$v")"
    done < <(config_filter_unneeded "${3:-'#'}")
    IFS=$old_IFS
}


#++ config_ini_get hash section [ key ]
#
#   Obtains a full section if ``key`` is not specified, or the value of
#   a given key of the section otherwise. The given ``hash`` table must have
#   the nested structure as the ones created by config_ini_.
#--
config_ini_get ()
{
    if [[ $# = 3 ]] ; then
        hash_get $(hash_get "$1" "[$2]") "$3"
    else
        hash_get "$1" "[$2]"
    fi || true
}


#++ config_ini_get_chained hash section fallback key default
#
#   Obtains a value associated with the given *key* of a *section*. If the
#   key does not exist in the *section*, it will be looked up in the
#   alternative *fallback* section, and if not given then the *default*
#   value is printed out.
#--
config_ini_get_chained ()
{
    local v=""

    if hash_has "$1" "[$2]" ; then
        local h=$(hash_get "$1" "[$2]")
        if hash_has "$h" "$4" ; then
            v=$(hash_get "$h" "$4")
        fi
    fi

    if [ -z "$v" ] && hash_has "$1" "[$3]"
    then
        local h=$(hash_get "$1" "[$3]")
        if hash_has "$h" "$4" ; then
            v=$(hash_get "$h" "$4")
        fi
    fi

    echo "${v:-${5:-}}"
}


#++ config_ini_clear hash
#
#   Disposes keys and values in a hash table hierarchy as created by
#   config_ini_.
#--
config_ini_clear ()
{
    local -ar keys=( $(hash_keys "$1" ) )
    local key

    for key in "${keys[@]}" ; do
        hash_clear "$key"
    done
    hash_clear "$1"
}

