#! /usr/bin/env bill
#++
#   ===================
#   String manipulation
#   ===================
#   :Author: Adrián Pérez <aperez@udc.es>
#   :Copyright: Igalia S.L., 2008
#   :License: GPL v2
#   :Abstract: Provides common functions used to manipulate text strings.
#
#   .. contents::
#--

need tr || die "Needed program 'tr' not found (no coreutils?)"


#++ string_upper text
#
#   Converts a string to upper case.
#--
string_upper ()
{
    tr '[a-z]' '[A-Z]' <<< "$*"
}


#++ string_lower text
#
#   Converts a string to lower case.
#--
string_lower ()
{
    tr '[A-Z]' '[a-z]' <<< "$*"
}


#++ string_length text
#
#   Obtains the length of a string.
#--
string_length ()
{
    local -r joined="$*"
    echo "${#joined}"
}


#++ string_startswith text prefix
#
#   Checks whether a string starts with a given prefix. Exit status is
#   non-zero if the condition is not met.
#--
string_startswith ()
{
    local -r prefix_length=$(string_length "$2")
    [[ ${1::$prefix_length} = $2 ]]
}


#++ string_endswith text suffix
#
#   Checks whether a string ends with a given suffix. Exit status is
#   non-zero if the condition is not met.
#--
string_endswith ()
{
    local -r suffix_length=$(string_length "$2")
    [[ ${1:$(( ${#1} - suffix_length))} = $2 ]]
}


#++ string_ascii_code text [ format ]
#
#   Returns the ASCII code of the first character of the a string. Output is
#   in decimal by default, but the behaviour can be changed by passing the
#   ``format`` option, whose valid values are:
#
#   * ``d`` for decimal output (default).
#   * ``x`` for lowercase hexadecimal output.
#   * ``X`` for uppercase hexadecimal output.
#   * ``o`` for octal output.
#--
string_ascii_code ()
{
    local -r format=${2:-d}
    printf "%${format::1}" "'${1::1}"
}


#++ string_ascii text [ separator ] [ format ]
#
#   Returns ASCII codes for *all* characters in a string. Output is in
#   decimal by default, but format can be changed using the same specifiers
#   as for the string_ascii_code_ function. ASCII codes will be separated
#   using the given ``separator`` string. You can pass an empty string to
#   join the ASCII codes.
#--
string_ascii ()
{
    local -r length=$(string_length "$1")
    local -r sep=${2:-' '}
    local format=${3:-d}
    local i

    printf "%${format::1}" "'${1:0:1}"
    format="%s%${format::1}"
    for (( i = 1; i < $length; i++ )) ; do
        printf "$format" "$sep" "'${1:$i:1}"
    done
}


#++ string_contains text substring
#
#   Checks whether the given strings contains a substring inside it. Exit
#   status is non-zero if the condition is not satisfied.
#--
string_contains ()
{
    # Quite trivial...
    [[ $2 = *$1* ]]
}


#++ string_join separator [ string1 [ string2 ... [ stringN ] ] ]
#
#   Concatenates all given strings into a single one using the specified
#   separator.
#--
string_join ()
{
    local -r saved_IFS=$IFS
    IFS=$1
    shift
    echo "$*"
    IFS=$saved_IFS
}


#++ string_lstrip
#
#   Removes blank characters from the start of lines of the given
#   text. Works like a filter, using both standard input and
#   output.
#--
string_lstrip ()
{
    sed -e 's,^[[:space:]]*,,'
}


#++ string_rstrip
#
#   Removes blank characters from the end of lines of the given
#   text. Works like a filter, using both standard input and
#   output.
#--
string_rstrip ()
{
    sed -e 's,[[:space:]]*$,,'
}


#++ string_strip
#
#   Removes blank characters *both* from the end and the start of lines
#   given. Works like a filter, using both standard input and output.
#--
string_strip ()
{
    sed -e 's,^[[:space:]]*,,' \
        -e 's,[[:space:]]*$,,'
}

