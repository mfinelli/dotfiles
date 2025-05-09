#!/usr/bin/env bash

# script to print out the right os icon for tmux status line
# usage: ./os.sh

if [[ $# -ne 0 ]]; then
  echo >&2 "usage: $(basename "$0")"
  exit 1
fi

osconffile="${HOME}/.config/tmux/os.conf"

# find "nerdfont-complete" and grab the icons from the list
# https://github.com/romkatv/powerlevel10k/blob/master/internal/icons.zsh
if [[ $(uname) == Darwin ]]; then
  echo -e '\uF179' > "$osconffile"
elif [[ $(uname) == Linux ]]; then
  if [[ -f /etc/os-release ]]; then
    distro="$(grep ^NAME /etc/os-release | awk -F\" '{print $2}')"

    if [[ $distro == "Arch Linux" ]]; then
      echo -e '\uF303' > "$osconffile"
    elif [[ $distro == "Debian GNU/Linux" ]]; then
      echo -e '\uF306' > "$osconffile"
    elif [[ $distro == "Ubuntu" ]]; then
      echo -e '\uF31b' > "$osconffile"
    elif [[ $distro == "CentOS Linux" ]]; then
      echo -e '\uF304' > "$osconffile"
    else
      echo -e '\uF17C' > "$osconffile"
    fi
  else
    echo -e '\uF17C' > "$osconffile"
  fi
else
  echo -e '☺' > "$osconffile"
fi

exit 0
