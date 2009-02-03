#! /usr/bin/env bill
#++
#   =======
#   Logging
#   =======
#   :Author: Adrián Pérez <aperez@igalia.com>
#   :Copyright: Igalia, 2009
#   :License: GPL v2
#   :Abstract: Logging module for use in Bill shell scripts.
#       Vaguely inspired by Python's “logging” module, which in turn is
#       based upon Apache's “log4j” system.
#
#   .. contents::
#--

#++
#   Discussion
#   ==========
#--

#++
#   Log levels
#   ----------
#   There are seven levels of logging. Enabling a higher level of logging
#   also enables the preceding ones. Levels are (in order):
#
#   0. LOG_NONE
#   1. LOG_FATAL
#   2. LOG_ERROR
#   3. LOG_WARN
#   4. LOG_INFO
#   5. LOG_DEBUG
#   6. LOG_TRACE
#
#   Note that ``LOG_NONE`` is noy really a log level, but just a convenience
#   to merely disable logging. Logging functions will not have effect at
#   all at this level, even *no side effects*.
#
#   You can set the log level by assigning the global ``LOG_LEVEL`` variable
#   which, by default, is set to ``LOG_INFO``. You can also control the log
#   level with the log_enable_, log_disable_, log_chattier_ and
#   log_quieter_ functions.
#
#   .. sourcecode:: bash
#
#       # Our program is quiet by default, but increase the log level if
#       # requested by the user...
#       LOG_LEVEL=${LOG_WARN}
#
#       if [ "$FOO_DEBUG" ] ; then
#           log_chattier
#       fi
#
#   You can change the value of ``LOG_LEVEL`` whenever it is needed, but it
#   is usually set only at program startup.
#--
LOG_TRACE=6
LOG_DEBUG=5
LOG_INFO=4
LOG_WARN=3
LOG_ERROR=2
LOG_FATAL=1
LOG_NONE=0

LOG_MAXIMUM=$LOG_TRACE
LOG_MINIMUM=$LOG_FATAL

LOG_LEVEL=$LOG_INFO

__LOG_LEVEL_OLD=$LOG_INFO
__LOG_NAMES=( none fatal error warn info debug trace )


#++
#   Root logger and destinations
#   ----------------------------
#   Unless specified otherwise, by default logging output goes to the so
#   called *root logger*, so there is no need to specify a destination to
#   send messages to it. The root logger is created automatically for you
#   the first time you use a logging function, and it will print messages to
#   standard output. This way using the module is only a matter of:
#
#   .. sourcecode:: bash
#
#       use text/log
#       log_info 'I am a log message'
#
#   If you create a new logger (using log_create_) you can send data to it
#   by putting an exlamation mark (``!``) after the log level and then the
#   name of the logger. Suppose we have created the ``accesslog`` logger,
#   then we would send data to it with:
#
#   .. sourcecode:: bash
#
#       log_create accesslog ... # Put a log chain instead of the ellipsis
#       log_warn ! accesslog 'This message goes to "accesslog"'
#
#   You can change the logger used as *root* by using the log_root_
#   function. This, in combination with the ability of defining your own
#   `log chains`_, allows for bypassing the default initialization:
#
#   .. sourcecode:: bash
#
#       log_create mylog ... # Put a log chain instead of the ellipsis
#       log_root   mylog
#       log_info  'Built-in defaults are not initialized this time'
#
#--

# Map of loggers. Those are undefined until __log_setup_once is called.
# Also, __log_root is checked as flag at setup. Once setup is done, there
# will be at least one root logger configured.
__log_map=''
__log_root=''



#++
#   Log chains
#   ----------
#   The *text/log* module works with *log chains*: a text message which is
#   about to be logged is passed through a series of *filters*, and then
#   final output is done by a *sink*. The full set of components and their
#   ordering is a *log chain*::
#
#       formatter1 » formatter2 » ... » formatterN » sink
#
#   A **formatter** receives the log level and message as arguments, and is
#   responsible of transforming text and echoing it. This way text can be
#   processed before it reaches its destination. A log
#
#   A **sink** is responsible for outputting the messages to whatever
#   destination they may have (files, console, etc).
#
#   Both sinks and formatters may have configuration options, which can be
#   changed and inspected via log_config_. Configuration of components
#   belongs to the chain.
#--

#++
#   Producing output
#   ----------------
#   All output can be done by using the log_ function. `Per-level logging
#   functions`_ are provided as a convenience, though. You mus pass at least
#   the log level and the message to the function:
#
#   .. sourcecode:: bash
#
#       log $LOG_INFO 'This is an informative message'
#       log $LOG_WARN 'This is a warning, so be warned!'
#
#   The destination of such statements will be the current `root logger`__.
#   If you want to change where message go, make sure you define an
#   alternate logger with log_create_ and put its name preceded by
#   a exclamation mark, after the logging level:
#
#   __ `root logger and destinations`_
#
#   .. sourcecode:: bash
#
#       log $LOG_INFO ! $(log_root) 'This is a message for the root logger'
#
#   In the previous example, the log_root_ function is used to get the name
#   of the root logger, but you could specify which logger to use instead.
#   Supposing that you have defined a logger named ``mylog``, that would be:
#
#   .. sourcecode:: bash
#
#       log $LOG_INFO ! mylog 'Message for the "mylog" logger'
#--

