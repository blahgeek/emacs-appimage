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
RUN apt-get install -y git texinfo

ADD scripts /work/scripts
