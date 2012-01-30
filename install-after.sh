#!/bin/sh
# Copyright (C) 2008 Jari Aalto; Licensed under GPL v2 or later
#
# install-after.sh -- Custom installation
#
# The script will receive one argument: relative path to
# installation root directory. Script is called like:
#
#    $ install-after.sh .inst
#
# This script is run after [install] command. NOTE: Echo all messages
# with ">> " prefix".

PATH="/sbin:/usr/sbin/:/bin:/usr/bin:/usr/X11R6/bin"
LC_ALL="C"

set -e

Cmd()
{
    echo "$@"
    [ "$test" ] && return
    "$@"
}

Main()
{
    root=${1:-".inst"}

    if [ ! "$root"  ] || [ ! -d "$root" ]; then
        echo "$0: [ERROR] In $(pwd) no such directory: '$root'" >&2
        return 1
    fi

    root=$(echo $root | sed 's,/$,,')  # Delete trailing slash
    bindir=$root/usr/bin
    sharedir=$root/usr/share
    mandir=$sharedir/man/man1
    emacsdir=$sharedir/emacs/site-lisp
    share=$sharedir/cdargs

    echo ">> install sh lib"
    Cmd install -m 755 -d $share
    Cmd install -m 755 CYGWIN-PATCHES/lib/*sh $share

    echo ">> install emacs"
    Cmd install -m 755 -d $emacsdir
    Cmd install -m 755 contrib/*.el $emacsdir
}

Main "$@"

# End of file
