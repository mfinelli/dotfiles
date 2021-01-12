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
if [[ $hn == "debian" ]]; then
  VAULT_ID=w@./wvault
  mtype=work
else
  VAULT_ID=p@./vault
  mtype=personal
fi

# yubikey needs this ahead of time to work
gpg --import 4DA7BCBA.asc

curl -s https://finelli.pub/36FDA306.asc | gpg --import

ansible-playbook --vault-id ${VAULT_ID} \
  --extra-vars whoami="$(whoami)" \
  --extra-vars whoami_group="$(id -gn)" \
  --extra-vars mtype=$mtype \
  dotfiles.yml

exit 0
