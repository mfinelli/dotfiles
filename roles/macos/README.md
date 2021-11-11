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
