# 原版图片用户翻转与方向组合顺序证据（2026-08-23）

## 读取范围

- `C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\g3.java`
- `C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\nx0.java`
- `C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\hp5.java`

Desktop 只读；未写入或运行任何原版/鸿蒙运行态。

## 证据

1. `g3.java` case 6 对 orientation 2/4/5/7 先执行 `postScale(-1, 1)`，再对 `w34.l()` rotation 执行
   `postRotate()`，最后 map rect、平移并绘制到 oriented Bitmap。
2. 该回调返回的 drawable 已携带 baked EXIF mirror + rotation；`nx0.java` 通过 `new g3(this, 6)` 复用该
   共享解码路径。
3. `hp5.java` 显示 `ImageBlockImpl` 同时保留 `cropRectRegister`、`imageFlippedVerticallyRegister` 和
   `imageFlippedHorizontallyRegister`，说明 crop 与用户 flip 是 block 状态，不是共享 bitmap 缓存的组成部分。

## Harmony 结论

渲染顺序必须为：encoded crop → baked display orientation → user H/V flip → draw。此前 renderer 在 clip 前
旋转，导致 encoded 坐标 cropRect 落到错误像素区域；Phase 286 将方向变换移动到 clip 后、用户翻转前。
