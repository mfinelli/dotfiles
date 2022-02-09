# bash

Configures bash using the [bash-it](https://github.com/Bash-it/bash-it)
framework.

We actually only use `bash` on servers (where our default `zsh` may or may not
be available) and so the configuration here is intended to be lightweight,
offering just a few improvements to make working on a server by SSH a little
easier, while also offering a distinct theme change to make it abundantly
obvious that we're connected to a remote machine and not the localhost.

## profiles

`bash-it` uses so-called profiles to manage which plugins, aliases, and
completions are installed. There isn't a good automation story here, so after
running the dotfiles on a server (and reloading the shell) you will need to
manually load the profile: `bash-it profile load default`. For now we're just
using the provided default profile, but if we were to add any custom profiles
we would do that here in ansible and then write them out to
`~/.bash/bash-it/profiles` where they could be loaded just like the default
profile. More information available at the profiles
[documentation](https://bash-it.readthedocs.io/en/latest/commands/profile/).
