======
 butt
======
----------------------
Bill Unit Test Tester
----------------------

:Author: Adrian Perez <aperez@igalia.com>
:Manual section: 1
:Manual group: User commands

SYNOPSIS
========

butt script-test-file


DESCRIPTION
===========

Butt runs shell scripts which contain test suites. It is a convenient
wrapper around *shunit2*.

It can be invoked directly by test scripts using a she-bang, writing
something like this in the first line of the script:

::

  #! /usr/bin/env butt



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


SEE ALSO
========
* ShUnit2 home page: http://code.google.com/p/shunit2/

