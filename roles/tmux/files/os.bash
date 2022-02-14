#!/usr/bin/env bash

# script to print out the right os icon for tmux status line
# usage: ./os.sh

if [[ $# -ne 0 ]]; then
  echo >&2 "usage: $(basename "$0")"
  exit 1
fi

# find "nerdfont-complete" and grab the icons from the list
# https://github.com/romkatv/powerlevel10k/blob/master/internal/icons.zsh
if [[ $(uname) == Darwin ]]; then
  echo -e '\uF179' > "${HOME}/.tmux/os.conf"
elif [[ $(uname) == Linux ]]; then
  if [[ -f /etc/os-release ]]; then
    distro="$(grep ^NAME /etc/os-release | awk -F\" '{print $2}')"

    if [[ $distro == "Arch Linux" ]]; then
      echo -e '\uF303' > "${HOME}/.tmux/os.conf"
    elif [[ $distro == "Debian GNU/Linux" ]]; then
      echo -e '\uF306' > "${HOME}/.tmux/os.conf"
    elif [[ $distro == "Ubuntu" ]]; then
      echo -e '\uF31b' > "${HOME}/.tmux/os.conf"
    elif [[ $distro == "CentOS Linux" ]]; then
      echo -e '\uF304' > "${HOME}/.tmux/os.conf"
    else
      echo -e '\uF17C' > "${HOME}/.tmux/os.conf"
    fi
  else
    echo -e '\uF17C' > "${HOME}/.tmux/os.conf"
  fi
else
  echo -e '☺' > "${HOME}/.tmux/os.conf"
fi

exit 0
