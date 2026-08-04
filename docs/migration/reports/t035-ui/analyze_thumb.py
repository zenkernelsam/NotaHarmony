from PIL import Image
import sys

path = sys.argv[1]
im = Image.open(path).convert('RGB')
w, h = im.size
px = im.load()
# 分析左上角卡片网格区域（x 300-1300, y 300-1400）：
# 统计"非灰色"像素（缩略图内容 vs 灰色占位 #E0E0E0）
non_gray = 0
total = 0
for y in range(320, 1400, 3):
    for x in range(320, 1300, 3):
        r, g, b = px[x, y]
        total += 1
        # 灰色占位 #E0E0E0 ≈ (224,224,224)；白色背景 (255,255,255)
        if abs(r - g) > 15 or abs(g - b) > 15 or abs(r - b) > 15:
            non_gray += 1
print('sample_total', total, 'non_gray(彩色内容)', non_gray)
