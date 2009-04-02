#! /usr/bin/env bill
#++
#   ==============
#   BILL built-ins
#   ==============
#   :Author: Adrián Pérez <aperez@igalia.com>
#   :Copyright: 2008-2009 Igalia S.L.
#   :License: GPL3
#   :Abstract: Provides functions of common usage in shell code.
#       This module is always imported by the Bill interpreter at startup.
#
#   .. contents::
#--

export BILL_VERSION='0.1'

#++ warn message
#
#   Prints a message to the standard error stream.
#--
warn ()
{
    echo "$@" 1>&2
}


#++ die [ message ]
#
#   Exits running process with a non-zero status, optionally printing an
#   error message before exiting.
#--
die ()
{
    [ "$1" ] && warn "$@"
    exit 1
}


#++ need tool1 [ tool2 [ ... [ toolN ] ] ]
#
#   Checks whether a list of commands are available on the system and can be
#   accessed by means of the current ``$PATH`` setting. If one of the
#   dependencies is not met, return status will be non-zero. If you want to
#   know exactly which tool was not found then check the tools one at
#   a time:
#
#   .. sourcecode:: bash
#
#       need openssl || die "openssl not found"
#       need convert || die "ImageMagick is not installed"
#--
need ()
{
    local tool

    for tool in "$@"
    do
        type -P "$tool" &> /dev/null || return 1
    done
}



declare -ax bill_loaded_modules=( bill/builtins )

#++ use module
#
#   Loads one module from the library search path, which is itself
#   taken from the ``$BILLPATH`` environment variable. If a module is not
#   found, execution will be aborted and an informative message will be
#   printed to standard error.
#
#   The function will search for a function named the same as the module
#   name with slashes changed to underscores, prefixed with
#   ``__bill_module__``. If the function is found, it will be executed
#   instead of sourcing the module from disk.
#
#   On successful module load the module name will be appended to the
#   ``bill_loaded_modules`` array, and when trying to load the module
#   afterwards will do nothing.
#--
use ()
{
    local modname path

    # Check whether the module is already loaded.
    for modname in "${bill_loaded_modules[@]}"
    do
        # Skip it if already loaded.
        [[ $modname = $1 ]] && return
    done

    local funcname="__bill_module__${1//\//__}"
    if [[ $(type -t "$funcname") = function ]]
    then
        # The module is an inline piece of preloaded code. All defs are
        # inside the function, so we just execute the function.
        __bill_use__=true $funcname
    else
        local old_IFS=$IFS
        local found=false

        IFS=':'
        for path in $BILLPATH
        do
            if [ -r "$path/$1.bash" ]
            then
                __bill_use__=true source "$path/$1.bash"
                found=true
                break
            fi
        done

        # Sanity check :)
        if ! $found
        then
            echo "Could not find module '$1', the module search path is:"
            for path in $BILLPATH
            do
                echo "  $path"
            done
            exit 1
        fi 1>&2

        IFS=$old_IFS
    fi

    # Append module name to list of already loaded modules.
    bill_loaded_modules=( "${bill_loaded_modules[@]}" "$1" )
}


#++ main
#
#   Checks whether a module is running as a standalone script and runs the
#   supplied function with a set of arguments. This allows modules both being
#   imported and for acting as a script. For example.
#
#   .. sourcecode:: bash
#
#       foo () {
#           echo "I am foo"
#       }
#
#       main foo
#--
main ()
{
    [ "$__bill_use__" ] || "$@"
}


declare -xf use die warn need main

