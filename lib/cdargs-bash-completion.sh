#!/bin/bash
# (C) 2002-2003 Dan Allen and Stefan Kamphausen

# --------------------------------------------- #
# Bash programming completion for cdargs        #
# Sets the $COMPREPLY list for complete         #
#                                               #
# @param  string substring of alias             #
#                                               #
# @access private                               #
# @return void                                  #
# --------------------------------------------- #
_cdargs_aliases ()
{
    local cur bookmark dir strip oldIFS
    COMPREPLY=()
    if [ -e "$HOME/.cdargs" ]; then
        cur=${COMP_WORDS[COMP_CWORD]}
        if [ "$cur" != "${cur/\//}" ]; then # if at least one /
            bookmark="${cur/\/*/}"
            dir=`grep "^$bookmark " "$HOME/.cdargs" | sed 's#^[^ ]* ##'`
            if [ -n "$dir" -a "$dir" = "${dir/
/}" -a -d "$dir" ]; then
                strip="${dir//?/.}"
                oldIFS="$IFS"
                IFS='
'
                COMPREPLY=( $(
                    compgen -d "$dir`echo "$cur" | sed 's#^[^/]*##'`" \
                        | sed -e "s/^$strip/$bookmark/" -e "s/\([^\/a-zA-Z0-9#%_+\\\\,.-]\)/\\\\\\1/g" ) )
                IFS="$oldIFS"
            fi
        else
            COMPREPLY=( $( (echo $cur ; cat "$HOME/.cdargs") | \
                           awk 'BEGIN {first=1}
                                 {if (first) {cur=$0; l=length(cur); first=0}
                                 else if (substr($1,1,l) == cur) {print $1}}' ) )
        fi
    fi
    return 0
}

# --------------------------------------------- #
# Bash programming completion for cdargs        #
# Set up completion (put in a just so  #
# `nospace' can be a local variable)            #
#                                               #
# @param  none                                  #
#                                               #
# @access private                               #
# @return void                                  #
# --------------------------------------------- #
_cdargs_bash_complete()
{
  if [ ! "CDARGS_BASH_ALIASES" ]; then
      echo '[ERROR] Set CDARGS_BASH_ALIASES=\"cb cdb" to select aliases' \
	   'for commands to complete' >&2
      return 1
  fi

  local nospace=
  [[ "${BASH_VERSINFO[0]}" -ge 3 ||
     (
	  "${BASH_VERSINFO[0]}" = 2 &&
	  (
		"${BASH_VERSINFO[1]}" = 05a ||
	        "${BASH_VERSINFO[1]}" = 05b
	  )
      )
  ]] &&
  nospace='-o nospace'

  complete $nospace -S / -X '*/' -F _cdargs_aliases $CDARGS_BASH_ALIASES
}

# install bash completion
[ "$BASH_VERSION" ] && _cdargs_bash_complete

# End of file
