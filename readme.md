# Emacs AppImage

![](https://img.shields.io/github/downloads/blahgeek/emacs-appimage/total)

| Build type | Latest version (click to download) | Status | Notes |
|-----|---|---|---|
| **Release & pre-release** | [![](https://img.shields.io/github/v/release/blahgeek/emacs-appimage?sort=semver&filter=Release*&display_name=release&label=%20)](https://github.com/blahgeek/emacs-appimage/releases?q=Release&expanded=true) | [![](https://github.com/blahgeek/emacs-appimage/actions/workflows/release.yml/badge.svg)](https://github.com/blahgeek/emacs-appimage/releases?q=Release&expanded=true) | |
| **Daily master** | [![](https://img.shields.io/github/v/release/blahgeek/emacs-appimage?include_prereleases&sort=date&filter=Daily%20master%20build*&display_name=release&label=%20)](https://github.com/blahgeek/emacs-appimage/releases?q=Daily+master+build&expanded=true) | [![](https://github.com/blahgeek/emacs-appimage/actions/workflows/daily-master.yml/badge.svg)](https://github.com/blahgeek/emacs-appimage/releases?q=Daily+master+build&expanded=true) | |
| **Weekly mps build** | [![](https://img.shields.io/github/v/release/blahgeek/emacs-appimage?include_prereleases&sort=date&filter=*mps%20build*&display_name=release&label=%20)](https://github.com/blahgeek/emacs-appimage/releases?q=Daily+mps+build&expanded=true) | [![](https://github.com/blahgeek/emacs-appimage/actions/workflows/daily-mps.yml/badge.svg)](https://github.com/blahgeek/emacs-appimage/releases?q=Daily+mps+build&expanded=true) | the experimental MPS GC feature from `feature/igc` branch. does not supports pgtk yet |

[AppImage](https://appimage.org/) is a single-file executable format for linux.
This repo builds Emacs as AppImages for x86-64 & aarch64 linux systems.

## Highlights

- Supports native-comp, native json, tree sitter
- Self-contained, no extra dependencies
- Automatically built on Github Actions
- Provides both latest release and daily master builds

## Version string meanings

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

## Troubleshooting

### Spacemacs reports error like "Lisp directory /tmp/.mount_emacsxxxxx/share/emacs/29.4/etc/: no such directory"

On each execution, Emacs.AppImage mounts itself in a unique temporary directory (/tmp/.mount_emacsxxxxx) and sets environment variables like `EMACSDATA` so that emacs can find data files correctly.
Apparently, Spacemacs would cache environment variables in `.spacemacs.env`, which would break Emacs.AppImage. To fix this, delete related entires in `.spacemacs.env` and restart.
