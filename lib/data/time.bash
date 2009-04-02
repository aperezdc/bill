#! /usr/bin/env bill
#++
#   ===========
#   Time module
#   ===========
#   :Author: Adrián Pérez de Castro <aperez@igalia.com>
#   :Copyright: 2008-2009 Igalia S.L.
#   :License: GPL3
#   :Abstract: Provides functions for dealing with date and time values.
#
#   .. contents::
#--

#++
#   Discussion
#   ==========
#
#   Time specifications
#   -------------------
#   Format of time specification arguments is nearly any English unambiguous
#   text describing a time and/or date.
#--

#++
#   Functions
#   =========
#--

#++ time_format [format [time]]
#
#   Formats a given *time* with the specified *format*.
#
#   format
#       Format string with ``%``-escaped sequences. Recognized sequences
#       are those of the ``strftime(3)`` function of the C library.
#   time
#       Time specification. If not given, the system's current time will
#       be used instead.
#
#--
time_format ()
{
    [[ $# -eq 2 ]] && date --date="$2" "+$1" || date "+$1"
}


#++ time_rfc2822 [time]
#
#   Formats a given *time* in the format specified by
#   `RFC 822 <http://www.ietf.org/rfcs/rfc822>`__ (or
#   `RFC 2822 <http://www.ietf.org/rfcs/rfc2822>`__). This is typically used
#   in Internet protocols and formats.
#
#   time
#       Time specification. If not given, the system's current time will
#       be used instead.
#--
time_rfc2822 ()
{
    [[ $# -eq 0 ]] && date --rfc-2822 || date --date="$1" --rfc-2822
}



__time_stamp_format='+%Y-%m-%dT%T.%N'
declare -r __time_stamp_format

#++ time_stamp [time]
#
#   Formats a give *time* as a timestamp. The output looks like::
#
#      YYYY-mm-ddTHH:MM:SS.NNNNNNNN
#
#   Timestamps generated this way can be sorted lexicographically, e.g.
#   using the ``sort(1)`` command, it looks like.
#
#   time
#       Time specification. If not given, the system's current time will
#       be used instead.
#--
time_sortable ()
{
    if [ "$1" ] ; then
        date --date="$1" "$__time_sortable_format"
    else
        date "$__time_sortable_format"
    fi
}


#++ time_parse string
#
#   Parses a string containing a time specification and returns the number
#   of seconds from the Epoch.
#
#   string
#       Time specification string. Can contain almost any english free-form
#       text which can be parsed as a date. If the input value cannot be
#       parsed in an unambiguous manner, exit status of the function is
#       non-zero.
#--
time_parse ()
{
    date --date="$1" '+%s'
}


