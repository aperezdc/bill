#! /usr/bin/env bill
#++
#   ============================
#   Utilities for the TWiki wiki
#   ============================
#   :Author: Adrian Perez <aperez@igalia.com>
#   :License: GPL3
#   :Copyright: 2008-2009 Igalia S.L.
#   :Abstract: Functions for performing operations on TWiki instances.
#
#   .. contents::
#--

use data/time

need ci co || die "Need RCS commands not found"
need stat  || die "Utility 'stat' not found"

#++ twiki_attach twikidir pagename filename [ attachname ]
#--
twiki_attach ()
{
    local -r twiki=$1
    local -r page=$2
    local -r path=$3

    if [ ! -r "$twiki/data/$page.txt" ]
    then
        warn "Page '$page' does not exist"
        return 1
    fi

    mkdir -p "$twiki/pub/$page"

    # Sanitize:
    #   1. Backslashes to forward slashes
    #   2. Spaces to underscores
    #   3. Keep only file name
    local s_name=${path//\\/\/}
    s_name=${s_name// /_}
    s_name=${s_name##*/}

    local a_name=$4
    if [ "$a_name" ]
    then
        # Sanitize this one as well
        a_name=${a_name//\\/\/}
        a_name=${a_name// /_}
        a_name=${a_name##*/}
    else
        a_name=$s_name
    fi

    if [ "$NOCLOBBER" ] && $NOCLOBBER &> /dev/null
    then
        local count=1
        local o_name=$a_name

        while [ -r "$twiki/pub/$page/$a_name" ]
        do
            a_name="$o_name.$count"
            (( count++ ))
        done
    fi

    # Add file to twiki data dir
    cp "$path"         "$twiki/pub/$page/$a_name"
    ci -q -t-"$a_name" "$twiki/pub/$page/$a_name"
    co -q              "$twiki/pub/$page/$a_name"
    chmod +w           "$twiki/pub/$page/$a_name"

    # Get file infos
    local -r filesize=$(stat -c '%s' "$path")
    local -r filedate=$(stat -c '%Y' "$path")

    # Check out a locked copy of the page text, add the metainfo, commit the
    # changes and do a checkout to leave in-place.
    rm    -f "$twiki/data/$page.txt"
    co -q -l "$twiki/data/$page.txt"

     ( printf "%%META:FILEATTACHMENT{name=\"$a_name\" "
       printf "attachment=\"$a_name\" attr=\"\" comment=\"$a_name\" "
       printf "date=\"$filedate\" path=\"$a_name\" size=\"$filesize\" "
       printf "stream=\"$a_name\" tmpFilename=\"$path\" "
       printf "user=\"admin\" version="1"}%%\n"
     ) >> "$twiki/data/$page.txt"

     ci -q -m"Add $a_name" "$twiki/data/$page.txt"
     co -q -l              "$twiki/data/$page.txt"
}


#++ twiki_page_checkout twiki pagename
#--
twiki_page_checkout ()
{
    local path="$1/data/$2.txt"
    rm -f    "${path}"
    co -q -l "${path}"
}


#++ twiki_page_new twiki pagename [comment]
#
#   Fails with non-zero exit status if page already exists.
#--
twiki_page_new ()
{
    local path="$1/data/$2.txt"
    if [[ -r ${path},v ]] ; then
        return 1
    fi

    # Touch the page and add minimum amount of meta-data.
    ( printf '%%META:TOPICINFO{author="admin" date="%i"' $(time_format %s)
      printf ' format="1.1" reprev="1.1" version="1.1"}%%\n' ) > "${path}"

    # Save initial revision
    twiki_page_commit "$@"
}


#++ twiki_page_commit twiki pagename [comment]
#--
twiki_page_commit ()
{
    local path="$1/data/$2.txt"

    if [[ ! -r ${path},v ]] ; then
        ci -q -m"${3:-$(date)}" -t-'Twiterator Iteration' "${path}"
    else
        ci -q -m"${3:-$(date)}" "${path}"
    fi
    co -q -l "${path}"
}


#++ twiki_page_path twiki pagename
#--
twiki_page_path ()
{
    echo "$1/data/$2.txt"
}


main twiki_attach "$@"
