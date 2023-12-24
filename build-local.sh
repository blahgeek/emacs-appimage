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

./run-and-package.sh "$IMAGE_ID" ./build/emacs-src BUILD_WITH_X11=yes
