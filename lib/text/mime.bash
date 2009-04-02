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

declare -r __mime_CR=$'\015'


#++ mime_decode [ headersfile ]
#
#   Takes the standard input as a MIME-formatted message. Headers are sent
#   to the file specified as *headersfile*, or to standard error if not
#   specified (more exactly to ``/dev/stderr``). Headers will be converted
#   to shell variables so you can ``source`` the resulting file in your
#   code. Header names are converted as follows:
#
#   1. The header name is converted to lowercase.
#   2. Characters in the ``A-Z`` range and underscores are left as-is.
#   3. All other characters are changed to underscrores.
#   4. The header name is prefixed with ``H_``.
#
#   The header value is kept in its original form. Only trailing whitespace
#   is removed from multiline header values.
#
#   The contents of the body of the MIME message are send unchanged to
#   standard output.
#
#   As an exaple, consider decoding the follow e-mail content::
#
#       From: Adrian Perez <aperez@igalia.com>
#       To: Ella Fitzgerald <fitzgerald@divas.net>,
#           Maestro Manggiacapprini <m-m@capprini.com>
#       Subject: Bash rules!
#       Content-Type: text/plain
#
#       Hello pals!
#
#       We will be having a meeting tomorrow at 8:00 PM. Do not forget
#       to bring your notes regarding current musical trends.
#
#   That would output the following in the headers file:
#
#   .. sourcecode:: bash
#
#       H_from='Adrian Perez <aperez@igalia.com>'
#       H_to='Ella Fitzgerald <fitzgerald@divas.net>, Maestro Manggiacapprini <m-m@capprini.com>'
#       H_subject='Bash rules!'
#       H_content_type='text/plain'
#
#--
mime_decode ()
{
    local line key value
    local headersfound=false
    local -r metafile=${1:-/dev/stderr}

    # Empty up metafile.
    : > "$metafile"

    while read line
    do
        line=${line%${__mime_CR}}

        if [[ $line =~ ^[^:]+: ]]
        then
            # Line has a header name. If this is not the first one, print
            # the previous one to the metafile.
            [ "$key" ] && printf "H_$key=%q\n" "$value" >> "$metafile"

            # Now prepare to read the current header storing its initial
            # value.
            headersfound=true
            key=${line%:*}
            key=$(string_lower "${key//[^A-Za-z_]/_}")

            # TODO Change this to avoid piping through sed
            value=$(echo "${line#*:}" | sed -e 's:^[[:space:]]*::')
        elif [ -z "$line" ]
        then
            # Skip bogus lines.
            $headersfound || continue

            # Input ended, stop the look and hand off output... but be careful
            # to output the last read header before!
            [ "$key" ] && printf "H_$key=%q\n" "$value" >> "$metafile"
            break
        else
            # Line is a continuation of the previous header value. Note that
            # we must remove trailing whitespace.
            value="${value}$(sed -e 's:^[[:space:]]*: :' <<< "$line")"
        fi
    done

    # Dump remaining input to standard output.
    cat
}


main mime_decode "$@"
