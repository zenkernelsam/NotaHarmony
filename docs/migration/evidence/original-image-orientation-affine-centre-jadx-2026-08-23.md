# 原版图片方向仿射中心证据（2026-08-23）

## 读取范围

- `C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\g3.java`

Desktop 只读；未写入或启动运行态。

## 硬证据

1. `g3.java` case 6 先记录 encoded bitmap 中心：`width = getWidth() / 2.0f`，
   `height = getHeight() / 2.0f`。
2. EXIF horizontal mirror 调用 `postScale(-1, 1, width, height)`。
3. rotation 调用 `postRotate(i7, width, height)`。
4. 90/270 只创建 `height x width` 新 Bitmap；Matrix pivot 没有改用交换后的 oriented 尺寸。
5. map rect 后的平移用于把负偏移移回原点，不改变上述 pivot。

## Harmony 差距与修复

Phase 284～287 的顺序正确，但 renderer 曾把 pivot 写成 `orientedWidth/orientedHeight / 2`。对 90/270
这会使用交换后的中心，造成半像素级以上偏移。Phase 288 改为 `bitmap.width/height / 2`，与原版 Matrix 完全
一致。
