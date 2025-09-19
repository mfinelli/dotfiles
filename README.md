# .dotfiles

All configuration is managed via [ansible](https://www.ansible.com).

This is slightly more challenging compared to our old
[GNU Stow](https://www.gnu.org/software/stow/) approach as each file,
directory, symlink, and template needs to be managed manually instead of just
letting stow create a bunch of symbolic links but it allows greater control
and ease-of-use for managing differences across systems and dealing with
secrets.

## usage

### setup

You must have the GPG key used for decrypting the vault (more information
below) available before running the setup step below. If you're using using a
yubikey to store the key material you're done as the setup script automatically
loads the public keys necessary for it to work.

If you're keeping the private key material on the machine then you need to copy
the private key to the new machine and then run the following steps:

```shell
gpg --import ./path/to/key.asc
```

Then you need to edit the key to give it `ultimate` trust:

```shell
gpg --edit-key 36FDA306
```

Then enter `trust` and `5` to `ultimate`ly trust the key, and then `save` to
exit.

You can verify success with

```shell
gpg --list-keys
```

### first run

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

### post-setup

Some roles only install basic configuration but other steps are necessary.
For example to activate `atuin` (in the `zsh` role) you must run the `login`
command. More information is available in the `zsh` role README.

## notes

### vault

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
