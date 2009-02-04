#! /usr/bin/env bill
#++
#   ===========
#   Hash tables
#   ===========
#   :Author: Adrian Perez <aperez@igalia.com>
#   :Copyright: 2008 Igalia S.L.
#   :License: GPL v2
#   :Abstract: Efficient dictionary-like structures i.e. a hash table.
#
#   .. contents::
#--

#++
#   Discussion
#   ==========
#   A hash table is a data structure which stores a set of *(key, value)*
#   pairs in a way that enables for fast lookup of values when the keys are
#   known. Those hash tables are used mainly with string keys and values, so
#   they are sometimes called *dictionaries* as well.
#
#   Usage
#   -----
#   A hash table can be accessed by using its unique identifier. New
#   identifiers can be obtained using hash_new_, and albeit they are regular
#   strings and can be printed usually you do not need to know about them:
#
#   .. sourcecode:: bash
#
#       (bill) use data/hash
#       (bill) h=$(hash_new)
#       (bill) echo $h
#       :bill:0709bd8abbe7139f40dd48004e85a5ea00dd4bd3:
#
#   Now you can use the hash table, the basic functions for this are
#   hash_set_ and hash_get_:
#
#   .. sourcecode:: bash
#
#       (bill) hash_set $h firstname 'John'
#       (bill) hash_set $h lastname  'Doe'
#       (bill) hash_set $h email     'john@doe.org'
#       (bill) printf '%s %s <%s>\n' \
#         ...)   "$(hash_get $h firstname)" \
#         ...)   "$(hash_get $h lastname)" \
#         ...)   "$(hash_get $h email)"
#       John Doe <john@doe.org>
#
#   We can check whether a key is present in a hash table using hash_has_,
#   which is nice to do checking. Note that hash_get_ will return an empty
#   string and have a non-zero exit status:
#
#   .. sourcecode:: bash
#
#       (bill) hash_has $h email && echo Yes || echo No
#       Yes
#       (bill) hash_has $h age && echo Yes || echo No
#       No
#       (bill) v=$(hash_get $h age)
#       (bill) echo "code $?, value '$v'"
#       code 1, value ''
#
#   Finally, you can obtain a array of keys present in the hash table using
#   hash_keys_escaped_. Once you are done using a table, do not forget to
#   use hash_clear_ on it:
#
#   .. sourcecode:: bash
#
#       (bill) keys=( $(hash_keys_escaped $h) )
#       (bill) echo "Keys: ${keys[*]}"
#       Keys: lastname firstname email
#       (bill) hash_clear $h
#       (bill) echo "Keys: ${keys[*]}"
#       Keys:
#
#
#   Acceptable values
#   -----------------
#   Keys can be any string which can be represented in bash source code. You
#   can even use “funny” keys containing escape and control characters as
#   long as you do not try to iterate over keys containing them.
#
#   .. warning:: Use only printable characters for hash table keys when it
#      is needed to iterate over the keys of a hash table using
#      hash_keys_iter_, hash_keys_ or hash_keys_escaped_.
#
#   Nesting
#   -------
#   As hash table identifiers are strings, you can use them as values of
#   another hash table, thus creating nested tables:
#
#   .. sourcecode:: bash
#
#       (bill) outer=$(hash_new)
#       (bill) inner=$(hash_new)
#       (bill) hash_set $outer subtable $inner
#       (bill) hash_set $inner value 'I am inside inner'
#       (bill) hash_get $(hash_get $outer subtable) value
#       I am inside inner
#
#   This way complex data structures can be created. The syntax used to
#   create them is not very pretty, but at least it is possible.
#--

#++
#   Functions
#   =========
#--


use data/random
use text/string


#++ hash_new
#
#   Creates a new hash table. Returns a has table identifier which is needed
#   as first argument to all the other functions of the module.
#--
hash_new () {
    echo ":bill:$(random_pseudo_hex 20):"
}


