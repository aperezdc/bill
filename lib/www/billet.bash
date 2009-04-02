#! /usr/bin/env bill
#++
#   =================
#   Billet client API
#   =================
#   :Author: Adrian Perez de Castro <aperez@igalia.com>
#   :Copyright: 2008-2009 Igalia
#   :License: GPL3
#   :Abstract: Provides support functions for implementing Billets.
#
#   .. contents::
#
#   Functions
#   =========
#--

#++ billet_url relative_uri
#--
billet_url ()
{
    if [[ $# -eq 1 ]] ; then
        echo "/${BILLET_CONTEXT}/$1"
    else
        echo "/$1/$2"
    fi
}
