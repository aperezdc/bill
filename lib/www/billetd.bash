#! /usr/bin/env bill
#++
#   =============
#   Billet Engine
#   =============
#   :Author: Adrian Perez <aperez@igalia.com>
#   :Copyright: 2008-2009 Igalia S.L.
#   :License: GPL3
#   :Abstract: Billet container implementation.
#       This module is used by the ``billetd`` daemon included with Bill.
#
#   .. contents::
#--

need stat || "Program 'stat' was not found, install coreutils"


use text/string
use www/http


declare    BILLET_CONTEXT="."
declare -a BILLET_TRAIL=( )
declare    BILLET_PATH=''
declare    BILLET_BASE=''
declare    BILLET_DATA=''
declare    BILLET_TEMP=''
declare    BILLET_RSRC=''
declare    BILLET_LIBS=''


#++ billetd_debug format [ arg1 [ arg2 ... [ argN ] ] ]
#
#   When the ``BILLETD_DEBUG`` variable is set, prints a message to standard
#   error. Otherwise does nothing. The *format* string works the same as for
#   the ``printf`` builtin.
#--
billetd_debug () {
    if [ "$BILLETD_DEBUG" ] ; then
        local -r format="(billetd) $1\n"
        shift
        printf "$format" "$@"
    fi
} 1>&2


