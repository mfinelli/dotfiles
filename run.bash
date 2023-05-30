#!/bin/bash -e

if [[ $(id -u) -eq 0 ]]; then
  echo >&2 "must not run as root!"
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
FACILE=(CLIFMI706)
# shellcheck disable=SC2034
MEDIA=(liveusb zen)
# shellcheck disable=SC2034
GAMING=(bowser wario)
# shellcheck disable=SC2034
PSERVER=(cdev.finelli.dev odev parkpi raipi rome.mfpkg.net ubuilder)

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
  wedition=personal
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

if [[ $mtype != server ]]; then
  vaultoption="--vault-id ${VAULT_ID}"
else
  vaultoption=""
fi

if [[ -n $SSH_TTY ]]; then
  if ! ssh-add -L > /dev/null 2>&1; then
    echo "We seem to be running over SSH but ssh-agent isn't available"
    echo "Are you sure that you forwarded your keys?"
    read -r -n 1 -p "Continue? "
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      exit 1
    fi
  fi
fi

# shellcheck disable=SC2086
ansible-playbook $needsudo $vaultoption \
  --inventory localhost \
  --extra-vars whoami="$(whoami)" \
  --extra-vars whoami_group="$(id -gn)" \
  --extra-vars mtype=$mtype \
  --extra-vars wedition=$wedition \
  --extra-vars isgaming=$isgaming \
  dotfiles.yml

exit 0
