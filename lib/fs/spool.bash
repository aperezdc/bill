#! /usr/bin/env bill
#++
#   ==================================
#   Module for filesystem-based spools
#   ==================================
#   :Author: Adrián Pérez <aperez@igalia.com>
#   :Copyright: 2008-2009 Igalia S.L.
#   :License: GPL3
#   :Abstract: Provides mechanism for having a directory with spooled items.
#       Items may be files or subdirectories which can be created, listed and
#       removed. All the operations are done at the filesystem level and
#       atomicity is guaranteed by using renames.
#
#   .. contents::
#
#   Usage
#   =====
#
#   Common arguments
#   ----------------
#   Most of the functions accept either a ``spooldir`` (a spool directory)
#   or a ``spoolitem`` (an item inside the spool directory) argument.
#   A spool directory is a user-created directory, initially empty, which
#   will be accessed by means of the functions defined in this module;
#   otherwise behaviour is undefined. A spool item is the path to an item
#   inside the spool file (including the name of the spool directory itself
#   as prefix).
#
#   Workflow
#   --------
#   There are three states in which a item inside a spool directory can be:
#
#   Temporary
#       Item file names start with ``t:``. In this state the items are
#       being created.
#   Zapping
#       Item file names start with ``z:``. In this state the items are
#       being deleted. There is no way of accessing an item once it was
#       marked for deletion.
#   Committed
#       Item file names start with ``c:``. In this state it is supposed that
#       the data in the item will be only read.
#
#   Created items (either via spool_mkdir_ or spool_touch_) are initially in
#   a “temporary” state. Items in this state will not be listed by default
#   using spool_items_.
#
#   Additional states with arbitrary names for spool items can be used.
#   State transitions can be manually done by using spool_state_set_. The
#   only thing to care about is not using the ``t``, ``z`` and ``c`` as
#   custom state names.
#
#
#   Functions
#   =========
#--


#++ spool_make_uid
#
#   Creates an unique identifier suitable to be used as temporary item in
#   a spool directory. If available, this function uses the ``uuidgen``
#   program (included as part of `e2fsprogs <http://e2fsprogs.sf.net>`_),
#   otherwise uses the Bash-supplied ``$RANDOM`` variable and the process
#   identifier, which is somewhat weaker, but should work reasonably well.
#
#   .. note:: It is up to the caller preprending the string with the state
#      of the item. This functions does *only* create a suitable name.
#--
spool_make_uid ()
{
    local -r uuidgen=$(type -P uuidgen | head -1)

    if [ "$uuidgen" ] && [ -x "$uuidgen" ]
    then
        # uuidgen is available (and it rocks!)
        echo "$$-$( "$uuidgen" )"
    else
        # Cope with $RANDOM -- not too secure, but works
        echo "$$-$RANDOM-$RANDOM-$RANDOM"
    fi
}

#++ spool_mkdir spooldir
#
#   Creates a new temporary directory in the spool directory. Once data in
#   the directory was filled in spool_commit_ must be applied to it
#   because the directory will be initially marked as temporary.
#--
spool_mkdir ()
{
    local -r item="$1/t:$(spool_make_uid)"
    mkdir "$item"
    echo  "$item"
}


#++ spool_touch spooldir
#
#   Creates a new file in temporary state. Once data gets added to the file
#   spool_commit_ must be applied to it.
#--
spool_touch ()
{
    local -r item="$1/t:$(spool_make_uid)"
    touch "$item"
    echo  "$item"
}


#++ spool_state_get spoolitem
#
#   Obtains the state of a spool item. States are the fierst letters of file
#   names before a colon.
#--
spool_state_get ()
{
    local -r item=${1##*/}
    echo "${item%%:*}"
}


#++ spool_state_set spoolitem state
#
#   Sets the state of an item. The state may be any letter. Note that the
#   implementation of the module already uses ``t``, ``c`` and ``z``;
#   remaining letters may be freely used to mark states. Prints the
#   resulting spool item.
#--
spool_state_set ()
{
    local -r item=${1##*/}
    local -r sdir=${1%/*}
    local -r newi="$2:${item#*:}"
    mv "$1" "$sdir/$newi"
    echo "$sdir/$newi"
}


#++ spool_commit spoolitem
#
#   Commits a spool item. This makes items transition from temporary to
#   commited state. Prints the resulting spool item.
#--
spool_commit ()
{
    [ "$(spool_state_get "$1")" = t ] && spool_state_set "$1" c
}


#++ spool_zap spoolitem [ kind ]
#
#   Deletes one item from the spool directory.
#--
spool_zap ()
{
    rm -fr "$(spool_state_set "$1" z)"
}


#++ spool_items spooldir [ kind ]
#
#   Enumerates items in a spool directory. Spool items are returned as paths
#   to the items including the spool path itself as prefix. Kind may be:
#
#   * ``t`` for temporary items.
#   * ``c`` for commited items (the default).
#--
spool_items ()
{
    local -r kind=${2:-c}
    local -r nullglob=$(shopt -q nullglob && echo true || echo false)

    shopt -q -s nullglob
    for item in "$1/$kind:"*
    do
        echo "$item"
    done
    $nullglob || shopt -q -u nullglob
}


#++ spool_cleanup spooldir [ kind ]
#
#   Cleans up the spool directory. All temporary items and stray in-deletion
#   items will be removed. The latter takes into account the case of an
#   interrupted run of spool_zap_.
#--
spool_cleanup ()
{
    local item

    for item in $(spool_items "$1" t)
    do
        spool_zap "$item"
    done

    for item in $(spool_items "$1" z)
    do
        rm -rf "$1"
    done
}


