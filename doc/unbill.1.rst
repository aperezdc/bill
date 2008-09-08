========
 unbill
========
--------------------------------
Decaffeinates Bill shell scripts
--------------------------------

:Author: Adrian Perez <aperez@igalia.com>
:Manual section: 1
:Manual group: User commands

SYNOPSIS
========

unbill script-file [ > output ]


DESCRIPTION
===========

``unbill`` takes a Bill shell script as input and produces a version of it
capable of working standalone, i.e. without needing an installed copy of
the Bill interpreter and standard library. Output of processing will be
dumped to standard output.

Preparing scripts for deployment using this tool has advantages and
drawbacks:

* Scripts can be run standalone, they do not need extra
* Scripts will take more disk space.
* If you have a set of scripts which share a module, you will have duplicate
  code.


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

