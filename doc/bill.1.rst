======
 bill
======
-----------------------------
Bill shell script interpreter
-----------------------------

:Author: Adrian Perez <aperez@igalia.com>
:Manual section: 1
:Manual group: User commands

SYNOPSIS
========

bill [ script-file ]


DESCRIPTION
===========

Bill runs shell scripts which use Bill extensions, or can be used as
interactive interpreter as well. You can run it without arguments to
get into interactive mode, or pass the name of a script to be executed.
The second form of invocation allows for launching the interpreter from
a she-bang, writing something like this in the first line of the script:

::

  #! /usr/bin/env bill



OPTIONS
=======

None yet.


ENVIRONMENT VARIABLES
=====================

BILLPATH
  Augments the default search path for modules. By default modules are
  loaded from ``/usr/lib/bill`` and the directory where the launched
  script resides. This variable can be manipulated from scripts, and
  contains a colon-separated list of paths.

