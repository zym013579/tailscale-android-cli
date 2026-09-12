#!/usr/bin/env python3
"""Fail the build if a binary is for the wrong OS/CPU or cannot use 16 KiB pages."""
import pathlib
import struct
import sys

path, arch = pathlib.Path(sys.argv[1]), sys.argv[2]
data = path.read_bytes()
assert data[:4] == b'\x7fELF', f'{path}: not ELF'
assert data[5] == 1, 'expected little endian'
assert struct.unpack_from('<H', data, 18)[0] == {'arm': 40, 'arm64': 183, 'amd64': 62}[arch], 'wrong CPU'
assert struct.unpack_from('<H', data, 16)[0] == 3, 'Android release must be PIE (ET_DYN)'
if data[4] == 2:
    offset = struct.unpack_from('<Q', data, 32)[0]
    size, count = struct.unpack_from('<HH', data, 54)
    fmt = '<IIQQQQQQ'
else:
    offset = struct.unpack_from('<I', data, 28)[0]
    size, count = struct.unpack_from('<HH', data, 42)
    fmt = '<IIIIIIII'
interp = None
for i in range(count):
    h = struct.unpack_from(fmt, data, offset + i * size)
    kind = h[0]
    start, length = (h[2], h[5]) if data[4] == 2 else (h[1], h[4])
    if kind == 3:
        interp = data[start:start + length].rstrip(b'\0')
    if kind == 1:
        assert h[-1] >= 16384, f'PT_LOAD alignment {h[-1]} is below 16 KiB'
assert interp in (b'/system/bin/linker', b'/system/bin/linker64'), f'not Android bionic: {interp!r}'
print(f'{path}: Android {arch}, PIE, bionic linker, 16 KiB alignment OK')
