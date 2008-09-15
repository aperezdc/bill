#! /usr/bin/env bill
#++
#   ======================
#   Random data generation
#   ======================
#   :License: GPL v2
#   :Author: Adrian Perez <aperez@igalia.com>
#   :Copyright: 2008 Igalia S.L.
#   :Abstract: Helpful functions for random data generation.
#       Functions whose name starts with ``random_pseudo_`` generate
#       pseudo-random data, and those starting with ``random_`` do
#       generate true random data (in the worst case as random as
#       ``/dev/urandom`` can provide).
#
#   .. contents::
#--


#++ random_pseudo_hex [ count ]
#
#   Generates a random string of length ``count`` hexadecimal octets.
#   If not specified ``count`` is 20 by default.
#--
random_pseudo_hex ()
{
    local i=${1:-20}
    while [ $(( i-- )) != 0 ] ; do
        printf "%02x" $(( RANDOM % 256 ))
    done
}
