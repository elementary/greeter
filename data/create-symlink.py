#!/usr/bin/env python3

import os
import sys

if len(sys.argv) < 3:
    print('Usage: create-symlink.py SOURCE DESTINATION')
    sys.exit(1)

src = sys.argv[1]
dest = sys.argv[2]

if 'MESON_INSTALL_DESTDIR_PREFIX' in os.environ:
    src = os.path.join(os.environ['MESON_INSTALL_DESTDIR_PREFIX'], src)
    dest = os.path.join(os.environ['MESON_INSTALL_DESTDIR_PREFIX'], dest)

if os.path.isabs(src):
    src = os.path.relpath(src, os.path.dirname(os.path.realpath(dest)))

if not os.path.exists(dest):
    print('Creating symbolic link: ' + dest + ' -> ' + src)
    if not os.path.exists(os.path.dirname(dest)):
        os.makedirs(os.path.dirname(dest))
    os.symlink(src, dest)
