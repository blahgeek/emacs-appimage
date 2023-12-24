# Emacs AppImage

[AppImage](https://appimage.org/) is a single-file executable format for linux.
This repo builds Emacs as AppImages for x86-64 linux systems.

## Highlights

- Enabled native-comp, native json, tree sitter, etc.
- Self-contained, no extra dependencies
- Automatically built on Github Actions

## How-to

1. Download *.AppImage in [release](https://github.com/blahgeek/emacs-appimage/releases/)
2. `chmod +x Emacs.AppImage`
3. `./Emacs.AppImage`

The appimage executable accepts the same arguments as emacs itself.
Furthermore, if you want to run any other binaries shipped with emacs (e.g. `emacsclient`, `etags`),
add `--emacs-appimage-run-as BINARY_NAME` as the first arguments, aka: `./Emacs.AppImage --emacs-appimage-run-as emacsclient xxx yyy`.

## Prerequisite

- A not-too-old linux system (at least ~ ubuntu 18.04, which is the system it's based on)
- Fuse (Should be pre-installed in most distributions. see [here](https://docs.appimage.org/user-guide/troubleshooting/index.html#ref-ug-troubleshooting))

Tested in:

- Ubuntu 20.04
- Fedora 39
