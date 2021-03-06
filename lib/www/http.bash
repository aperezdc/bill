#! /usr/bin/env bill
#++
#   ==================
#   Simple HTTP server
#   ==================
#   :Author: Adrian Perez <aperez@igalia.com>
#   :License: GPL3
#   :Copyright: 2008-2009 Igalia S.L.
#   :Abstract: Provides a not-so-basic standalone web server.
#       Socket functionality is **not** provided. Requests are
#       read from standard input, responses are sent to standard
#       output and logging is done the standard error stream.
#
#   .. contents::
#--

use text/string

need date || die "The 'date' program was not found"
need sed  || die "The 'sed' program was not found"
need cat  || die "The 'cat' program was not found"

#++
#   Running a webserver
#   ===================
#   Fortunately, dealing with sockets can be done in pure Bash [#]_.
#   Unfortunately enough, some distributors choose not to enable support for
#   this feature. This is the case of the Bash builds included with Debian_
#   and Ubuntu_.
#
#   .. [#] http://unixjunkie.blogspot.com/2006/01/two-cool-bash-tricks.html
#   .. _debian: http://debian.org
#   .. _ubuntu: http://ubuntulinux.org
#
#
#   Using auxiliar tools
#   --------------------
#   Some utilities exist which allow nearly all program
#   using the standard input and output streams to use sockets. It is likely
#   that at least one of these is available for your operating system of
#   choice. All those examples run a simple web server listening in port
#   ``8000`` at ``127.0.0.1`` (the loopback network address). Once you try
#   one of those command lines, point a browser to http://localhost:8000/doc
#   and you will be able of browsing the Bill documentation using the simple
#   built-in web server.
#
#   .. class:: tabular
#
#   ========== =============================================================
#   Package    Command
#   ========== =============================================================
#   ipsvd_     ``tcpsvd 127.0.0.1 8000 ./scripts/bill lib/www/http.bash``
#   ucspi-tcp_ ``tcpserver -q 127.0.0.1 8000 ./scripts/bill lib/www/http.bash``
#   netcat_    ``(while true ; do nc -l -p 8000 -c './scripts/bill lib/www/http.bash'; done)``
#   netpipes_  ``faucet 8000 -H 127.0.0.1 -i -o ./scripts/bill lib/www/http.bash``
#   ========== =============================================================
#
#   .. _ipsvd: http://smarden.org/ipsvd/
#   .. _ucspi-tcp: http://cr.yp.to/ucspi-tcp.html
#   .. _netcat: http://netcat.sourceforge.net/
#   .. _netpipes: http://web.purplefrog.com/~thoth/netpipes/netpipes.html
#
#   .. note:: Commands should be run from the top-level Bill source
#       directory, otherwise they may not work.
#
#   .. warning:: The netcat_ command is very flaky, it will not accept
#       concurrent connections, and in general will perform poorly.
#--

#++
#   Functions
#   =========
#--

http_debug () {
    if [ "$HTTP_DEBUG" ] ; then
        local -r format="(http) $1\n"
        shift
        printf "$format" "$@"
    fi
} 1>&2


#++ http_response_by_code code
#
#   Obtains the descriptive text for the given HTTP response status code.
#   The strings returned are those specified in the code list contained in
#   `RFC 2068 <http://www.ietf.org/rfcs/rfc2068>`_.
#--
http_response_by_code ()
{
    # HTTP/1.1 response code listing from RFC 2068
    local C='Unknown HTTP code'
    case $1 in
        100) C='Continue'                      ;;
        101) C='Switching Protocols'           ;;
        200) C='OK'                            ;;
        201) C='Created'                       ;;
        202) C='Accepted'                      ;;
        203) C='Non-Authoritative Information' ;;
        204) C='No Content'                    ;;
        205) C='Reset Content'                 ;;
        206) C='Partial Content'               ;;
        300) C='Multiple Choices'              ;;
        301) C='Moved Permanently'             ;;
        302) C='Moved Temporarily'             ;;
        303) C='See Other'                     ;;
        304) C='Not Modified'                  ;;
        400) C='Bad Request'                   ;;
        401) C='Unauthorized'                  ;;
        402) C='Payment Required'              ;;
        403) C='Forbidden'                     ;;
        404) C='Not Found'                     ;;
        405) C='Method Not Allowed'            ;;
        406) C='Not Acceptable'                ;;
        407) C='Proxy Authentication Required' ;;
        408) C='Request Time-out'              ;;
        409) C='Conflict'                      ;;
        410) C='Gone'                          ;;
        411) C='Length Required'               ;;
        412) C='Precondition Failed'           ;;
        413) C='Request Entity Too Large'      ;;
        414) C='Request-URI Too Large'         ;;
        415) C='Unsupported Media Type'        ;;
        500) C='Internal Server Error'         ;;
        501) C='Not Implemented'               ;;
        502) C='Bad Gateway'                   ;;
        503) C='Service Unavailable'           ;;
        504) C='Gateway Timeout'               ;;
        505) C='HTTP Version Not Supported'    ;;
    esac
    echo "$C"
}



