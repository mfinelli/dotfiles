# .dotfiles

## mutt/mbsync/msmtp

To generate password files (from
[ArchWiki](https://wiki.archlinux.org/index.php/Msmtp#Server_sent_empty_reply))

```shell
$ gpg --encrypt --sign --output .account.gpg -r account -
```

Type the password, press enter for a newline, and then Ctrl-D to encrypt.

## vim

Plugins are managed with [vim-plug](https://github.com/junegunn/vim-plug).

After running the install script you will need to install the other plugins
with the `PlugInstall` command. Restart vim to see the changes.
