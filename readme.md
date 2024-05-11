# Emacs AppImage

[AppImage](https://appimage.org/) is a single-file executable format for linux.
This repo builds Emacs as AppImages for x86-64 linux systems.

## Highlights

- Supports native-comp, native json, tree sitter
- Self-contained, no extra dependencies
- Automatically built on Github Actions
- Provides both latest release and daily master builds

## Download

- **[Latest Release](https://github.com/blahgeek/emacs-appimage/releases/latest)**
- **[Daily master build](https://github.com/blahgeek/emacs-appimage/releases/)**

## Version string meanings

- **NEW!** `mps`: the experimental MPS GC feature from `scratch/igc` branch, in daily master build only. This version does not supports native-comp or pgtk yet.
- `x11`: built with X11 GUI support
- `pgtk`: built with PGTK GUI support, for wayland desktop
- `nox`: built without GUI support

## How-to

1. Download *.AppImage
2. `chmod +x Emacs.AppImage`
3. `./Emacs.AppImage`

The appimage executable accepts the same arguments as emacs itself.

Furthermore, if you want to run any other binaries shipped with emacs (e.g. `emacsclient`, `etags`),
add `--emacs-appimage-run-as BINARY_NAME` as the first arguments, aka: `./Emacs.AppImage --emacs-appimage-run-as emacsclient xxx yyy`.

## Prerequisite

- A not-too-old linux system (at least ~ ubuntu 18.04, which is the system it's built on)
- FUSE 2.x, which should be pre-installed in most distributions.
  - Recent distributions (e.g. ubuntu 22.04+) may have FUSE 3.x installed instead, you need to also install the 2.x version.
  - For more help, see [here](https://docs.appimage.org/user-guide/troubleshooting/fuse.html#setting-up-fuse-2-x-alongside-of-fuse-3-x-on-recent-ubuntu-22-04-debian-and-their-derivatives)

Tested in:

- Ubuntu 20.04
- Fedora 39
