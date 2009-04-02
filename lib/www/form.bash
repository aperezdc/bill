#! /usr/bin/env bill
#++
#   =============================
#   Handles HTML form submissions
#   =============================
#   :Author: Adrián Pérez <aperez@igalia.com>
#   :Copyright: 2008-2009 Igalia S.L.
#   :License: GPL3
#   :Abstract: Handles input in the formats provided by HTML forms.
#       This includes submissions in the ``multipart/form-data`` and
#       ``application/x-www-form-urlencoded`` encodings. This functionality
#       is typically needed in CGI scripts.
#
#   .. contents::
#--

use text/mime
use text/string
use data/hash

need csplit head mkdir || die "One of csplit, head, or mkdir is missing"


#++ form_urldecode hash
#
#   Reads data in a line-by-line basis from standard input, performs
#   URL-like decoding as defined in `RFC 1945
#   <http://http://www.w3.org/Protocols/rfc1945/rfc1945>`__ and sends
#   it decoded to standard output.
#--
form_urldecode ()
{
    local -r saved_IFS=$IFS
    local key val line item

    while read line
    do
        IFS='&'
        for item in $line
        do
            key=${item%%=*}
            val=${item#*=}
            key=${key//\\/\\\\}
            val=${val//\\/\\\\}
            printf -v key "${key//\%/\\x}"
            printf -v val "${val//\%/\\x}"
            hash_set $1 "$key" "$val"
        done
        IFS=$saved_IFS
    done
}


#++ form_multipart_handle directory
#
#   Decodes standard input in ``multipart/form-data`` encoding to multiple
#   files in a directory. The directory will be laid out as follows, for
#   a directory named ``output``:
#
#   ``output/pack``
#       File containing the  unprocessed input, minus the marker present
#       at the last line.
#   ``output/raw/*``
#       Each file inside this directory is an unprocessed part of the input.
#   ``output/body/*``
#       Each file inside this directory contains the bodies of the parts.
#   ``output/headers/*``
#       Each file inside this directory contains the MIME headers of each
#       part.
#
#   For example, the first part will be named ``00`` (double-zero),
#   ``output/raw/00`` would be the unprocessed part, ``output/body/00``
#   its content body and ``output/headers/00`` the corresponding MIME
#   headers. Each part is decoded using the mime_decode_ function.
#
#   .. _mime_decode: mime.html#mime-decode
#--
form_multipart_handle ()
{
    mkdir -p "$1"/{raw,body,headers}

    # Dump input to file, removing last line. Last line is the same as the
    # marker (the first one) but with two dashes appended. It is unneeded
    # due to the hacky nature of this decoder :P
    head -n -1 > "$1/pack"

    # Read back boundary marker string.
    local -r marker=$(head -1 "$1/pack")

    # Split up parts in components
    csplit -q -z -f "$1/raw/" "$1/pack" "/^$marker/" '{*}'

    local name

    for name in "$1/raw"/*
    do
        local cook=${name##*/}
        # XXX The head invocation is needed to remove the trailing "\r\n" of
        # the input as given in the multipart form data.
        head -c -2 "$name" | mime_decode "$1/headers/$cook" > "$1/body/$cook"
    done
}



#++ form_handle hash [ tmpdir ]
#
#   Handles input if a HTML form, either from a ``POST`` or ``GET`` request.
#   In both cases the query string will be stored in the *hash* table.
#   When handling ``POST`` requests you may also want to
#   provide a temporary directory ``tmpdir``, otherwise ``/tmp`` will be
#   always used. Data stored in ``hash`` can be accessed using the
#   functions in the `data/hash <../data/hash.html>`_ module.
#--
form_handle ()
{
    : ${CONTENT_TYPE:='application/x-www-form-urlencoded'}
    : ${REQUEST_METHOD:='GET'}

    REQUEST_METHOD=$(string_upper "${REQUEST_METHOD}")

    # Always parse the query string into a hash map.
    #
    form_urldecode $1 <<< "$QUERY_STRING"

    # When
    case ${REQUEST_METHOD} in
        GET)
            # No extra work needed for GET requests.
            true
            ;;
        POST)
            # If we get a URL-encoded body, add its variables into the hash,
            # otherwise handle things over to form_multipart_handle
            #
            case ${CONTENT_TYPE} in
                application/x-www-form-urlencoded)
                    form_urldecode $1
                    ;;
                multipart/form-data)
                    form_multipart_handle "${2:-'/tmp'}"
                    ;;
                *)
                    die "Unsupported CONTENT_TYPE"
                    ;;
            esac
            ;;
        *)
            die "REQUEST_METHOD is not POST or GET"
            ;;
    esac
}


main form_handle "$@"

