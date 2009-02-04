#! /usr/bin/env bill
#++
#   ==============
#   Example module
#   ==============
#   :Author: Adrián Pérez <aperez@igalia.com>
#   :Copyright: Igalia S.L, 2008
#   :Abstract: Provides an example ``hello`` function.
#       This module is used by the ``hello`` test script.
#--

#++ hello [ name ]
#
#   The (in)famous “Hello, world!” example, as a Bill module.
#   Pass ``name`` to greet someone, otherwise the full world will be greeted
#   instead.
#
#--
hello () {
    echo "Hello ${1:-world}!"
}
