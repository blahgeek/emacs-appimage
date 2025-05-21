#!/bin/bash -ex

cd "$(dirname "$(readlink -f "${0}")")"
rm -rf ./dist

mkdir -p build
pushd build
if [ ! -d emacs-src ]; then
    git clone -b emacs-30.1 --depth 1 https://github.com/emacs-mirror/emacs emacs-src
fi
pushd emacs-src
git clean -dxf
popd
popd

docker build .  # next step has no log, so build first
IMAGE_ID=$(docker build -q .)

./build.sh "$IMAGE_ID" ./build/emacs-src BUILD_GUI=gtk3 BUILD_NATIVE_COMP=no
