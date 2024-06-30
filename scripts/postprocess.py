#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import glob
import shutil
import logging
from pathlib import Path
import subprocess
import os
import sys


logging.basicConfig(level=logging.INFO)

APPDIR = Path(sys.argv[1])

def _glob_one(p):
    res = glob.glob(str(p))
    assert len(res) == 1, f'Cannot find exactly one {p}'
    logging.info(f'Glob {p} -> {res[0]}')
    return Path(res[0])

emacs_version = str(_glob_one(APPDIR / 'bin/emacs-*')).split('-')[-1]
logging.info(f'Emacs version: {emacs_version}')

all_bins = [f'emacs-{emacs_version}', 'emacs', 'ebrowse', 'emacsclient', 'etags', 'ctags']

# patchelf
# must do this before processing libraries below, so that we can correctly find dependants of libgccjit.so etc.
for n in all_bins:
    subprocess.run(['patchelf', '--set-rpath', '$ORIGIN/../lib', str(APPDIR / 'bin' / n)])

# remove unwanted bins
for n in (Path(APPDIR) / 'bin').iterdir():
    if n.name not in all_bins:
        n.unlink()

# link pdump file
pdump_file = _glob_one(APPDIR / f'libexec/emacs/{emacs_version}/**/*.pdmp')
os.symlink('../' +str(pdump_file.relative_to(APPDIR)),
           str(APPDIR / 'bin' / f'emacs-{emacs_version}.pdmp'))

# copy desktop files
shutil.copy2(APPDIR / 'share/applications/emacs.desktop', APPDIR / 'emacs.desktop')
shutil.copy2(APPDIR / 'share/icons/hicolor/128x128/apps/emacs.png', APPDIR / 'emacs.png')

# copy as,ld for libgccjit
gccjit_libexec_bin_path = _glob_one(APPDIR / 'libexec/gcc/*/*/')
for n in ['as', 'ld']:
    shutil.copy2(Path('/usr/local/bin/') / n, gccjit_libexec_bin_path / n)

# copy libc related files for libgccjit
gccjit_lib_path = _glob_one(APPDIR / 'lib/gcc/*/*/')
for n in ['crtn.o', 'crti.o']:
    shutil.copy2(_glob_one(f'/usr/lib/**/{n}'), gccjit_lib_path / n)
shutil.copy2(_glob_one('/lib/*/libc.so.6'), gccjit_lib_path / 'libc.so.6')
os.symlink('libc.so.6', str(gccjit_lib_path / 'libc.so'))

# copy libraries
LIB_WHITELIST = [
    'libMagickCore-6.Q16',  # depend by emacs
    'libMagickWand-6.Q16',  # depend by emacs
    'libbz2',  # depend by MagickCore
    'libfftw3',  # depend by MagickCore
    'libgomp',  # depend by MagickWand
    'liblcms2',  # depend by emacs, MagickWand, MagickCore
    'liblqr-1',  # depend by MagickWand, MagickCore
    'libltdl',  # depend by MagickCore

    'librsvg-2',  # depend by emacs
    'libcroco-0.6',  # depend by rsvg

    'libgif',  # depend by emacs
    'libjansson',  # depend by emacs
    'libotf',  # depend by emacs
    'libsqlite3',  # depend by emacs
    'libtinfo',  # depend by emacs
    'libwebpdemux',  # depend by emacs
    'libwebp',  # depend by emacs

    'libmpc',  # depend by libgccjit
    'libmpfr',  # depend by libgccjit

    # 'libdatrie',  # thai

    # 'libtiff',  # depend by emacs. but should be present in users' system by gtk, so do not include
    # 'libjbig',  # depend by tiff
    # 'libjpeg',  # depend by tiff, emacs
    # 'liblzma',  # depend by tiff

    # 'libpng16',  # depend by emacs. but should be present in users' system by gtk, so do not include
]

# hack: replace needed from 0 to 1
LIB_REPLACE = [
    # in new systems, there's libtiff.so.6 instead of libtiff.so.5
    # we cannot simply include libtiff.so.5 because GTK libraries in system would still load libtiff.so.6
    # so let's remove this version requirement. it seems to work
    ('libtiff.so.5', 'libtiff.so'),
]

ldd_output = subprocess.check_output(['ldd', str(APPDIR / 'bin/emacs')], universal_newlines=True)
for line in ldd_output.splitlines():
    if '=>' not in line or 'not found' in line:
        logging.warning(f'Unexpected ldd output: {line}')
        continue
    libpath = Path(line.split()[2])
    if not libpath.exists():
        logging.warning(f'Skipping non-exist library {libpath}')
        continue
    if libpath.parent.resolve() == (APPDIR / 'lib'):
        continue
    libname = libpath.name.split('.so')[0]
    if libname not in LIB_WHITELIST:
        logging.info(f'Skipping non-whitelisted library {libpath}')
        continue
    logging.info(f'Copying {libpath}')
    dst_path = APPDIR / 'lib' / libpath.name
    shutil.copy2(libpath, dst_path)

# patch all libs (not only those just copied), including libgccjit
for n in (APPDIR / 'lib').iterdir():
    if n.is_file() and '.so' in n.name:
        subprocess.run(['patchelf', '--set-rpath', '$ORIGIN', str(n)])

# patch executables
for lib_src, lib_dst in LIB_REPLACE:
    for n in all_bins:
        subprocess.run(['patchelf', '--replace-needed', lib_src, lib_dst, str(APPDIR / 'bin' / n)])
