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

## Phase 529 更正

Phase 286 的 Harmony 过渡实现把 cropRect 暂按 encoded 域处理；结合 `vuh/bgj/g3` 的完整尺寸链复核后，
Phase 529 确认原版 `g3` 先产出 oriented bitmap，`b40` 再以 oriented `dp5.size` 解释 crop。因此当前
持久化 intrinsic/crop 使用 oriented 域，renderer 以 encoded 轴矩阵桥接 raw bitmap，再执行用户翻转和
oriented crop/fit。上面的顺序记录保留为历史阶段快照，不再作为当前坐标契约。