#++
#   Per-level logging functions
#   ---------------------------
#   Alongside with the general log_ function, for each one of the `log
#   levels`_ there is a ``log_*`` function (i.e. ``log_info``,
#   ``log_fatal``...) which is a convenience wrapper over the generic one.
#   All those functions accept the same parameters as log_, with the
#   exception of the log level. As an example, the following three lines
#   are equivalent:
#
#   .. sourcecode:: bash
#
#      log $LOG_INFO 'I am an uninformative message'
#      log_info 'I am an uninformative message'
#      log_info ! default 'I am an uninformative message'
#
#   The only difference between both is the number of characters typed.
#   Note that using convenience functions does *not* involve extra
#   function calls when logging is not to be produced.
#--


#++
#   Functions
#   =========
#--


#++ log_chattier
#
#   Increases the log level by one. If level has already reached the maximum
#   useable value, does nothing.
#--
log_chattier ()
{
    if [[ $(( ++LOG_LEVEL )) -ge $LOG_MAXIMUM ]]
    then
        LOG_LEVEL=$LOG_MAXIMUM
    fi
}


#++ log_quieter
#
#   Decreases the log level by one. If level has already reached the minimum
#   useable value, does nothing.
#
#   .. important:: Note that this *never* disables logging completely, use
#      log_disable_ or set ``LOG_LEVEL`` to ``LOG_NONE`` for that.
#--
log_quieter ()
{
    if [[ $(( --LOG_LEVEL )) -le $LOG_MINIMUM ]]
    then
        LOG_LEVEL=$LOG_MINIMUM
    fi
}


#++ log_disable
#
#   Disables logging. This has the same effect of setting ``LOG_LEVEL`` to
#   ``LOG_NONE``, but the active log level will be saved and restored if
#   logging is re-enabled using log_enable_.
#--
log_disable ()
{
    __LOG_LEVEL_OLD=$LOG_LEVEL
    LOG_LEVEL=$LOG_NONE
}


