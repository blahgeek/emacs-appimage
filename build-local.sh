#!/bin/bash -ex

cd "$(dirname "$(readlink -f "${0}")")"
rm -rf ./dist ./build

mkdir build
pushd build
git clone -b 29.2 --depth 1 https://github.com/emacs-mirror/emacs emacs-src
popd

docker build .  # next step has no log, so build first
IMAGE_ID=$(docker build -q .)

./run-and-package.sh "$IMAGE_ID" ./build/emacs-src BUILD_GUI=no
