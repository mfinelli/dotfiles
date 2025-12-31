#!/usr/bin/env bash

set -e

if [[ $(id -u) -eq 0 ]]; then
  echo >&2 "must not run as root!"
  exit 1
fi

if [[ $# -gt 1 ]]; then
  echo >&2 "usage: $(basename "$0") [tag]"
  exit 1
fi

for bin in ansible-playbook ansible-vault hostname; do
  if ! command -v $bin > /dev/null 2>&1; then
    echo >&2 "can not find $bin in path!"
    exit 1
  fi
done

# https://stackoverflow.com/a/14367368
array_contains() {
  local haystack="$1[@]"
  local needle="$2"
  local found=1

  for element in "${!haystack}"; do
    if [[ $element == "$needle" ]]; then
      found=0
      break
    fi
  done

  return $found
}

# Shellcheck returns a false positive here because these variables aren't
# actually referenced as variables in the conditional below, but they _are_
# used
# shellcheck disable=SC2034
FACILE=(CLIFMI1371 CLIFMI706)
# shellcheck disable=SC2034
MEDIA=(liveusb zen)
# shellcheck disable=SC2034
GAMING=(bowser wario)
# shellcheck disable=SC2034
PSERVER=(homepi iris parkpi raipi rome.mfpkg.net tvpi workpi)

hn="$(hostname)"

if array_contains FACILE "$hn"; then
  VAULT_ID=w@./wvault
  mtype=work
  wedition=facile
  isgaming=no
elif array_contains PSERVER "$hn"; then
  mtype=server
  wedition=personal
  isgaming=no
elif array_contains MEDIA "$hn"; then
  VAULT_ID=p@./vault
  mtype=personal
  wedition=media
  isgaming=no
elif array_contains GAMING "$hn"; then
  VAULT_ID=p@./vault
  mtype=personal
  wedition=media
  isgaming=yes
elif [[ $hn =~ ^codespaces- ]]; then
  mtype=server
  wedition=codespace
  isgaming=no
else
  VAULT_ID=p@./vault
  mtype=personal
  wedition=none
  isgaming=no
fi

# yubikey needs this ahead of time to work
gpg --quiet --import 4DA7BCBA.asc

if [[ $mtype == work || $wedition == media ]]; then
  # make sure the yubikey is loaded
  gpg --card-status > /dev/null
fi

curl -s https://finelli.pub/36FDA306.asc | gpg --quiet --import

needsudo=""
# if [[ $(uname) == Darwin ]]; then
#   # on macos we set some settings (software update) that require admin
#   needsudo=-K # --ask-become-password
# fi

macoslaptop="false"
if [[ $(uname) == Darwin ]]; then
  if pmset -g batt | grep -q InternalBattery; then
    macoslaptop="true"
  fi
fi

if [[ $mtype != server ]]; then
  vaultoption="--vault-id ${VAULT_ID}"

  if [[ $VAULT_ID == p@./vault ]]; then
    # also make w@./wvault available if needed
    vaultoption="$vaultoption --vault-id w@./wvault"
  fi
else
  vaultoption=""
fi

if [[ -n $SSH_TTY && $wedition != codespace ]]; then
  if ! ssh-add -L > /dev/null 2>&1; then
    echo "We seem to be running over SSH but ssh-agent isn't available"
    echo "Are you sure that you forwarded your keys?"
    read -r -n 1 -p "Continue? "
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi
fi

tags=""
if [[ -n $1 ]]; then
  # we don't have yq available on all dotfiles platforms yet so only run this
  # check if it's available
  if command -v yq > /dev/null 2>&1; then
    role="$(yq ".[].roles[] | select(.tags == \"$1\").role" dotfiles.yml)"
    if [[ -z $role ]]; then
      echo >&2 "error: want tag '$1' but missing from dotfiles.yml"
      exit 1
    fi
  fi

  tags="--tags $1"
fi

# https://docs.ansible.com/ansible/latest/porting_guides/porting_guide_12.html
export _ANSIBLE_TEMPLAR_UNTRUSTED_TEMPLATE_BEHAVIOR=error

# shellcheck disable=SC2086
ansible-playbook $needsudo $vaultoption $tags \
  --inventory localhost \
  --extra-vars whoami="$(whoami)" \
  --extra-vars whoami_group="$(id -gn)" \
  --extra-vars mtype=$mtype \
  --extra-vars wedition=$wedition \
  --extra-vars isgaming=$isgaming \
  --extra-vars islaptop=$macoslaptop \
  dotfiles.yml

# we set ANSIBLE_HOME now, but this might be left over after the initial run:
# remove it now and then on successive runs it'll be in the right place
[[ -d ~/.ansible ]] && rm -rf ~/.ansible
[[ -f ~/.bash_history ]] && rm -rf ~/.bash_history
[[ -d ~/.zsh_sessions ]] && rm -rf ~/.zsh_sessions

exit 0
