#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import typing as tp
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

def _is_relative_to(a, b):
    try:
        a.relative_to(b)
        return True
    except ValueError:
        return False

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

# ---
# process dynamic libs
# ---
class NeededLib:

    def __init__(self, name: str, resolved_path: Path):
        self.name = name
        self.resolved_path = resolved_path
        self.needed_libs = []

    def _collect(self, result):
        for l in self.needed_libs:
            result[l.name] = l.resolved_path
            l._collect(result)

    def collect(self) -> tp.Dict[str, Path]:
        '''
        Collect all nodes in current tree (except self).
        '''
        result = {}
        self._collect(result)
        return result

    def _trim(self, name_prefix, trimmed_names: tp.Set[str]):
        kept_libs = []
        for x in self.needed_libs:
            if not x.name.startswith(name_prefix):
                kept_libs.append(x)
            else:
                trimmed_names.add(x.name)
                trimmed_names.update(x.collect().keys())
        self.needed_libs = kept_libs
        for x in self.needed_libs:
            x._trim(name_prefix, trimmed_names)

    def trim(self, name_prefix) -> tp.Set[str]:
        '''
        Delete node whose name starts with name_prefix, along with all their children.
        '''
        trimmed_names = set()
        self._trim(name_prefix, trimmed_names)
        return trimmed_names

def _leading_space_count(s) -> int:
    n = 0
    while n < len(s) and s[n] == ' ':
        n = n + 1
    return n

def _parse_lddtree(lddtree_output: str) -> NeededLib:
    lines = lddtree_output.rstrip().splitlines()
    assert not lines[0].startswith(' ')
    line_i = 1

    def _parse_node(node, expected_level):
        nonlocal line_i
        while line_i < len(lines):
            line = lines[line_i]
            level = _leading_space_count(line) // 4

            if level > expected_level:
                assert level == expected_level + 1
                assert len(node.needed_libs) > 0
                _parse_node(node.needed_libs[-1], expected_level + 1)
                continue

            if level < expected_level:
                return

            parts = line.strip().split(' => ')
            assert len(parts) == 2
            node.needed_libs.append(
                NeededLib(name=parts[0], resolved_path=Path(parts[1]))
            )
            line_i = line_i + 1

    root = NeededLib(name='', resolved_path=Path())
    _parse_node(root, 1)
    return root


lddtree_output = subprocess.check_output(
    ['lddtree', '-a', str(APPDIR / 'bin/emacs')],
    universal_newlines=True,
)
lddtree = _parse_lddtree(lddtree_output)


# this is prefix
LIB_BLACKLIST = [
    # X related
    'libX',  # prefix
    'libxcb.so',
    'libxcb-shape.so',
    'libSM.so',
    'libICE.so',
    # GUI base system
    'libfreetype.so',
    'libfontconfig.so',
    'libharfbuzz.so',
    'libGL',
    'libOpenGL',
    'libEGL',
    'libdbus-1.so',
    # base system
    'libgcc_s.so',
    'libstdc++.so.6',
    # glibc
    'libpthread.so',
    'librt.so',
    'libc.so',
    'libc_',
    'libdl.so',
    'libresolv.so',
    'libz.so',
    'libm.so',
    'libanl.so',
    'libnss_',
    'libutil.so',
]

# Remove lib from blacklist
# also, remove all its children
for name in LIB_BLACKLIST:
    trimmed_names = lddtree.trim(name)
    for trimmed_name in trimmed_names:
        logging.warning(f'Removed lib {trimmed_name} (due to {name})')
        lddtree.trim(trimmed_name)

for name, libpath in lddtree.collect().items():
    if _is_relative_to(libpath.resolve(), APPDIR):  # e.g. libgccjit
        continue
    logging.info(f'Copying {name} ({libpath})')
    dst_path = APPDIR / 'lib' / libpath.name
    shutil.copy2(libpath, dst_path)

# patch all libs (not only those just copied), including libgccjit
for n in (APPDIR / 'lib').iterdir():
    if n.is_file() and '.so' in n.name:
        subprocess.run(['patchelf', '--set-rpath', '$ORIGIN', str(n)])
