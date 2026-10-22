"""Locate the game's coral OK button in a device screenshot and print its
centre in device pixels.  Usage:  python find_ok_center.py <png>"""
import sys
from PIL import Image

path = sys.argv[1]
im = Image.open(path).convert("RGB")
W, H = im.size
px = im.load()

# the OK button is a flat coral fill; sample-based matching (exact colour
# band) so clouds / grass are not picked up
def is_ok(c):
    r, g, b = c
    return 225 <= r <= 250 and 125 <= g <= 150 and 125 <= b <= 150 and abs(g - b) <= 8

mask = bytearray(W * H)
for y in range(H):
    row = y * W
    for x in range(W):
        if is_ok(px[x, y]):
            mask[row + x] = 1

# connected components (iterative flood fill)
seen = bytearray(W * H)
best = None
for y in range(H):
    row = y * W
    for x in range(W):
        if not mask[row + x] or seen[row + x]:
            continue
        stack = [(x, y)]
        seen[row + x] = 1
        minx = maxx = x
        miny = maxy = y
        n = 0
        while stack:
            cx, cy = stack.pop()
            n += 1
            if cx < minx: minx = cx
            if cx > maxx: maxx = cx
            if cy < miny: miny = cy
            if cy > maxy: maxy = cy
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = cx + dx, cy + dy
                if 0 <= nx < W and 0 <= ny < H:
                    i = ny * W + nx
                    if mask[i] and not seen[i]:
                        seen[i] = 1
                        stack.append((nx, ny))
        if n > 8000 and (best is None or n > best[4]):
            best = (minx, miny, maxx, maxy, n)

if best is None:
    print("NOTFOUND")
    sys.exit(1)

minx, miny, maxx, maxy, n = best
print((minx + maxx) // 2, (miny + maxy) // 2)