__http_CR=$'\015'
__http_server="bash/${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}"
__http_server="${__http_server} bill-www-http/$BILL_VERSION"

declare -r __http_CR __http_server


#++ http_mimetype_guess path
#
#   Determines MIME types depending on the entries of a hash map named
#   ``http_mime_mapping``, which contains a default set of entries which
#   suffice for serving the Bill documentation. The suffix of the file
#   pointed by ``path`` is used to determine its content type.
#
#   For example:
#
#   .. sourcecode:: bash
#
#       (bill) http_mimetype_guess /etc/sysctl.conf
#       text/plain
#
#--

# FIXME: Guess out why "file" does get CSS types well.
if need file && false
then
    http_mimetype_guess ()
    {
        file -ib "$1"
    }
else
    http_mimetype_guess ()
    {
        local m='application/octet-stream'
        case ${1##*.} in
            bash | txt | rst | conf ) m='text/plain' ;;
            jpg | jpe | jpeg) m='image/jpeg' ;;
            png) m='image/png' ;;
            html) m='text/html' ;;
            htm) m='text/html' ;;
            css) m='text/css' ;;
        esac
        echo "$m"
    }
fi


#++ http_error_document [ code [ description ... ] ]
#
#   Generates an error document in standard output:
#
#   * ``code`` is the HTTP error code (default is ``500``)
#   * ``description`` is an arbitrary piece of text which will be inserted
#     pre-formatted in the output.
#
#--
http_error_document ()
{
    local -r mess=$(http_response_by_code $1)
    shift
    local desc=$(string_join $'\n' "$@")
    [[ -z $desc ]] && desc='No additional information supplied'

    # XXX Warning, tab-indented lines follow for the here-document
    cat <<-EOF
	<html>
	  <head>
		<title>Error: ${mess}</title>
		<style type="text/css">
		pre {
			font-family: monospace;
			background: #f8f8f8;
			border: 1px solid #eee;
			padding: 1em;
		}
		</style>
	  </head>
	  <body>
		<h1>${mess}</h1>
		<p>Additional information:</p>
		<pre>${desc}</pre>
	  </body>
	</html>
	EOF
}



declare -i __HTTP_RESPONSE=666
declare    __HTTP_HEADER_SENT=true
declare    __HTTP_DATE_HEADER=false
declare    __HTTP_SERVER_HEADER=false
declare    __HTTP_CONTENT_LENGTH='-'
declare    __HTTP_CONNECTION_HEADER=false


#++ http_header name value
#
#   Sends an HTTP header.
#--
http_header ()
{
    $__HTTP_HEADER_SENT && die "HTTP headers already sent"

    [[ $1 = [Cc]ontent\ [Ll]ength ]] && __HTTP_CONTENT_LENGTH=$2
    [[ $1 = [Cc]onnection ]] && __HTTP_CONNECTION_HEADER=true
    [[ $1 = [Ss]erver ]] && __HTTP_SERVER_HEADER=true
    [[ $1 = [Dd]ate ]] && __HTTP_DATE_HEADER=true

    printf "%s: %s\r\n" "$1" "$2"
}


#++ http_header_start [ code [ description ] ]
#--
http_response ()
{
    $__HTTP_HEADER_SENT || die "Cannot reinit an HTTP reponse"

    __HTTP_RESPONSE=${1:-200}
    local -r mess=${2:-$(http_response_by_code "$__HTTP_RESPONSE")}
    # FIXME Currently responses are only HTTP 1.0
    printf "HTTP/1.0 %s %s\r\n" "$__HTTP_RESPONSE" "$mess"
    __HTTP_HEADER_SENT=false
}


