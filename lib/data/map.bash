#! /usr/bin/env bill
#++
#   ====
#   Maps
#   ====
#
#   :Author: Adrián Pérez <aperez@igalia.com>
#   :Copyright: 2008-2009 Igalia S.L.
#   :License: GPL3
#   :Abstract: Provides a dictionary-like data structure for use in shell code.
#
#   .. contents::
#
#   Introduction
#   ============
#   This module adds functions to manage pseudo hash tables using arrays. It
#   it not as efficient as a proper hash table implementation, but that
#   would be difficult to do in shell code and this suffices for a vast
#   amount of cases where performance is not critical. In fact, when maps
#   are used to store a small amount of items, they may even be faster.
#
#   An array containing paired items is considered to be a map, like the
#   following example:
#
#   .. sourcecode:: bash
#
#       mymap=(
#           "key1"    "value1"
#           "key2"    "value2"
#           # ...
#       )
#
#
#   Obviously enough, a map must contain an even number of elements.
#
#   .. warning:: This map implementation is neither CPU and memory
#      efficient. Each algorithm has *O(n)* complexity. This is *not*
#      considered to be an error.
#
#
#   Functions
#   =========
#--


#++ map_get map key
#
#   Obtains the value associated with a particular key. The exit status is
#   non-zero if the specified key does not exist.
#--
map_get ()
{
    # Calculate the lenght of the map
    local -r map_len=$(map_size "$1")
    local -r map_key=$2
    local i

    # Loop over map keys.
    for (( i = 0; i < $map_len ; i += 2 ))
    do
        # Check if we founded specified key. In this case print value into
        # stdout and return true.
        if [[ $(map_item "$1" "$i") = $map_key ]]
        then
            echo "$(map_item "$1" "$((i+1))")"
            return 0
        fi
    done

    # If loop ends, then no key is found.
    return 1
}


#++ map_key map value
#
#   Finds the first key which has the given value associated. Exits status
#   is non-zero if the item is not found.
#--
map_key ()
{
    local -r map_len=$(map_size "$1")
    local -r map_val=$2
    local i

    # Loop over map keys.
    for (( i = 1; i < $map_len; i += 2 ))
    do
        if [[ $(map_item "$1" "$i") = $map_val ]]
        then
            echo "$(map_item "$1" "$((i-1))")"
            return 0
        fi
    done
    return 1
}


#++ map_keys map
#
#   Gets a list of all the keys in a map. Exit status is non-zero if
#   the map is empty.
#--
map_keys ()
{
    local -r map_len=$(map_size "$1")
    local list_out i

    for (( i = 0; i < $map_len; i += 2 ))
    do
        list_out="${list_out:+${list_out}${IFS:0}}$(map_item "$1" "$i")"
    done

    # Finally print result in stdout if list_out contains something.
    # If no result, then condition fails, and return value is automatically
    # set to *false*.
    [ "$list_out" ] && echo "$list_out"
}


#++ map_size map
#
#   Calculates the number of elements present in a map.
#--
map_size ()
{
    eval "echo \${#${1}[@]}"
}


#++ map_item map index
#
#   Returns item at the given position of the map. Usually you do not need
#   to use this function, as it will be used internally by the rest of the
#   functions of the module. It could be useful to build additional features
#   in other modules.
#--
map_item ()
{
    eval "echo \${$1[$2]}"
}


#++ map_values map
#
#   Obtains a list of all the values in a map. Exit status is non-zero
#   if the map is empty.
#--
map_values ()
{
    local -r map_len=$(map_size "$1")
    local list_out i

    for (( i = 1; i < $map_len; i += 2 ))
    do
        # Concatenate current value into ``list_out`` variable.
        list_out="${list_out:+${list_out}${IFS:0}}$(map_item "$1" "$i")"
    done

    # Finally print result in ``stdout`` if ``list_out`` contains something.
    # If no result, then condition fails, and return value is automatically
    # setted to *false*.
    [ "$list_out" ] && echo "$list_out"
}


