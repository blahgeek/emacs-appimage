#!/bin/bash -ex

SCRIPT_DIR=$(dirname "$(readlink -f "${0}")")

cd "$WORK_DIR"

cp -r emacs-src emacs

pushd emacs

./autogen.sh

ARGS=""
ARGS+=" --disable-locallisppath"
ARGS+=" --with-native-compilation=${BUILD_NATIVE_COMP:-aot}"
ARGS+=" --with-json --with-threads --with-sqlite3 --with-tree-sitter"
ARGS+=" --with-dbus --with-xml2 --with-modules --with-libgmp --with-gpm --with-lcms2"
# always add mps. it will be ignored in master branch.
ARGS+=" --with-mps"

if [ "$BUILD_GUI" = "pgtk" ]; then
    ARGS+=" --with-pgtk --without-x --without-gconf --without-ns"
elif [ "$BUILD_GUI" = "x11" ]; then
    ARGS+=" --with-x --without-pgtk --without-gconf --with-x-toolkit=gtk3"
    ARGS+=" --with-xft"
else
    ARGS+=" --without-x --without-pgtk --without-ns"
fi

# TODO: libtiff caused some trouble on compatibility:
# it's depend by gtk (which we donot bundle) and have incompatible APIs between versions.
# so disable libtiff for now
# TODO: imagemagick requires dynamic coders. we don't support them correctly now (so it cannot work correctly)
# so disable imagemagick for now
ARGS+=" --without-tiff --without-imagemagick"
if [ "$BUILD_GUI" != "no" ]; then
    ARGS+=" --with-gif --with-png --with-rsvg --with-webp"
    ARGS+=" --with-harfbuzz --with-cairo --with-libotf --without-m17n-flt"
    # use static lib for libjpeg, to prevent incompatible libjpeg.so version because it's depend by gtk
    ARGS+=" --with-jpeg emacs_cv_jpeglib=/usr/lib/x86_64-linux-gnu/libjpeg.a"
fi


env \
    PATH=$DIST_APPDIR/bin:$PATH \
    LD_LIBRARY_PATH=$DIST_APPDIR/lib \
    LDFLAGS=-L$DIST_APPDIR/lib \
    CPPFLAGS=-I$DIST_APPDIR/include \
    TREE_SITTER_CFLAGS=-I$DIST_APPDIR/include \
    TREE_SITTER_LIBS="-L$DIST_APPDIR/lib/ -ltree-sitter" \
    CC=gcc-8 \
    ./configure \
    --prefix=$DIST_APPDIR \
    $ARGS
env \
    PATH=$DIST_APPDIR/bin:$PATH \
    LD_LIBRARY_PATH=$DIST_APPDIR/lib \
    bash -c "make -j$(nproc) && make install"
popd

cp $SCRIPT_DIR/AppRun $DIST_APPDIR/AppRun
python3 $SCRIPT_DIR/postprocess.py $DIST_APPDIR