#++ http_date_now
#
#   Returns the current GMT time in RFC 1123 format, as needed for
#   response HTTP headers.
#--
http_date_now ()
{
    LANG='' LC_ALL='' date --utc '+%a, %d %b %Y %T GMT'
}


#++ http_body
#
#   Prepares the HTTP connection to send content body.
#--
http_body ()
{
    $__HTTP_HEADER_SENT && die "Cannot reinit an HTTP response"
    $__HTTP_DATE_HEADER || http_header Date "$(http_date_now)"
    $__HTTP_SERVER_HEADER || http_header Server "${__http_server}"
    $__HTTP_CONNECTION_HEADER || http_header Connection close
    printf "\r\n"

    # For 1xx, 204 & 304 codes: do not allow sending further output.
    case $__HTTP_RESPONSE in
        1?? | 204 | 304) exec 1>&- ;;
    esac

    # Restore to initial values:
    __HTTP_HEADER_SENT=true
    __HTTP_DATE_HEADER=false
    __HTTP_SERVER_HEADER=false
    __HTTP_CONTENT_LENGTH='-'
    __HTTP_CONNECTION_HEADER=false
}


#++ http_error [ code [ description ... ] ]
#
#   Sends an HTTP error status code and an accompanying HTML document
#   explaining the error. Error document is formatted using
#   http_error_document_.
#--
http_error ()
{
    http_response "$1"
    http_header Content-Type text/html
    http_header Connection close
    http_body
    http_error_document "$@"
}


#++ http_redirect uri [ code ]
#
#   Sends an HTTP redirection, to the given ``uri``. If not supplied, the
#   ``code`` will be ``302`` (a permanent redirect). You can pass ``301``
#   for temporary redirects. Keep in mind that using absolute paths in
#   redirects is recommended.
#--
http_redirect ()
{
    http_response "${2:-302}"
    http_header Location "$1"
    http_body
}


#++ http_log_clf [ status ]
#
#   Logs a line of output to standard error in CLF__ format::
#
#      host ident authuser date request status bytes
#
#   __ http://en.wikipedia.org/wiki/Common_Log_Format
#
#   Note that the “ident” field will always be empty. The field
#   “address” will be empty when the remote IP cannot be guessed.
#   The field “bytes” will be empty as well unless the
#   ``Content-Length`` is set with http_header_.
#--
http_log_clf ()
{
    printf '%s - %s [%s] "%s %s %s" - %s %s\n'      \
        "${REMOTE_ADDR:--}" "${REMOTE_USER:--}"      \
        "$(LC_ALL='' LANG='' date '+%d/%b/%Y:%T %z')" \
        "$REQUEST_METHOD" "$PATH_INFO" "$HTTP_VERSION" \
        "${__HTTP_RESPONSE:--}" "${__HTTP_CONTENT_LENGTH:--}"
} 1>&2



declare -r http_directory_template='#! local var_i
<html>
  <head>
    <title>${path}</title>
  </head>
  <body>
    <h1>${path}</h1>
    <ul>
    $([ "${path}" = "/" ] || echo "<li><a href=\\\"../\\\">[up]</a></li>")
    $(for var_i in ".${path}"* ; do \
        echo "<li><a href=\\\"${i:1}\\\">${i#.${path}}</a></li>" ; \
    done)
    </ul>
  </body>
</head>'


#++ http_handle_GET
#
#   Default handler for the HTTP ``GET`` method. This does nothing more than
#   serving static files and producing directory listings. Also, if path
#   resolves to a directory which contains a file named ``index.html`` it
#   will be served instead.
#--
http_handle_GET ()
{
    local isdir=false

    if ! [ -r "./$PATH_INFO" ]
    then
        http_error 404 "path=$PATH_INFO"
        return 1
    fi

    if [ -d "./$PATH_INFO" ]
    then
        if ! string_endswith "$PATH_INFO" "/"
        then
            http_redirect "$PATH_INFO/"
            return
        fi

        if [ -r "./$PATH_INFO/index.html" ]
        then
            PATH_INFO="${PATH_INFO}/index.html"
        else
            isdir=true
        fi
    fi

    http_response
    if $isdir
    then
        use text/template # This is loaded on-demand the first time
        http_header Content-Type "text/html; encoding=utf-8"
        http_body
        var_path=$PATH_INFO template_expand <<< "$http_directory_template"
    else
        http_header Content-Type "$(http_mimetype_guess "./$PATH_INFO")"
        http_body
        cat "./$PATH_INFO"
    fi
}


