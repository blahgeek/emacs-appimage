#!/bin/bash -ex

cd "$(dirname "$(readlink -f "${0}")")"
rm -rf ./dist ./build

mkdir build
pushd build
wget https://ftp.gnu.org/gnu/emacs/emacs-29.1.tar.xz
tar xf emacs-29.1.tar.xz
mv emacs-29.1 emacs-src
popd

docker build .  # next step has no log, so build first
IMAGE_ID=$(docker build -q .)

CONTAINER_ID="emacs-appimage-build-$$-$(date +%s)"
docker run \
       --name "$CONTAINER_ID" \
       -v $PWD/build/emacs-src:/work/emacs-src \
       $IMAGE_ID \
       scripts/build_emacs_in_docker.sh

docker cp $CONTAINER_ID:/work/dist ./dist
docker rm -v $CONTAINER_ID

# download appimagetool-x86_64.AppImage if not exists
if [ ! -f ./appimagetool-x86_64.AppImage ]; then
    wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x ./appimagetool-x86_64.AppImage
fi

ARCH=x86_64 ./appimagetool-x86_64.AppImage --no-appstream ./dist/AppDir ./dist/Emacs.AppImage