#++ billetd_map_context [ path ]
#
#   Maps an URL to an existing Billet context. Contexts are searched in the
#   directory referenced by the ``BILLET_BASE`` variable which, by default,
#   points to the current working directory.
#
#   If a *path* is not supplied, then ``$PATH_INFO`` will be used instead.
#   The function defines the ``$BILLET_CONTEXT`` and ``$BILLET_PATH``
#   variables, with the obvious meaning.
#--
billetd_map_context ()
{
    billetd_debug "PWD=$(pwd)"
    local path=${1:-"$PATH_INFO"}
    while string_startswith "$path" / ; do
        path=${path#/}
    done

    # Use 1st URL component as context name
    BILLET_CONTEXT=${path%%/*}

    # If no context name is given, but a default one exists, use the default
    if ( [ -z "$BILLET_CONTEXT" ] || [ ! -x "${BILLET_CONTEXT}.b" ] ) && \
         [ -r "$BILLET_BASE/default" ]
    then
        BILLET_CONTEXT=$(< "$BILLET_BASE/default" )
        PATH_INFO="/${BILLET_CONTEXT}${PATH_INFO}" # XXX Hackish
        path="$BILLET_CONTEXT/$path"
    fi

    # If the chosen context does *not* have a launcher script, or the
    # launcher script is not executable, just exit with a 404 (Not
    # found) HTTP status.
    if [ ! -x "${BILLET_BASE}/${BILLET_CONTEXT}.b" ] ; then
        http_error 404 'Billet context not found'
        return 1
    fi

    BILLET_TRAIL=( "$BILLET_CONTEXT" )
    BILLET_PATH=${path#*/}

    local npath=${path#*/}
    while [ "$path" != "$npath" ] ; do
        path=${npath}
        BILLET_TRAIL=( "${BILLET_TRAIL[@]}" "${path%%/*}" )
        npath=${path#*/}
    done

    if [ ! -x "${BILLET_BASE}/${BILLET_CONTEXT}.b" ] ; then
        http_error 404 'Billet context not found'
        return 1
    fi

    # XXX This is for PATH_INFO=/ -- and a bit hackish.
    [[ ${#BILLET_TRAIL[1]} = 0 ]] && unset BILLET_TRAIL[1]

    billetd_debug 'Context is "%s"' "$BILLET_CONTEXT"
}


#++ billetd_set_stdvars
#
#   Defines the standard set of variables. Note that ``$BILLET_CONTEXT``
#   **must** be defined in order for this to work. You can map an URI/path
#   to its context name using billetd_map_context_.
#--
billetd_set_stdvars ()
{
    if [ -z "$BILLET_CONTEXT" ] ; then
        http_error 500
        return 1
    fi

    BILLET_BOOT="${BILLET_BASE}/${BILLET_CONTEXT}.b"
    BILLET_DATA="${BILLET_BASE}/${BILLET_CONTEXT}/data"
    BILLET_TEMP="${BILLET_BASE}/${BILLET_CONTEXT}/temp"
    BILLET_RSRC="${BILLET_BASE}/${BILLET_CONTEXT}/rsrc"
    BILLET_LIBS="${BILLET_BASE}/${BILLET_CONTEXT}/libs"
}


#++ billet_send_resource
#--
billetd_send_resource ()
{
    local -r method=${1:-GET}
    local -i response=200

    if [ "$method" != GET ] && [ "$method" != HEAD ] ; then
        http_error 501
        return 3
    fi

    # XXX Using PATH_INFO is a reasonable shortcut.
    local -r path="${BILLET_BASE}/${PATH_INFO}"

    if [ ! -r "$path" ] || [ ! -f "$path" ] ; then
        http_error 404
        return 3
    fi

    mtime=$(date --reference="$path" --utc '+%a, %d %b %Y %T GMT')

    # File attributes array contents:
    #
    #  Index  What
    #  ----- -------------------
    #     0   file size (bytes)
    #     1   etag
    #     2   mtime (seconds from the Epoch)
    #
    finfo=( $(stat --dereference --format='%s %Z:%Y:%X:%d:%i %Y' "$path") )

    if [ "$HTTP_if_modified_since" ] ; then
        local -i refdate
        # This can fail
        refdate=$(date --date="$HTTP_if_modified_since" '+%s' 2> /dev/null)
        if [[ $? = 0 ]] && [[ ${finfo[2]} -le $refdate ]] ; then
            # Set HTTP response to "Not Modified" :-)
            response=304
        fi
    fi

    http_response $response
    http_header Content-Type   "$(http_mimetype_guess "$path")"
    http_header Content-Length "${finfo[0]}"
    http_header ETag           "${finfo[1]}"
    http_header Last-Modified  "$mtime"
    http_body

    # Send contest only if we have a GET and content is modified
    if [[ $method = GET ]] && [[ $response != 304 ]] ; then
        cat "$path"
    fi
}


billetd_handle_http_HEAD ()
{
    billetd_map_context || return 1
    billetd_set_stdvars || return 2

    # Handle static content, trail have "rsrc" as second component:
    #
    #    BILLET_TRAIL=( context rsrc foo bar... )
    #                           ^^^^
    if [[ ${#BILLET_TRAIL[@]} -gt 2 ]] && [[ ${BILLET_TRAIL[1]} = rsrc ]]
    then
        billetd_send_resource HEAD
    else
        ( billetd_dispatch HEAD "$(string_join . "${BILLET_TRAIL[@]}")" )
    fi
}


#++ billetd_handle_http_GET
#--
billetd_handle_http_GET ()
{
    billetd_map_context || return
    billetd_set_stdvars || return

    # Handle static content, trail have "rsrc" as second component:
    #
    #    BILLET_TRAIL=( context rsrc foo bar... )
    #                           ^^^^
    # All other cases are passed down to the billet.
    #
    if [[ ${#BILLET_TRAIL[@]} -gt 2 ]] && [[ ${BILLET_TRAIL[1]} = rsrc ]]
    then
        billetd_send_resource GET
    else
        ( billetd_dispatch GET "$(string_join . "${BILLET_TRAIL[@]}")" )
    fi
}


#++ billetd_handle_http_POST
#--
billetd_handle_http_POST ()
{
    billetd_map_context || return
    billetd_set_stdvars || return

    if [[ ${#BILLET_TRAIL[@]} -gt 2 ]] && [[ ${BILLET_TRAIL[1]} = rsrc ]]
    then
        # It is not allowed to POST to static resources
        http_error 405
    else
        ( billetd_dispatch POST "$(string_join . "${BILLET_TRAIL[@]}")" )
    fi
}


#++ billetd_run_hook name [ condition-file ]
#--
billetd_run_hook ()
{
    local -i rc=${__BILLETD_HOOK_DEFAULT:-0}

    if [ "$2" ] ; then
        if [[ $(type -t "billet.$1") = function ]] && [ ! -e "$2" ] ; then
            "billet.$1" ; rc=$?
            touch "$2"
        fi
    else
        if [[ $(type -t "billet.$1") = function ]] ; then
            "billet.$1" ; rc=$?
        fi
    fi
    return $rc
}


billetd_dispatch ()
{
    local handler="billet:${2#*.}"
    local newhandler=${handler%.*}
    local -i rc=0

    BILLPATH="$BILLPATH:$BILLET_LIBS"
    source "$BILLET_BOOT"

    billetd_run_hook setup "$BILLET_BASE/$BILLET_CONTEXT/.setup" || return
    billetd_run_hook before_request || return

    billetd_debug 'Looking up dispatcher...'
    while [[ $handler != $newhandler ]] ; do
        billetd_debug '  Trying dispatch to "%s"' "$handler"
        if [[ $(type -t "$handler") = function ]] ; then
            billetd_debug '  Dispatching to "%s"' "$handler"
            "$handler" ; rc=$?
            billetd_run_hook after_request || true
            return $rc
        fi
        handler=$newhandler
        newhandler=${handler%.*}
    done

    billetd_debug '  Trying dispatch to "%s"' "$handler"
    if [[ $(type -t "$handler") = function ]] ; then
        billetd_debug '  Dispatching to "%s"' "$handler"
        "$handler" ; rc=$?
        billetd_run_hook after_request || true
        return $rc
    fi

    if [[ $handler != billet: ]] ; then
        billetd_debug '  Trying dispatch to "billet:"'
        if [[ $(type -t "billet:") = function ]] ; then
            billetd_debug '  Dispatching to "billet:"'
            "billet:" ; rc=$?
            billetd_run_hook after_request || true
            return $rc
        fi
    fi

    billetd_debug 'Could not dispatch'
    __BILLETD_HOOK_DEFAULT=1 billetd_run_hook not_found \
        || http_error 404 "No handler found for $PATH_INFO"
}


#++ billet_server_run handlers
#--
billetd_handle_request ()
{
    declare -x BILLET_BASE=$(pwd)
    billetd_debug "BASE=%s" "$BILLET_BASE"
    http_handle_request billetd_handle_http
}

