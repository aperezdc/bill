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
#   Formatter which escapes characters into X(HT)ML entities. Currently the
#   following characters are escaped:
#
#   .. class:: modules
#
#   ========= ==========
#   Character Entity
#   ========= ==========
#   <         &lt;
#   >         &gt;
#   &         &amp;
#   '         &apos;
#   "         &quot;
#   ========= ==========
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


#++ bte_format_calc state < input > output
#
#   Performs simple arithmetic evaluations using a Bash built-in ``$((...))``
#   expression. This allows for some degree of simple calculations. The
#   usual ``+``, ``-``, ``*`` and ``/`` operands are allowed. Referring to
#   Bash special variables like ``$RANDOM`` must be done without the dollar
#   sign, and variables from the current state must be enclosed into square
#   brackets. Spaces in the expression are not allowed, but grouping
#   parentheses are. Example::
#
#       ${(RANDOM+$[x])/3:calc}
#
#--
bte_format_calc ()
{
    local line
    while read -r line ; do
        line=${line//\[/\{}
        line=${line//\]/\}}
        line=$(bte_template $1 <<< "${line}")
        echo "$(( ${line} ))"
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
            if [[ ${#trail[@]} -gt 1 ]] ; then
                unset trail[0]
                for item in "${trail[@]}" ; do
                    if hash_has ${value} ${item} ; then
                        value=$(hash_get ${value} ${item})
                    else
                        value=$2
                        break
                    fi
                done
            fi
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
    local xpn_re='(.*)(\$\{[]\[()a-zA-Z0-9\.+/*:_\ \$-]+\})(.*)'

    local line xpn item val
    local old_ifs=${IFS}

    if [[ ${BASH_VERSINFO[0]} -le 3 && ${BASH_VERSINFO[1]} -le 1 ]] ; then
        # Change regex syntax for bash older than 3.2
        xpn_re="'${xpn_re}'"
    fi

    IFS=''
    while read -r line ; do
        IFS=${old_ifs}
        # Expand variables and stuff... one at a time
        while eval "[[ \${line} =~ ${xpn_re} ]]" ; do
            xpn=${BASH_REMATCH[2]}
            xpn=${xpn:2:$(( ${#xpn} - 3 ))}
            xpn=( ${xpn//:/ } )

            # Get initial value
            if [[ ${#xpn[0]} -gt 0 ]] ; then
                val=$(bte_dotted_var $1 ${xpn[0]})
            else
                val=''
            fi

            if [[ ${#xpn[@]} -gt 1 ]] ; then
                # Run filter pipeline
                unset xpn[0]
                for item in "${xpn[@]}" ; do
                    if [[ $(type -t bte_format_${item}) = function ]] ; then
                        val=$(bte_format_${item} $1 <<< "${val}")
                    fi
                done
            fi

            # Save line with item expanded, and reprocess
            line="${BASH_REMATCH[1]}${val}${BASH_REMATCH[3]}"
        done
        echo "${line}"
        IFS=''
    done
    IFS=${old_ifs}
}


bte_template_main ()
{
    bte_template $(hash_new)
}


main bte_template_main

