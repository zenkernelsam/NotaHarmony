from PIL import Image
import sys

path = sys.argv[1]
im = Image.open(path).convert('RGB')
w, h = im.size
px = im.load()
dark = []
for y in range(0, h, 2):
    for x in range(0, w, 2):
        r, g, b = px[x, y]
        if r < 100 and g < 100 and b < 100:
            dark.append((x, y))
print('size', w, h, 'dark_count', len(dark))
if dark:
    xs = [p[0] for p in dark]
    ys = [p[1] for p in dark]
    print('x_range', min(xs), max(xs), 'y_range', min(ys), max(ys),
          'span', max(xs) - min(xs), max(ys) - min(ys))