#++ http_handle_request [ handler_prefix ]
#
#   Serves a single HTTP request. The following variables are set by the
#   function and their values **will be clamped** if already defined. Note
#   that most of them start with the ``HTTP_`` prefix or have names of the
#   variables used by the `CGI interface`_:
#
#   * REQUEST_METHOD
#   * PATH_INFO
#   * QUERY_STRING
#   * ...and so on.
#
#   .. _cgi interface: http://www.w3.org/CGI/
#
#   The ``handler_prefix`` can be used to change behavior of how requests
#   are served. It is used to find which functions are used to serve the
#   different HTTP methods. As an example, one could define:
#
#   .. sourcecode:: bash
#
#       my_handler_GET () {
#           # Do something interesting...
#       }
#       my_handler_HEAD () {
#           # ...and something *even* more interesting.
#       }
#
#   and then use ``my_handler`` as prefix, then the HTTP request hadler will
#   pass ``GET`` to ``my_handler_GET`` and ``HEAD`` ones to
#   ``my_handler_HEAD``. This allows for easily reusing the HTTP module.
#--
http_handle_request ()
{
    local -r prefix=${1:-'http_handle'}

    http_debug 'Handler prefix: %s' "$prefix"

    # Use CGI variables as log as possible, so interfacing with external
    # CGIs will be easier.
    #
    local REQUEST_METHOD PATH_INFO QUERY_STRING HTTP_VERSION
    local readmore line key val

    read REQUEST_METHOD PATH_INFO HTTP_VERSION
    # String annoying carriage return characters
    REQUEST_METHOD=$(string_upper "${REQUEST_METHOD%${__http_CR}}")
    HTTP_VERSION=$(string_upper "${HTTP_VERSION%${__http_CR}}")
    PATH_INFO=${PATH_INFO%${__http_CR}}
    QUERY_STRING=${PATH_INFO#*\?}
    PATH_INFO=${PATH_INFO%%\?*}

    [ "$PATH_INFO" = "$QUERY_STRING" ] && QUERY_STRING=""

    declare -x REQUEST_METHOD PATH_INFO HTTP_VERSION QUERY_STRING
    declare -x SERVER_PORT=80

    # Those are provided by UCSPI-compliant TCP socket wrappers,
    # see http://cr.yp.to/ucspi-tcp/environment.html
    #
    if [ -n "$TCPREMOTEIP" ]
    then
        http_debug 'Running under UCSPI-compatible TCP wrapper'
        declare -x REMOTE_ADDR=${TCPREMOTEIP}
        if [ "$TCPREMOTEHOST" != "$TCPREMOTEIP" ] ; then
            declare -x REMOTE_HOST=${TCPREMOTEHOST}
        fi
        [ -n "$TCPREMOTEINFO" ] && declare -x REMOTE_IDENT=${TCPREMOTEINFO}
    elif string_endswith "$BILL_FROM" /faucet && [ -x "${BILL_FROM%faucet}/getpeername" ]
    then
        # It looks like we are being run under control of netpipes
        http_debug 'Running under netpipes/faucet TCP wrapper'
        local -ar info=( $(getpeername) )
        declare -x REMOTE_ADDR=${info[1]}
    else
        http_debug 'TCP wrapper not detected'
    fi
    # TODO Add support for internal sockets


    case $HTTP_VERSION in
        HTTP/1.0 | HTTP/1.1)
            readmore=true
            ;;
        HTTP/0.9 | "")
            readmore=false
            ;;
        *)
            http_error 500 "Protocol version unrecognized"
            return
            ;;
    esac

    local -r handler="${prefix}_${REQUEST_METHOD}"
    if [[ $(type -t "$handler") != 'function' ]]
    then
        http_error 501 "Method $REQUEST_METHOD not implemented"
        return
    fi

    while $readmore
    do
        read line
        if [[ $line = $__http_CR ]] || [[ -z $line ]]
        then
            # We have found the last empty line signaling end of headers.
            readmore=false
            break
        fi

        # TODO: Handle multi-line HTTP headers (check RFC for details)
        line=${line%${__http_CR}}
        key=$(string_lower "${line%%:*}")
        printf -v val %q "$(string_lstrip <<< "${line#*:}")"
        eval "export HTTP_${key//-/_}=${val}"
    done

    $handler ; http_log_clf
}


main http_handle_request

