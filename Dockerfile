FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive WORK_DIR=/work DIST_DIR=/work/dist DIST_APPDIR=/work/dist/AppDir

RUN mkdir -p $WORK_DIR $DIST_DIR $DIST_APPDIR
WORKDIR $WORK_DIR

# deps for gcc
RUN apt-get update && apt-get install -y \
    xz-utils wget \
    build-essential g++ make file \
    libgmp-dev libmpfr-dev libmpc-dev \
    gcc-8 bison patchelf

RUN wget https://ftp.gnu.org/gnu/gcc/gcc-13.2.0/gcc-13.2.0.tar.xz && \
    tar xf gcc-13.2.0.tar.xz && \
    cd gcc-13.2.0 && \
    ./configure --prefix=$DIST_APPDIR \
    --enable-host-shared --enable-languages=jit,c++ \
    --disable-multilib --enable-checking=release --enable-bootstrap && \
    make -j$(nproc) && \
    make install-strip && \
    cd .. && rm -rf gcc-13.2.0 gcc-13.2.0.tar.xz

# build binutils (ld & as) for libgccjit
# install to /usr/local. will be copied by postprocessor
RUN wget http://ftp.gnu.org/gnu/binutils/binutils-2.41.tar.gz && \
    tar xf binutils-2.41.tar.gz && \
    cd binutils-2.41 && \
    ./configure --prefix=/usr/local/ --enable-static --enable-static-link && \
    make -j$(nproc) && \
    make install-strip && \
    cd .. && rm -rf binutils-2.41 binutils-2.41.tar.gz

# treesitter
RUN wget https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v0.20.8.tar.gz && \
    tar xf v0.20.8.tar.gz

RUN cd tree-sitter-0.20.8 && \
    make -j$(nproc) CC=gcc-8 && \
    make install PREFIX=$DIST_APPDIR

RUN apt-get install -y \
    xorg libx11-dev libgtk-3-dev \
    libjpeg-dev libgif-dev libtiff-dev libxmp-dev \
    libsqlite3-dev libmagickcore-dev libmagickwand-dev \
    libwebp-dev libotf-dev libcairo-dev libjansson-dev \
    libgnutls28-dev libxpm-dev libncurses-dev

# build emacs
RUN wget https://ftp.gnu.org/gnu/emacs/emacs-29.1.tar.xz && \
    tar xf emacs-29.1.tar.xz

RUN cd emacs-29.1 && \
    PATH=$DIST_APPDIR/bin:$PATH LD_LIBRARY_PATH=$DIST_APPDIR/lib LDFLAGS=-L$DIST_APPDIR/lib CPPFLAGS=-I$DIST_APPDIR/include \
    TREE_SITTER_CFLAGS=-I$DIST_APPDIR/include TREE_SITTER_LIBS="-L$DIST_APPDIR/lib/ -ltree-sitter" \
    CC=gcc-8 \
    ./configure \
    --prefix=$DIST_APPDIR \
    --with-native-compilation=aot --disable-locallisppath \
    --with-x --without-pgtk --without-gconf --with-x-toolkit=gtk3 \
    --with-gif --with-jpeg --with-png --with-rsvg --with-tiff --with-imagemagick --with-webp \
    --with-dbus --with-modules --with-libgmp --with-gpm --with-json \
    --with-lcms2 --with-xml2 --with-sqlite3 --with-threads --with-tree-sitter \
    --with-xft --with-cairo --with-harfbuzz --with-libotf \
    --without-m17n-flt \
    --with-imagemagick && \
    PATH=$DIST_APPDIR/bin:$PATH LD_LIBRARY_PATH=$DIST_APPDIR/lib make install-strip -j$(nproc)

ADD resources/AppRun $DIST_APPDIR/AppRun

ADD postprocess.py $WORK_DIR/postprocess.py
RUN python3 postprocess.py $DIST_APPDIR
