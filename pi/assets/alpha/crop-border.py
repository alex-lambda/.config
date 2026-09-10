"""Crop the dead border off a PNG using only the stdlib. Writes 8-bit grayscale.

The last argument picks which axis to trim. Rows are usually the scarce resource in a
terminal, so "y" is the useful one when a drawing is framed wider than it is tall.
"""

import binascii
import struct
import sys
import zlib

CHANNELS = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}


def read_chunks(data):
    assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
    pos = 8
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos : pos + 4])
        ctype = data[pos + 4 : pos + 8]
        yield ctype, data[pos + 8 : pos + 8 + length]
        pos += 12 + length


def decode(path):
    raw = open(path, "rb").read()
    idat = b""
    ihdr = plte = None
    for ctype, body in read_chunks(raw):
        if ctype == b"IHDR":
            ihdr = struct.unpack(">IIBBBBB", body)
        elif ctype == b"PLTE":
            plte = body
        elif ctype == b"IDAT":
            idat += body

    width, height, depth, color, _comp, _filt, interlace = ihdr
    assert depth == 8, f"only 8-bit supported, got {depth}"
    assert not interlace, "interlaced not supported"
    nch = CHANNELS[color]
    stride = width * nch

    data = zlib.decompress(idat)
    # Undo per-scanline filtering.
    out = bytearray(height * stride)
    prev = bytearray(stride)
    pos = 0
    for y in range(height):
        ftype = data[pos]
        pos += 1
        line = bytearray(data[pos : pos + stride])
        pos += stride
        if ftype == 1:
            for i in range(nch, stride):
                line[i] = (line[i] + line[i - nch]) & 0xFF
        elif ftype == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif ftype == 3:
            for i in range(stride):
                left = line[i - nch] if i >= nch else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 0xFF
        elif ftype == 4:
            for i in range(stride):
                a = line[i - nch] if i >= nch else 0
                b = prev[i]
                c = prev[i - nch] if i >= nch else 0
                p = a + b - c
                pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
                pred = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pred) & 0xFF
        elif ftype != 0:
            raise ValueError(f"bad filter {ftype}")
        out[y * stride : (y + 1) * stride] = line
        prev = line

    # Flatten to single-channel luminance.
    lum = bytearray(width * height)
    for i in range(width * height):
        px = out[i * nch : i * nch + nch]
        if color in (0, 4):
            lum[i] = px[0]
        elif color in (2, 6):
            lum[i] = (px[0] * 299 + px[1] * 587 + px[2] * 114) // 1000
        else:  # palette
            e = plte[px[0] * 3 : px[0] * 3 + 3]
            lum[i] = (e[0] * 299 + e[1] * 587 + e[2] * 114) // 1000
    return width, height, lum


def bbox(width, height, lum, threshold):
    top, bottom, left, right = height, -1, width, -1
    for y in range(height):
        row = lum[y * width : (y + 1) * width]
        hit = [x for x, v in enumerate(row) if v > threshold]
        if not hit:
            continue
        top = min(top, y)
        bottom = y
        left = min(left, hit[0])
        right = max(right, hit[-1])
    return left, top, right, bottom


def write_gray_png(path, width, height, lum):
    def chunk(ctype, body):
        return (
            struct.pack(">I", len(body))
            + ctype
            + body
            + struct.pack(">I", binascii.crc32(ctype + body) & 0xFFFFFFFF)
        )

    raw = bytearray()
    for y in range(height):
        raw.append(0)  # filter: none
        raw += lum[y * width : (y + 1) * width]
    png = (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 0, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(bytes(raw), 9))
        + chunk(b"IEND", b"")
    )
    open(path, "wb").write(png)


USAGE = (
    "usage: crop-border.py <src> <dst> <threshold> <pad-fraction> [both|x|y] [chars-aspect]"
)
if len(sys.argv) not in (5, 6, 7):
    sys.exit(USAGE)
src, dst, thresh, pad_pct = sys.argv[1], sys.argv[2], int(sys.argv[3]), float(sys.argv[4])
axis = sys.argv[5] if len(sys.argv) >= 6 else "both"
if axis not in ("both", "x", "y"):
    sys.exit(USAGE)
# Optional final argument: widen the canvas to a target chars-aspect after cropping.
# Cropping alone cannot make a portrait drawing landscape, and fitDimensions only stops
# filling the terminal height once the aspect clears paneWidth/rows. Padding sideways is
# the one lever that gets a tall image to sit at the same height as the landscape ones.
target_chars = float(sys.argv[6]) if len(sys.argv) == 7 else None
w, h, lum = decode(src)
x0, y0, x1, y1 = bbox(w, h, lum, thresh)
print(f"source {w}x{h}  content bbox x{x0}-{x1} y{y0}-{y1}", file=sys.stderr)
print(f"margins left={x0} right={w - 1 - x1} top={y0} bottom={h - 1 - y1}", file=sys.stderr)

# Pad is a fraction of the ink's extent along the axis being cropped, so the number means
# the same thing whichever axis you trim. An untrimmed axis keeps the canvas edge to edge.
if axis in ("both", "x"):
    pad_x = round((x1 - x0 + 1) * pad_pct)
    x0, x1 = max(0, x0 - pad_x), min(w - 1, x1 + pad_x)
else:
    x0, x1 = 0, w - 1
if axis in ("both", "y"):
    pad_y = round((y1 - y0 + 1) * pad_pct)
    y0, y1 = max(0, y0 - pad_y), min(h - 1, y1 + pad_y)
else:
    y0, y1 = 0, h - 1
cw, ch = x1 - x0 + 1, y1 - y0 + 1

crop = bytearray(cw * ch)
for y in range(ch):
    crop[y * cw : (y + 1) * cw] = lum[(y0 + y) * w + x0 : (y0 + y) * w + x0 + cw]

# A braille cell is 2 dots wide by 4 tall, so chars-aspect is 2 * pixel-aspect.
if target_chars is not None:
    want = round(target_chars * ch / 2)
    if want > cw:
        left = (want - cw) // 2
        padded = bytearray(want * ch)  # zero-filled: black, matching these assets
        for y in range(ch):
            padded[y * want + left : y * want + left + cw] = crop[y * cw : (y + 1) * cw]
        print(f"padded {cw}x{ch} -> {want}x{ch}  (+{left}px each side)", file=sys.stderr)
        crop, cw = padded, want
    else:
        print(f"already wider than {target_chars}:1, no padding", file=sys.stderr)

write_gray_png(dst, cw, ch, crop)
trimmed = f"axis={axis} pad x={pad_x if axis in ('both', 'x') else '-'}px y={pad_y if axis in ('both', 'y') else '-'}px"
print(f"cropped {cw}x{ch}  ({trimmed})  aspect {cw / ch:.4f}  -> chars {2 * cw / ch:.4f}:1")
