# macos

Attempt to set as many settings as possible to avoid needing to click around
in preferences and settings menus.

Some good references:

- https://marslo.github.io/ibook/osx/defaults.html#finder

## manual steps

Unfortunately, it's not currently possible to set every desired setting via
automation due to limitations in the ansible module (doesn't support setting
`dict` values for example) and what settings are exposed (or able to be found
after exporting defaults, changing a setting, exporting them again and running
a diff) so I'm documenting settings that need to be set manually with the GUI
here:

- Desktop background image: Settings -> Desktop & Screen Saver -> Desktop
  (I'm currently using the default dynamic wallpaper for the macOS release)
- Screen saver style: Settings -> Desktop & Screen Saver -> Screen Saver
  (I'm currently using "Flurry" with the default options)
- Mission control keyboard shortcuts -> Mission Control (I'm setting "Mission
  Control" to ^↑ [Ctrl + Up Arrow], "Application windows" to ^↓ [Ctrl + Down
  Arrow], and leaving "Show Desktop" with the default F11)
- Night shift: Settings -> Displays -> Night Shift (I currently enable it on
  schedule from sunset to sunrise)
- Allow unlock with Apple Watch: Settings -> Security and Privacy -> General ->
  allow Apple Watch to unlock mac and apps (I currently enable this)

## other

I think some of these settings may be defaults or depend on options that you
choose when first setting up a new macOS system, and I have had mixed results
testing `defaults` options that always work (and in some cases they require
`sudo` which isn't very desirable for a dotfiles workflow) so I'm just
documenting them here. I manage my own updates on my own schedule, thank you
very much. (Plus I like to read the release notes!)

- Make sure that in the App Store updates are not set to automatically
  download or install and that Apps downloaded/purchased on other systems are
  also not set to automatically install.
- In system preferences ensure that "Keep my mac up-to-date" is not checked.
