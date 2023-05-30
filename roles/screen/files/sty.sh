#!/bin/sh

# I only want to output the session name if it's a named session which doesn't
# seem to be possible using only the caption. I also want to upcase the
# session name which I know is not possible (see hn.sh). I would like to just
# use the $STY varible that screen exposed but it's not available in the
# context of this script when executed by screen to create backtick variables
# so instead we need to grep it from the list of screen sessions using the
# process id. Since this is POSIX sh and not bash we need to use grep instead
# of a bash regex (and why we need to echo into grep instead of using a
# here-string). This script only ever operates in the context of screen so
# it's safe to operate on the STY, but the main caveat is that it's kind of
# dumb: if the session name includes one or more "."s then it will assume that
# the session is _not_ named and won't print anything out. But it will
# otherwise work and I never include "." in my screen session names anyway.

STY_GREP="$(screen -ls 2>&1 | grep "$PPID" | awk '{print $1}')"
if ! echo "$STY_GREP" | grep -q '^.*\..*\..*$'; then
  echo "$STY_GREP" | sed -e 's|.*\.||' | tr '[:lower:]' '[:upper:]'
fi
