#!/bin/bash -e

if [[ $(id -u) -eq 0 ]]; then
  echo >&2 "must not run as root!"
  exit 1
fi

for bin in ansible-playbook ansible-vault; do
  if ! command -v $bin > /dev/null 2>&1; then
    echo >&2 "can not find $bin in path!"
    exit 1
  fi
done

hn="$(hostname)"
if [[ $hn == debian || $hn == MDMBMFINELLI.local ]]; then
  VAULT_ID=w@./wvault
  mtype=work
  wedition=genedx
else
  VAULT_ID=p@./vault
  mtype=personal
  wedition=none
fi

# yubikey needs this ahead of time to work
gpg --quiet --import 4DA7BCBA.asc

if [[ $mtype == work ]]; then
  # make sure the yubikey is loaded
  gpg --card-status > /dev/null
fi

curl -s https://finelli.pub/36FDA306.asc | gpg --quiet --import

ansible-galaxy install -r requirements.yml

# if [[ $(uname) == Darwin ]]; then
#   # on macos we set some settings (software update) that require admin
#   needsudo=-K # --ask-become-password
# fi

ansible-playbook $needsudo --vault-id ${VAULT_ID} \
  --extra-vars whoami="$(whoami)" \
  --extra-vars whoami_group="$(id -gn)" \
  --extra-vars mtype=$mtype \
  --extra-vars wedition=$wedition \
  dotfiles.yml

exit 0
