#!/bin/bash
# (C) 2002-2003 Dan Allen and Stefan Kamphausen
#
# Written by Dan Allen <dan@mojavelinux.com>
# - small additions by Stefan Kamphausen
# - better completion code by Robi Malik robi.malik@nexgo.de
# - trailing path support by Damon Harper <ds+dev-cdargs@usrbin.ca> Feb 2006
# - Namespace fix  work as library by Jari Aalto <jari.aalto@cante.net> 2008

# Globals
CDARGS_SORT=${CDARGS_SORT:-0}  # set to 1 if you want mark to sort the list
CDARGS_NODUPS=${CDARGS_NODUPS:-1} # set to 1 if you want mark to delete dups

#################################################
#
#   P U B L I C
#
#################################################

# --------------------------------------------- #
# Mark the current directory with alias         #
# provided and store as a cdargs bookmark       #
# directory                                     #
#                                               #
# @param  string alias                          #
#                                               #
# @access public                                #
# @return void                                  #
# --------------------------------------------- #
_cdargs ()
{
    local tmpfile

    if [ "$1" = "-f" ] || [ "$1" = "--force" ]; then
	# first clear any bookmarks with this same alias, if file exists
	if [ "$CDARGS_NODUPS" ] && [ -e "$HOME/.cdargs" ]; then
	    tmpfile=`echo ${TEMP:-${TMPDIR:-/tmp}} | sed -e "s/\\/$//"`
	    tmpfile=$tmpfile/cdargs.$USER.$$.$RANDOM

	    grep -v "^$1 " "$HOME/.cdargs" > "$tmpfile" &&
	    mv -f "$tmpfile" "$HOME/.cdargs"
	fi
    fi

    # add the alias to the list of bookmarks
    cdargs --add=":$1:`pwd`"

    # sort the resulting list
    if [ "$CDARGS_SORT" ]; then
        sort -o "$HOME/.cdargs" "$HOME/.cdargs"
    fi
}

# --------------------------------------------- #
# Mark the current directory with alias         #
# provided and store as a cdargs bookmark       #
# directory but do not overwrite previous       #
# bookmarks with same name                      #
#                                               #
# @param  string alias                          #
#                                               #
# @access public                                #
# @return void                                  #
# author: SKa                                   #
# --------------------------------------------- #
#
# The functionality was moved to cdargs() by adding
# ---force option. (Jari Aalto)
#
# ca ()
# {
#     # add the alias to the list of bookmarks
#     cdargs --add=":$1:`pwd`"
# }

# --------------------------------------------- #
# Prepare to move file list into the cdargs     #
# target directory                              #
#                                               #
# @param  string command argument list          #
#                                               #
# @access public                                #
# @return void                                  #
# --------------------------------------------- #
_cdargs_mvb ()
{
    local command

    command='mv -i'
    _cdargs_exec "$@"
}

# --------------------------------------------- #
# Prepare to copy file list into the cdargs     #
# target directory                              #
#                                               #
# @param  string command argument list          #
#                                               #
# @access public                                #
# @return void                                  #
# --------------------------------------------- #
_cdargs_cpb ()
{
    local command

    command='cp -i'
    _cdargs_exec "$@"
}

# --------------------------------------------- #
# Change directory to the cdargs target         #
# directory                                     #
#                                               #
# @param  string alias                          #
#                                               #
# @access public                                #
# @return void                                  #
# --------------------------------------------- #
_cdargs_cdb ()
{
    local dir

    _cdargs_get_dir "$1" &&
    cd "$dir" &&
    echo `pwd`
}

#################################################
#
#   P R I V A T E
#
#################################################

# --------------------------------------------- #
# Run the cdargs program to get the target      #
# directory to be used in the various context   #
# This is the fundamental core of the           #
# bookmarking idea.  An alias or substring is   #
# expected and upon receiving one it either     #
# resolves the alias if it exists or opens a    #
# curses window with the narrowed down options  #
# waiting for the user to select one.           #
#                                               #
# @param  string alias                          #
#                                               #
# @access private                               #
# @return 0 on success, >0 on failure           #
# --------------------------------------------- #
_cdargs_get_dir ()
{
    local bookmark extrapath
    # if there is one exact match (possibly with extra path info after it),
    # then just use that match without calling cdargs
    if [ -e "$HOME/.cdargs" ]; then
        dir=`grep "^$1 " "$HOME/.cdargs"`
        if [ -z "$dir" ]; then
            bookmark="${1/\/*/}"
            if [ "$bookmark" != "$1" ]; then
                dir=`grep "^$bookmark " "$HOME/.cdargs"`
                extrapath=`echo "$1" | sed 's#^[^/]*/#/#'`
            fi
        fi
        [ -n "$dir" ] && dir=`echo "$dir" | sed 's/^[^ ]* //'`
    fi
    if [ -z "$dir" -o "$dir" != "${dir/
/}" ]; then
        # okay, we need cdargs to resolve this one.
        # note: intentionally retain any extra path to add back to selection.
        dir=
        if cdargs --noresolve "${1/\/*/}"; then
            dir=`cat "$HOME/.cdargsresult"`
            rm -f "$HOME/.cdargsresult"
        fi
    fi
    if [ -z "$dir" ]; then
        echo "Aborted: no directory selected" >&2
        return 1
    fi
    [ -n "$extrapath" ] && dir="$dir$extrapath"
    if [ ! -d "$dir" ]; then
        echo "Failed: no such directory '$dir'" >&2
        return 2
    fi
}

# --------------------------------------------- #
# Perform the command (cp or mv) using the      #
# cdargs bookmark alias as the target directory #
#                                               #
# @param  string command argument list          #
#                                               #
# @access private                               #
# @return void                                  #
# --------------------------------------------- #
_cdargs_exec ()
{
    local arg dir i last call_with_browse

    # Get the last option which will be the bookmark alias
    eval last=\${$#}

    # Resolve the bookmark alias.  If it cannot resolve, the
    # curses window will come up at which point a directory
    # will need to be choosen.  After selecting a directory,
    # the will continue and $_cdargs_dir will be set.
    if [ -e $last ]; then
        last=
    fi
    if _cdargs_get_dir "$last"; then
        # For each argument save the last, move the file given in
        # the argument to the resolved cdargs directory
        i=1
        for arg; do
            if [ $i -lt $# ]; then
                $command "$arg" "$dir"
            fi
            let i=$i+1
        done
    fi
}

# End of file
