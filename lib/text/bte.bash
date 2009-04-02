#! /usr/bin/env bill
#++
#   ==============================
#   BTE - The Bash Template Engine
#   ==============================
#   :Author: Adrian Perez <aperez@igalia.com>
#   :License: GPL3
#   :Abstract: Inert template engine for use in shell code.
#       Provides text templating facilities, in such a way that it is not
#       possible to run arbitrary code from a template: templates are
#       *parsed* instead of passed along to the shell as code, or being
#       expanded by means of the ``eval`` builtin.
#
#   .. contents::
#--

#++
#   Introduction
#   ============
#   .. warning:: Documentation not yet available.
#--

use data/hash


#++
#   Functions
#   =========
#--

#++ bte_format_xmlescape state < input > output
#
#   Formatter which escapes characters into X(HT)ML entities.
#--
bte_format_xmlescape ()
{
    local line
    while read -r line ; do
        line=${line//&/&amp;}
        line=${line//</&lt;}
        line=${line//>/&gt;}
        line=${line//\'/&apos;}
        line=${line//\"/&quot;}
        echo "${line}"
    done
}


# __bte_var_is_from_env varname
#
__bte_var_is_from_env ()
{
    local decl attr name
    while read -r decl attr name ; do
        if [[ ${name} = $1=* ]] ; then
            return 0
        fi
    done < <(declare -x)
    return 1
}


#++ bte_dotted_var state var
#--
bte_dotted_var ()
{
    local -a trail=( ${2//\./ } )
    local item value

    if [[ ${#trail[@]} -gt 1 && ${trail[0]} = ENV ]] ; then
        if __bte_var_is_from_env ${trail[1]} ; then
            value=${trail[1]}
            value=${!value}
        else
            value=$2
        fi
    else
        if hash_has $1 ${trail[0]} ; then
            value=$(hash_get $1 ${trail[0]})
            unset trail[0]
            for item in "${trail[@]}" ; do
                if hash_has ${value} ${item} ; then
                    value=$(hash_get ${value} ${item})
                else
                    value=$2
                    break
                fi
            done
        else
            value=$2
        fi
    fi
    echo "${value}"
}


#++ bte_template state < input > output
#--
bte_template ()
{
    local line xpn item val

    while read -r line ; do
        # Expand variables and stuff... one at a time
        while [[ ${line} =~ (.*)(\$\{[a-zA-Z0-9\.:_-]+\})(.*) ]] ; do
            xpn=${BASH_REMATCH[2]}
            xpn=${xpn:2:$(( ${#xpn} - 3 ))}
            xpn=( ${xpn//:/ } )

            # Get initial value
            if [[ ${#xpn[0]} -gt 0 ]] ; then
                val=$(bte_dotted_var $1 ${xpn[0]})
            else
                val=''
            fi
            unset xpn[0]

            # Run filter pipeline
            for item in "${xpn[@]}" ; do
                [[ $(type -t bte_format_${item}) = function ]] || return 1
                val=$(bte_format_${item} $1 <<< "${val}")
            done

            # Save line with item expanded, and reprocess
            line="${BASH_REMATCH[1]}${val}${BASH_REMATCH[3]}"
        done
        echo "${line}"
    done
}


bte_template_main ()
{
    bte_template $(hash_new)
}


main bte_template_main

