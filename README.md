# .dotfiles

All files managed via [GNU Stow](https://www.gnu.org/software/stow/) where
possible.

## bootstrap

```shell
$ git clone --recursive ... .dotfiles && cd .dotfiles && ./setup
```

It's also possible to install individual components

```shell
$ ./setup bash
```

## uninstall

You can uninstall all or only parts of the configuration (which is done on
a best-effort basis)

```shell
$ ./uninstall [component]
```

## other

### mutt/mbsync/msmtp

To generate password files (from
[ArchWiki](https://wiki.archlinux.org/index.php/Msmtp#Server_sent_empty_reply))

```shell
$ gpg --encrypt --armor --output .account.asc -r account -
```

Type the password, press enter for a newline, and then Ctrl-D to encrypt.

### vim

Plugins are managed with [vim-plug](https://github.com/junegunn/vim-plug).

After running the install script you will need to install the other plugins
with the `PlugInstall` command. Restart vim to see the changes.

### archives

Archives created piping tar directly into gpg:

```shell
$ tar cvz directory | gpg -ear me -o file.tgz.asc
```
 To decrypt:

 ```shell
$ gpg -d file.tgz.asc | tar zxv
 ```
