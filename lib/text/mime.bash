#! /usr/bin/env bill
#++
#   ==================
#   Handling MIME data
#   ==================
#   :Author: Adrián Pérez <aperez@igalia.com>
#   :Copyright: 2008-2009 Igalia S.L.
#   :License: GPL3
#   :Abstract: Provides tools for handling MIME-encoded data.
#       The format is defined in RFCs number
#       `822 <http://www.ietf.org/rfc/rfc822.txt>`__ and
#       `2822 <http://www.ietf.org/rfc/rfc2822.txt>`__.
#
#   .. contents::
#--

need sed grep cat || die "grep, sed or cat are missing"

use text/string

__mime_CR=$'\015'
declare -r __mime_CR

# Define the regular expressions we will be using:
#
__mime_header_re='[[:space:]]*([a-zA-Z_ -]+):[[:space:]]*(.*)'
__mime_continuation_re='[[:space:]]+(.*)'

if [[ ${BASH_VERSINFO[0]} -le 3 && ${BASH_VERSINFO[1]} -le 1 ]] ; then
    __mime_header_re="'${__mime_header_re}'"
    __mime_continuation_re="'${__mime_continuation_re}'"
fi

declare -r __mime_header_re
declare -r __mime_continuation_re


#++ mime_decode hash < input > output-body
#
#   Interprets a set of MIME-like headers given as standard input and stores
#   them parsed into a hash table. The MIME convention of stop parsing when
#   an empty line is found is honored. Multi-line headers are properly
#   recognized, as well as multiple header instances, which are handled
#   somewhat gracefully: their values are stored under a single hash table
#   key, appended with commas (this is specified in the standard, but no
#   quoting is done, though). Header names are all converted to lowercase
#   when storing them in the hash table.
#
#   As an example, you could extract headers from an e-mail, saving the body
#   to another file using the following technique:
#
#   .. sourcecode:: bash
#
#       h=$(hash_new)
#       mime_decode $h < input-email > output-body
#
#--
mime_decode ()
{
    local line key='' val
    local old_ifs=${IFS}
    IFS=''

    while read -r line ; do
        IFS=${old_ifs}
        # Found a blank line: stop reading.
        if [[ ${line} = ${__mime_CR} || -z ${line} ]] ; then
            break
        fi

        # Strip carriage returns
        line=${line%${__mime_CR}}
        if eval "[[ \${line} =~ ${__mime_header_re} ]]" ; then
            if [[ -n ${key} && ${key} != ${BASH_REMATCH[1]} ]] ; then
                if hash_has $1 "${key}" ; then
                    # Append value with a comma
                    hash_set $1 "${key}" "$(hash_get $1 "${key}"), ${val}"
                else
                    hash_set $1 "${key}" "${val}"
                fi
            fi
            key=$(string_lower "${BASH_REMATCH[1]}")
            val=${BASH_REMATCH[2]}
            val=${val%${val##*[![:space:]]}}
        elif eval "[[ \${line} =~ ${__mime_continuation_re} ]]" ; then
            val="${val} ${BASH_REMATCH[1]}"
            val=${val%${val##*[![:space:]]}}
        fi
        IFS=''
    done
    IFS=${old_ifs}

    if [[ -n ${key} ]] ; then
        if hash_has $1 "${key}" ; then
            # Append value with a comma
            hash_set $1 "${key}" "$(hash_get $1 "${key}"), ${val}"
        else
            hash_set $1 "${key}" "${val}"
        fi
    fi

    # This lone cat handles passing stdin->stdout
    cat
}