#++ hash_set hash_id key value
#
#   Associates a ``key`` with a ``value``. The ``hash_id`` parameter must be
#   an identifier obtained with hash_new_.
#
#   *See also:* hash_get_, hash_has_.
#--
hash_set () {
    builtin hash -d "$1$2" 2> /dev/null || true
    builtin hash -p ":$3" "$1$2"
}


#++ hash_get hash_id key
#
#   Gets the value associated with a ``key``. The ``hash_id`` parameter must
#   be an identifier obtained with hash_new_. The exit status is non-zero
#   when an element is not found.
#
#   *See also:* hash_get_, hash_has_.
#--
hash_get () {
    builtin hash -t "$1$2" &> /dev/null || return 1
    local -r value=$(builtin hash -t "$1$2" 2> /dev/null)
    echo -n "${value:1}"
}


#++ hash_del hash_id key
#
#   Deletes a *(key, value)* pair from a hash table. The ``hash_id``
#   parameter must be an identifier obtained with hash_new_.
#
#   *See also:* hash_set_, hash_has_, hash_clear_.
#--
hash_del () {
    builtin hash -d "$1$2" 2> /dev/null || true
}


#++ hash_has hash_id key
#
#   Checks whether a given key is set in a hash table. The ``hash_id``
#   parameter must be an identifier obtained with hash_new_. The exit status
#   is zero when the keys exists, and non-zero otherwise.
#
#   *See also:* hash_set_.
#--
hash_has () {
    builtin hash -t "$1$2" &> /dev/null
}


#++ hash_keys_iter hash_id callback
#
#   Iterates over all keys of the given hash table ``hash_id``. The
#   ``callback`` will be called with the ``hash_id`` as first argument
#
#   .. warning:: Do not add or remove keys while iterating over the
#       elements, behaviour is undefined.
#
#   *See also:* hash_keys_escaped_, hash_keys_.
#--
hash_keys_iter () {
    local _a _b _c _d key hl=${#1}
    while read -r _a _b _c _d key ; do
        if [[ -z $key ]] && [[ -n $_d ]] ; then
            key=$_d
        fi
        [[ ${key::$hl} = $1 ]] && "$2" "$1" "${key:$hl}"
    done < <(builtin hash -l)
}


#++ hash_keys hash_id
#
#   Gathers all keys of a given hash table and print one key per line. It
#   may be better to use hash_keys_escaped_ if you want to save the key list
#   into an array.
#
#   *See also:* hash_keys_escaped_, hash_keys_iter_.
#--
hash_keys ()
{
    local _a _b _c _d key hl=${#1}
    while read -r _a _b _c _d key ; do
        if [[ -z $key ]] && [[ -n $_d ]] ; then
            key=$_d
        fi
        [[ ${key::$hl} = $1 ]] && echo "${key:$hl}"
    done < <(builtin hash -l)
}



#++ hash_keys_escaped hash_id
#
#   Gathers all keys of a given hash table and print one key per line.
#   Unlike hash_keys_, elements are escaped so you can reuse the output
#   for gathering the key names into an array:
#
#   .. sourcecode:: bash
#
#       h=$(hash_new)
#       for i in $(seq 10) ; do
#           hash_set $h "key $i" "value $i"
#       done
#       h_heys=( $(hash_keys_escaped $h) )
#
#   *See also:* hash_keys_, hash_keys_iter_.
#--
hash_keys_escaped ()
{
    local _a _b _c _d key hl=${#1}
    while read -r _a _b _c _d key ; do
        if [[ -z $key ]] && [[ -n $_d ]] ; then
            key=$_d
        fi
        [[ ${key::$hl} = $1 ]] && printf "%q\n" "${key:$hl}"
    done < <(builtin hash -l)
}



#++ hash_clear hash_id
#
#   Empties a hash table. The ``hash_id`` parameter must be a valid
#   identifier obtained with hash_new_.
#
#   *See also:* hash_new_, hash_set_, hash_del_.
#--
hash_clear ()
{
    local item
    while read -r item ; do
        hash_del "$1" "$item"
    done < <(hash_keys "$1")
}

