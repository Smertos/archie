# Archie

## Description
Archie is collection of quick-installation scripts for ArchLinux

For now it only does basic setup (aka ArchWiki Installation Guide) with GRUB and no users

## Installation

It's pretty simple, just do these commands:

``` sh
pacman -Sy git
git clone https://github.com/Smertos/archie
cd archie
vim settings.sh
./install.sh
```

Haven't check yet, if scripts need to be given executable flag after cloning

## Roadmap
* User setup script 
** Probably gonna try to implement it as curses menu or smthng)
** Would be nice if we forced/offered to setup root password (so we don't forget about the need to set it)
* User environment setup script (dotfiles)
** Probably would want to make another repo with updated dotfiles of mine and set them as some default or just force them
* Log the setup process
** Debugging small stuff when the setup is so fast is difficult, best to implement logs for everything in case anything goes wrong
** Also should probably do lots of output redirection to logs, as to keep the terminal clean (only show out messages/errors)
* Bootstrap script with short URL
** 'cuz I'm lazy
