#! /usr/bin/env bill
#++
#   =============================
#   Handling of terminal consoles
#   =============================
#   :Author: Adrián Pérez <aperez@igalia.com>
#   :License: GPL3
#   :Copyright: 2008-2009 Igalia S.L.
#   :Abstract: Handles settings of standard Unix terminal console devices.
#       Provides support for nicer handling of features like ECMA-48 (ANSI)
#       color codes.
#
#   .. contents::
#
#--

#++
#   ECMA-48 graphics rendition
#   ==========================
#   Support for using ECMA-48 escape sequences (also known as ANSI color
#   escapes) is provided by using tty_color_fg_, tty_color_bg_ and other
#   related functions.
#
#   Typical usage
#   -------------
#   There are some usage patterns which you may want to know prior to start
#   using the module. The most important one follows the *avoid doing the
#   same operation twice* motto: calling tty_color_fg_ and tty_color_bg_ is
#   not cheap in terms of efficiency, but their result can be saved for
#   later use. So instead of:
#
#   .. sourcecode:: bash
#
#       echo "$(tty_color_fg red) This is RED $(tty_color_fg reset)"
#       echo "$(tty_color_fg red) This one too... $(tty_color_fg reset)"
#
#   it is better to save results in variables and reuse the values:
#
#   .. sourcecode:: bash
#
#       red=$(tty_color_fg red)
#       reset=$(tty_color_fg reset)
#       echo "$red This is RED $reset"
#       echo "$red This one too... $reset"
#
#   This way your scripts will run faster and your code will be cleaner.
#--

#++
#   Functions
#   =========
#--

use data/map

__tty_color_fg=(
    reset       0
    bold        1
    half        2
    blink       5
    reverse     7
    normal     22
    no-blink   25
    no-reverse 27

    black      30
    red        31
    green      32
    brown      33
    blue       34
    magenta    35
    cyan       36
    white      37
)

__tty_color_bg=(
    reset       0
    bold        1
    half        2
    blink       5
    reverse     7
    no-blink   25
    no-reverse 27

    black      40
    red        41
    green      42
    brown      43
    blue       44
    magenta    45
    cyan       46
    white      47

    default    49
)

__tty_color_alias=(
    yellow  brown
    fucsia  magenta
    pink    magenta
    teal    cyan
    aqua    cyan
    silver  white
)

declare -ar __tty_color_alias __tty_color_bg __tty_color_fg


#++ tty_color_alias colorname
#
#   Obtains the real color for a given color name, resolving aliases as
#   needed.
#
#   .. note:: In the current implementation only **one** level of
#      indirection is resolved. That should be enough for all cases.
#--
tty_color_alias ()
{
    local -r name=$(map_get __tty_color_alias "$1")
    echo "${name:-$1}"
}


#++ tty_color_fg attribute1 [ attribute2 [ ... attributeN ] ]
#
#   Obtains the ECMA-48 escape sequence needed to apply a determinate
#   graphics rendition in the foreground. The escape sequence will apply
#   *all* the given attributes. See `typical usage`_ above for tips on
#   how to use this function.
#--
tty_color_fg ()
{
    local attr
    while [ "$1" ]
    do
        attr=$(map_get __tty_color_fg "$(tty_color_alias "$1")")
        [ "$attr" ] && printf '[%sm' "${attr}"
        shift
    done
}


#++ tty_color_bg attribute1 [ attribute2 [ ... attributeN ] ]
#
#   Obtains the ECMA-48 escape sequence needed to apply a determinate
#   graphics rendition in the background. The escape sequence will apply
#   *all* the given attributes. See `typical usage`_ above for tips on
#   how to use this function.
#--
tty_color_bg ()
{
    local attr
    while [ "$1" ]
    do
        attr=$(map_get __tty_color_bg "$(tty_color_alias "$1")")
        [ "$attr" ] && echo -n $'\e['"${attr}m"
        shift
    done
}


tty_begin () {
    echo -n "${__tty_green} *${__tty_reset} %s ... "
} > /dev/tty


tty_end () {
    local ret=${1:-$?}

    if [[ $ret -eq 0 ]]
    then ret="${__tty_green}done"
    else ret="fail"
    fi
    echo "${ret}${__tty_reset}\n"
} > /dev/tty

