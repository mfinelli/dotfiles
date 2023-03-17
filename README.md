# .dotfiles

All configuration is managed via [ansible](https://www.ansible.com).

This is slightly more challenging compared to our old
[GNU Stow](https://www.gnu.org/software/stow/) approach as each file,
directory, symlink, and template needs to be managed manually instead of just
letting stow create a bunch of symbolic links but it allows greater control
and ease-of-use for managing differences across systems and dealing with
secrets.

Get up and running by either cloning this repository and running, `run.bash`,
or all-in-one:

```shell
bash -c "$(curl -fsSL https://mfgo.link/dotfiles)"
```

**N.B.** if you're intending to run the dotfiles on a remote server you need
to forward your ssh agent with the public keys that you intend to write out
unlocked (`ssh-add ~/.ssh/key`).

The initial installation will install the dotfiles into `$HOME/.dotfiles` and
afterwards everything can be updated with `git pull` and `./run.bash`.

## vault

Sensitive files are encrypted with ansible-vault. The vault password was
initialized like so:

```shell
pwgen -cnsy 128 1 | gpg -ear 36FDA306 > vault.asc
```

The work-secret password was initialized like so:

```shell
pwgen -cnsy 128 1 | gpg -ear 36FDA306 -r 4DA7BCBA > work.asc
```

**N.B.** that to view encrypted variables (as opposed to full files) you will
need to have the [yq](https://github.com/mikefarah/yq) utility installed.
