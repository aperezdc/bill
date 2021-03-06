#! /usr/bin/env bill
#++
#   ==============
#   Text templates
#   ==============
#   :Author: Adrian Perez <aperez@igalia.com>, initial concept and
#       implementation by Andrés J. Díaz <ajdiaz@mundo-r.com>. This
#       implementation shares no code with the original one.
#   :Copyright: 2008-2009 Igalia S.L.
#   :License: GPL3
#   :Abstract: Miminalistic template engine to be used from shell scripts.
#       Can be used to dynamically generate any kind of text-based content,
#       including (but not limited to) HTML.
#
#   .. contents::
#
#   Template language
#   =================
#   Templates reuse the Bash parser, so the followgin constructs can be used
#   inside the template text:
#
#   Literal shell code execution
#       Lines prefixed with ``#!`` will be passed unmodified to the shell.
#       This can be used e.g. when one want to define new variables or
#       functions.
#
#   Variable expansion
#       Using ``${var}``. All modifiers which can be used in shell variable
#       expansion can be used in BSP templates as well. If you want to
#       output a literal dollar sign, use ``\$``.
#
#   Command expansion
#       Using ``$(command)``. Commands can be arbitrarily complex, including
#       ``for``-loops and the like.
#
#   Variables are expanded from the ones defined in the environment, but
#   only variables starting with a given prefix (``var_`` by default) will
#   be seen by the templates. For example the following template:
#
#   .. sourcecode:: bash
#
#       Hello ${name}!
#
#   would use a variable named ``var_name`` when expanding it, for example
#   using the following command:
#
#   .. sourcecode:: bash
#
#       var_name='Peter' template_expand < input.txt > output.txt
#
#   The final rendered result would be (as expected)::
#
#       Hello, Peter!
#
#
#   Functions
#   =========
#--


template_IFS='
'


#++ template_expand [ prefix ]
#
#   Expands shell variables in lines given as input. Optionally a prefix can
#   be specified (default is ``var_``) so a reference to ``${xyz}`` in the
#   input will be expanded with the contents of ``${var_xyz}``. The template
#   is read from the standard input and the expanded result dumped as
#   standard output. Typical usage would be:
#
#   .. sourcecode:: bash
#
#       var_foo='This is foo' var_bar='This is bar' \
#           template_expand < input_template > expanded_output
#--
template_expand () {

    local -r saved_IFS=${IFS}
    local -r prefix=${1:-'var_'}
    local line
    IFS=${template_IFS}
    while read line ; do
        if [[ "${line}" = \#!* ]] ; then
            eval "${line/\#\!/}"
            continue
        fi
        line=${line//\${/\${${prefix}}
        line=${line//\`/\\\`}
        eval echo "\"${line}\""
    done
    IFS=${saved_IFS}
}



declare -ra template_expand_cgi_vars=(
    CONTENT_LENGTH
    CONTENT_TYPE
    DOCUMENT_ROOT
    GATEWAY_INTERFACE
    HTTP_ACCEPT
    HTTP_ACCEPT_CHARSET
    HTTP_ACCEPT_ENCODING
    HTTP_ACCEPT_LANGUAGE
    HTTP_CACHE_CONTROL
    HTTP_CONNECTION
    HTTP_COOKIE
    HTTP_HOST
    HTTP_KEEP_ALIVE
    HTTP_REFERER
    HTTP_USER_AGENT
    QUERY_STRING
    REMOTE_ADDR
    REMOTE_PORT
    REQUEST_METHOD
    REQUEST_URI
    SCRIPT_FILENAME
    SCRIPT_NAME
    SERVER_ADDR
    SERVER_ADMIN
    SERVER_NAME
    SERVER_PORT
    SERVER_PROTOCOL
    SERVER_SOFTWARE
)


#++ template_expand_cgi [ prefix ]
#
#   Works exactly like template_expand_, but adds automatically the
#   variables specified by the `CGI <http://www.w3.org/CGI/>`__ standard.
#--
template_expand_cgi ()
{
    local -r prefix=${1:-'var_'}
    local varname

    # Export CGI vars (in no particular order)
    if [ "$prefix" ]
    then
        for varname in "${template_expand_cgi_vars[@]}"
        do
            eval "declare -xr ${prefix}${varname}='$varname'"
        done
    else
        for varname in "${template_expand_cgi_vars[@]}"
        do
            eval "declare -xr $varname"
        done
    fi

    template_expand "$@"
}


template_main ()
{
    local item

    for item in "$@"
    do
        case ${item} in
            *=*) eval "${item}" ;;
        esac
    done

    if [ "$1" ] ; then
        template_expand '' < "$1"
    else
        template_expand ''
    fi
}


main template_main "$@"

