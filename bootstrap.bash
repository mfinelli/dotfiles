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

GDX=(MDMBMFINELLI.local debian)
FACILE=(CLIFMI706)
MEDIA=(zen)
PSERVER=(cdev.finelli.dev odev parkpi raipi rome.mfpkg.net)

hn="$(hostname)"

if array_contains GDX "$hn"; then
  VAULT_ID=w@./wvault
  mtype=work
  wedition=genedx
elif array_contains FACILE "$hn"; then
  VAULT_ID=w@./wvault
  mtype=work
  wedition=facile
elif array_contains PSERVER "$hn"; then
  mtype=server
  wedition=personal
elif array_contains MEDIA "$hn"; then
  VAULT_ID=p@./vault
  mtype=personal
  wedition=media
else
  VAULT_ID=p@./vault
  mtype=personal
  wedition=none
fi

# yubikey needs this ahead of time to work
gpg --quiet --import 4DA7BCBA.asc

if [[ $mtype == work || $wedition == media ]]; then
  # make sure the yubikey is loaded
  gpg --card-status > /dev/null
fi

curl -s https://finelli.pub/36FDA306.asc | gpg --quiet --import

ansible-galaxy install -r requirements.yml

# if [[ $(uname) == Darwin ]]; then
#   # on macos we set some settings (software update) that require admin
#   needsudo=-K # --ask-become-password
# fi

if [[ $mtype != server ]]; then
  vaultoption="--vault-id ${VAULT_ID}"
else
  vaultoption=""
fi

ansible-playbook $needsudo $vaultoption \
  --inventory localhost \
  --extra-vars whoami="$(whoami)" \
  --extra-vars whoami_group="$(id -gn)" \
  --extra-vars mtype=$mtype \
  --extra-vars wedition=$wedition \
  dotfiles.yml

exit 0
