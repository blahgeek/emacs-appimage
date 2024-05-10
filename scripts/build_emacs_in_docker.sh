#!/bin/bash -ex

SCRIPT_DIR=$(dirname "$(readlink -f "${0}")")

cd "$WORK_DIR"

cp -r emacs-src emacs

pushd emacs

./autogen.sh

ARGS=""
ARGS+=" --disable-locallisppath"
ARGS+=" --with-json --with-threads --with-sqlite3 --with-tree-sitter"
ARGS+=" --with-dbus --with-xml2 --with-modules --with-libgmp --with-gpm --with-lcms2"
ARGS+=" --with-mps"

if [ "$BUILD_GUI" = "pgtk" ]; then
    ARGS+=" --with-pgtk --without-x --without-gconf --without-ns"
elif [ "$BUILD_GUI" = "x11" ]; then
    ARGS+=" --with-x --without-pgtk --without-gconf --with-x-toolkit=gtk3"
    ARGS+=" --with-xft"
else
    ARGS+=" --without-x --without-pgtk --without-ns"
fi

if [ "$BUILD_GUI" != "no" ]; then
    ARGS+=" --with-gif --with-jpeg --with-png --with-rsvg --with-tiff --with-imagemagick --with-webp"
    ARGS+=" --with-harfbuzz --with-cairo --with-libotf --without-m17n-flt"
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
