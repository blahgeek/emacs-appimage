#!/bin/bash -ex

SCRIPT_DIR=$(dirname "$(readlink -f "${0}")")

cd "$WORK_DIR"

rm -rf emacs
cp -r emacs-src emacs

pushd emacs

./autogen.sh

ARGS=""
ARGS+=" --disable-locallisppath --without-compress-install"
ARGS+=" --with-native-compilation=${BUILD_NATIVE_COMP:-aot}"
ARGS+=" --with-json --with-threads --with-sqlite3 --with-tree-sitter"
ARGS+=" --with-dbus --with-xml2 --with-modules --with-libgmp --with-gpm --with-lcms2"
# always add mps. it will be ignored in master branch.
ARGS+=" --with-mps"

IS_GUI=no

if [[ "$BUILD_GUI" = "pgtk" ]]; then
    IS_GUI=yes
    ARGS+=" --with-pgtk --without-x --without-gconf --without-ns"
elif [[ "$BUILD_GUI" = "x11" || "$BUILD_GUI" = "gtk3" ]]; then
    IS_GUI=yes
    ARGS+=" --with-x --without-pgtk --without-gconf --with-x-toolkit=gtk3"

    # copy GTK related files
    cp -r /usr/lib/$(uname -m)-linux-gnu/gdk-pixbuf-2.0 "$DIST_APPDIR/lib/"
    cp -r /usr/lib/$(uname -m)-linux-gnu/gtk-3.0 "$DIST_APPDIR/lib/"
    cp -r /usr/lib/$(uname -m)-linux-gnu/gio "$DIST_APPDIR/lib/"
    cp -r /usr/share/glib-2.0 "$DIST_APPDIR/share/"
elif [[ "$BUILD_GUI" = "lucid" ]]; then
    IS_GUI=yes
    ARGS+=" --with-x --without-pgtk --without-gconf --with-x-toolkit=lucid"
else
    ARGS+=" --without-x --without-pgtk --without-ns"
fi

# TODO: imagemagick requires dynamic coders. we don't support them correctly now (so it cannot work correctly)
# so disable imagemagick for now
ARGS+=" --without-tiff --without-imagemagick"
if [[ "$IS_GUI" = "yes" ]]; then
    ARGS+=" --with-gif --with-png --with-rsvg --with-webp --with-tiff --with-jpeg"
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
