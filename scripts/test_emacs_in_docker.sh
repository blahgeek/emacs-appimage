#!/bin/bash -ex

EMACS_APPIMAGE="$(realpath "$1")"

cd "$(mktemp -d)"

cp "$EMACS_APPIMAGE" ./Emacs.AppImage
chmod +x ./Emacs.AppImage

cat <<-EOF > test.el
(native-compile '(lambda (x) (* x 2)))
(message "hello world!")
EOF

./Emacs.AppImage --appimage-extract
cd squashfs-root
./AppRun --batch -l ../test.el
