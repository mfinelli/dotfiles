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

ansible-playbook -i hosts --vault-password-file ./vault dotfiles.yml

exit 0
