#! /usr/bin/env bill
#++
#   ================================
#   bURL - TinyURL clone as a Billet
#   ================================
#   :Author: Adrián Pérez <aperez@igalia.com>
#   :Copyright: 2008-2009 Igalia S.L.
#   :License: GPL3
#   :Abstract: Simple implementation of a TinyURL-like service.
#       This is an example of how to write a Billet, and it is used as
#       reference in the Billets tutorial.
#--

use text/string


if need openssl
then
    burl_hash () {
        openssl sha1 <<< "$1"
    }
elif need sha1sum
then
    burl_hash () {
        local -a result
        result=( $(sha1sum <<< "$1") )
        echo "${result[0]}"
    }
else
    die "No hashing command found, either install openssl or sha1sum"
fi


#++ burl_init store
#--
burl_init ()
{
    [[ -d $1 ]] || mkdir -p "$1"
}

#++ burl_add store url
#--
burl_add ()
{
    local sum cur_len max_len fname

    sum=$(burl_hash "$2")
    max_len=$(string_length "${sum}")

    for (( cur_len = 4 ; cur_len <= max_len ; cur_len++ ))
    do
        fname=${sum::${cur_len}}
        [ -r "$1/${fname}" ] || break
    done
    echo "$2" > "$1/${fname}"
    echo "${fname}"
}


#++ burl_find store key
#--
burl_find ()
{
    [ -r "$1/$2" ] || return 0
    printf '%s\n' "$(< "$1/$2")"
}



