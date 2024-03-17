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
    'libMagickCore-6.Q16',
    'libMagickWand-6.Q16',
    'libbz2',
    'libcroco-0.6',
    'libdatrie',
    'libfftw3',
    'libgif',
    'libgomp',
    'libjansson',
    'libjbig',
    'libjpeg',
    'liblcms2',
    'liblqr-1',
    'libltdl',
    'liblzma',
    'libotf',
    'libpng16',
    'librsvg-2',
    'libsqlite3',
    'libtiff',
    'libtinfo',
    'libwebpdemux',
    'libwebp',
    # mpc and mpfr is depended by libgccjit
    'libmpc',
    'libmpfr',
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
    subprocess.run(['patchelf', '--set-rpath', '$ORIGIN', dst_path])
