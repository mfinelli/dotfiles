# .dotfiles

All configuration is managed via [ansible](https://www.ansible.com).

This is slightly more challenging compared to our old
[GNU Stow](https://www.gnu.org/software/stow/) approach as each file,
directory, symlink, and template needs to be managed manually instead of just
letting stow create a bunch of symbolic links but it allows greater control
and ease-of-use for managing differences across systems and dealing with
secrets.

Get up and running by either cloning this repository and running,
`bootstrap.bash`, or all-in-one:

```shell
curl -xo- https://raw.githubusercontent.com/mfinelli/dotfiles/master/go | bash
```

## vault

Sensitive files are encrypted with ansible-vault. The vault password was
initialized like so:

```shell
pwgen -cnsy 128 1 | gpg -ear 36FDA306 > vault.asc
```
