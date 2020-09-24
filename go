#!/bin/bash -e

os="$(uname)"
saveas=.dotfiles

if ! command -v git > /dev/null 2>&1; then
  echo >&2 "error: git not found!"
  exit 1
fi

if [[ $os == Darwin || $os == Linux ]]; then
  cd ~

  if [[ -e $saveas ]]; then
    echo >&2 "error: $saveas directory already exists!"
    exit 1
  fi

  git clone https://github.com/mfinelli/dotfiles.git $saveas

  cd $saveas

  ./bootstrap.bash

  remote="$(git remote -v | grep origin | grep fetch | awk '{print $2}')"

  # switch to ssh remote now we have our ssh keys
  if grep -q '^https' <<< "$remote"; then
    git remote set-url origin git@github.com:mfinelli/dotfiles.git
  fi
else
  echo >&2 "error: unsupported operating system!"
  exit 1
fi

exit 0
