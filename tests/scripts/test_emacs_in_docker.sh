#!/bin/bash -ex

SCRIPTS_DIR="$(realpath "$(dirname "$0")")"
EMACS_APPIMAGE="$(realpath "$1")"

cd "$(mktemp -d)"

cp "$EMACS_APPIMAGE" ./Emacs.AppImage
chmod +x ./Emacs.AppImage

./Emacs.AppImage --appimage-extract
cd squashfs-root

./AppRun --batch -l "$SCRIPTS_DIR/test.el"
