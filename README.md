# .dotfiles

## mutt/mbsync/msmtp

To generate password files (from
[ArchWiki](https://wiki.archlinux.org/index.php/Msmtp#Server_sent_empty_reply))

```shell
$ gpg --encrypt --sign --output .account.gpg -r account -
```

Type the password, press enter for a newline, and then Ctrl-D to encrypt.
