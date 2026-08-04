from PIL import Image
import sys

path = sys.argv[1]
im = Image.open(path).convert('RGB')
w, h = im.size
px = im.load()
# 画布区域：排除顶部工具栏/左侧栏/底部页面条（x 400-2200, y 380-1380）
dark = []
for y in range(380, 1380, 2):
    for x in range(400, 2200, 2):
        r, g, b = px[x, y]
        if r < 100 and g < 100 and b < 100:
            dark.append((x, y))
print('canvas_dark_count', len(dark))
if dark:
    xs = [p[0] for p in dark]
    ys = [p[1] for p in dark]
    print('x_range', min(xs), max(xs), 'y_range', min(ys), max(ys),
          'x_span', max(xs) - min(xs), 'y_span', max(ys) - min(ys))
    # y 直方图（每 50px 一段）
    bins = {}
    for p in dark:
        b = p[1] // 50
        bins[b] = bins.get(b, 0) + 1
    for b in sorted(bins):
        print('y_bin', b * 50, '-', b * 50 + 50, ':', bins[b])
