#!/bin/bash -ex

if cat /etc/os-release | grep -i ubuntu; then
    apt-get update && apt-get install -y ubuntu-desktop
fi

EMACS_APPIMAGE="$(realpath "$1")"

cd "$(mktemp -d)"

cp "$EMACS_APPIMAGE" ./Emacs.AppImage
chmod +x ./Emacs.AppImage

cat <<-EOF > test.el
(message "hello world!")
EOF

./Emacs.AppImage --appimage-extract
cd squashfs-root
./AppRun --batch -l ../test.el
