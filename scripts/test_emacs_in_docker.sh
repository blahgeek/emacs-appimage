#!/bin/bash -ex

EMACS_APPIMAGE="$(realpath "$1")"

cd "$(mktemp -d)"

cat <<-EOF > test.el
(message "hello world!")
EOF

"$EMACS_APPIMAGE" --appimage-extract
cd squashfs-root
./AppRun --batch -l ../test.el
