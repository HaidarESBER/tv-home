#!/usr/bin/env python3
"""Rewrite backslash entry names (wallpapers\\01.jpg) in an APK to forward slashes.

aapt2 on Windows stores assets with backslashes, which Android's AssetManager can't find.
Usage: python -I fix_apk_paths.py in.apk out.apk
"""
import sys
import zipfile

src, dst = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(src) as zin, zipfile.ZipFile(dst, "w") as zout:
    for info in zin.infolist():
        data = zin.read(info.filename)
        # Raw header name, not the normalised one Python exposes on Windows.
        name = info.orig_filename.replace("\\", "/")
        new = zipfile.ZipInfo(name, date_time=info.date_time)
        new.compress_type = info.compress_type
        new.external_attr = info.external_attr
        zout.writestr(new, data)
print(f"rewrote {src} -> {dst}")