#++ log_enable [ level ]
#
#   Enables logging with a given *level*. If the new level is not given, or
#   it is not one of the valid ``LOG_*`` values, the log level saved by
#   log_disable_ will be restored. If log_disable_ has never been used, the
#   default log level is set.
#
#   .. important:: This function *always* enables some degree af logging,
#      at least the bare minimum of logging fatal errors.
#--
log_enable ()
{
    LOG_LEVEL=$__LOG_LEVEL_OLD
    if [[ $# -gt 0 ]] && [[ $LOG_LEVEL -lt $LOG_MINIMUM || $LOG_LEVEL -le $LOG_MAXIMUM ]]
    then
        LOG_LEVEL=$1
    fi
}


#++ log level [! destination] message
#--
log ()
{
    if [[ $LOG_LEVEL -ge $1 ]] ; then
        __log_real "$@"
    fi
}


log_format_addlevel ()
{
    local level=$1
    shift
    echo "[${__LOG_NAMES[$level]}] $*"
}


log_format_printf ()
{
    shift
    printf "$@"
}



log_format_ttycolor_init ()
{
    use dev/tty
    log_opt ttycolor-level        true
    log_opt ttycolor-${LOG_TRACE} cyan
    log_opt ttycolor-${LOG_DEBUG} blue
    log_opt ttycolor-${LOG_WARN}  yellow
    log_opt ttycolor-${LOG_INFO}  reset
    log_opt ttycolor-${LOG_ERROR} red
    log_opt ttycolor-${LOG_FATAL} red
}


log_format_ttycolor ()
{
    local level=$1
    local reset=$(tty_color_fg reset)
    local color=$(tty_color_fg $(log_opt ttycolor-$level))
    shift

    if $(log_opt ttycolor-level) ; then
        echo "${color}[${__LOG_NAMES[$level]}]${reset} $*"
    else
        echo "${color}$*${reset}"
    fi
}



log_format_date_init () {
    use data/time
    log_opt date-format '%Y-%m-%dT%H:%M:%S'
}

log_format_date ()
{
    shift
    echo "$(time_format "$(log_opt date-format)") $*"
}


log_sink_console ()
{
    # This is darn easy!
    shift
    echo "$*" > /dev/tty
}


log_sink_file_init () {
    log_opt file-path /dev/stderr
}

log_sink_file ()
{
    local filename=$(log_opt file-path)
    shift
    echo "$*" >> "$filename"
}


log_sink_stderr ()
{
    shift
    echo "$*" 1>&2
}


log_opt ()
{
    if [[ $# -eq 2 ]] ; then
        hash_set $SELF "$1" "$2"
    else
        hash_get $SELF "$1"
    fi
}


#++ log_config name option [value]
#--
log_config ()
{
    local object=$(hash_get $__log_map "$1")
    shift
    SELF=$object log_opt "$@"
}


#++ log_root [name]
#
#   Obtains the name of the `root logger`__ when called with no arguments,
#   or changes the root logger when a ``name`` is passed in.
#
#   __ `root logger and destinations`_
#--
log_root ()
{
    if [[ $# -gt 0 ]] ; then
        hash_has $__log_map "$1" || die "No logger '$1' was configured"
        __log_root=$1
    else
        echo "$__log_root"
    fi
}


#++ log_create name sink [formatter1 [formatter2 ... [formatterN]
#
#   Creates a new logging chain associated to a ``name``, which outputs
#   messages using to a particular ``sink``. Formatting of the message
#   strings will pass along ``formatter1``, ``formatter2`` and so on until
#   ``formatterN`` (in that order) before being passed to the sink. The
#   function takes care of initializing components of the chain of filters
#   and the sink to their default values, it is the responsibility of the
#   programmer to reconfigure the items as desired using log_config_.
#
#   **See also:** log_destroy_, log_replace_, log_config_
#--
log_create ()
{
    local item
    local name=$1
    local sink=$2
    local object=$(hash_new)
    local -a callbacks=( )
    local -a cleanups=( )
    shift 2

    if [[ $(type -t "log_sink_${sink}" 2> /dev/null) != function ]] ; then
        die "Fatal: log sink '$sink' does not exist"
    fi

    if [[ $(type -f "log_sink_${sink}_init" 2> /dev/null) = function ]] ; then
        SELF=$object log_sink_${sink}_init
    fi

    for item in "$@" ; do
        if [[ $(type -t "log_format_${item}" 2> /dev/null) != function ]] ; then
            die "Fatal: log formatter '$item' does not exist"
        fi

        # Check whether we have an initializer, and run it
        if [[ $(type -t "log_format_${item}_init") = function ]] ; then
            SELF=$object log_format_${item}_init
        fi

        callbacks=( "${callbacks[@]}" log_format_${item} )

        if [[ $(type -t "log_format_${item}_cleanup" 2> /dev/null) = function ]] ; then
            # Cleanup functions are called in reverse order
            cleanups=( log_format_${item}_cleanup "${cleanups[@]}" )
        fi
    done
    callbacks=( "${callbacks[@]}" log_sink_${sink} )

    if [[ $(type -t "log_sink_${sink}_cleanup" 2> /dev/null) = function ]] ; then
        cleanups=( log_sink_${sink}_cleanup "${cleanups[@]}" )
    fi

    # Great, we are there!
    hash_set $object chain "${callbacks[*]}"
    hash_set $object clean "${cleanups[*]}"
    hash_set $__log_map "$name" "$object"
}


#++ log_destroy name
#
#   Destroys a logger given its ``name``. This is frees resources which
#   could be allocated by log_create_ during initialization of the logger
#   components.
#
#   **See also:** log_create_, log_replace_
#--
log_destroy ()
{
    # No-op if to-remove logger was not created
    hash_has $__log_map "$1" || return

    local object=$(hash_get $__log_map "$1")
    local chain=$(hash_get $object clean)
    local item

    for item in ${chain} ; do
        SELF=$object "$item"
    done
    hash_clear $object
}


#++ log_replace name sink [formatter1 [formatter2 ... [formatterN]]]
#
#   Destroys a logger and creates a new one with the same name, thus
#   replacing the existing logger. This is mainly useful to redefine the
#   ``default`` logger at startup and avoid having to type in the
#   destination of messages in every call to the log functions. Do not
#   forget to use log_config_ to customize the new logger.
#
#   **See also:** log_create_, log_destroy_
#--
log_replace ()
{
    log_destroy "$1"
    log_create "$@"
}


__log_setup_once ()
{
    # Check if setup was already done
    [[ -n $__log_root ]] && return

    use data/hash
    __log_map=$(hash_new)

    # XXX Default logger and its setup is hardwired here.
    log_create default stderr ttycolor
    __log_root=default
}


# This is the real workhorse...
__log_real ()
{
    if [[ $1 -lt $LOG_MINIMUM ]] && [[ $1 -gt $LOG_MAXIMUM ]] ; then
        die "Fatal: log level '$1' is unknown!"
    fi
    __log_setup_once

    local root=$__log_root
    local level=$1
    shift

    if [[ $1 = ! ]] ; then
        root=$2
        shift 2
    fi
    local logger=$(hash_get $__log_map "$root")
    local chain=$(hash_get $logger chain)
    local item

    for item in ${chain} ; do
        set -- "$(SELF=$logger "$item" "$level" "$@")"
    done
}



# Clever trick used to autogenerate functions for different logging levels
for (( __log_l3v3l=LOG_MINIMUM; __log_l3v3l<=LOG_MAXIMUM; __log_l3v3l++ )) ; do
    eval "log_${__LOG_NAMES[$__log_l3v3l]} () {
        [[ \$LOG_LEVEL -eq 0 ]] && return
        [[ \$LOG_LEVEL -lt $__log_l3v3l ]] || __log_real $__log_l3v3l \"\$@\"
    }"
done
unset __log_l3v3l

