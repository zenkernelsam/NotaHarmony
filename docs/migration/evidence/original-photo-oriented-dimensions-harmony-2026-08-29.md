# Harmony 证据：原版照片入口的 oriented intrinsic 尺寸

日期：2026-08-29

## 原版硬证据

只读来源：

- `C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\vuh.java`
- `C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\bgj.java`

`vuh.b()` 的顺序是：

```text
encoded header -> EXIF rotation -> oriented i3/i4 -> ep5(i3, i4)
                                      \-> encoded-axis sample plan
```

`bgj` 使用 `ep5.a/b` 进入 `qed` 和 `bvh.a`，所以 IMAGE block 的尺寸是 oriented
属性，而不是未经方向化的 encoded header。

## 缺口复现

旧 Harmony 路径：

```text
OriginalPhotoIngressItem(encodedWidth, encodedHeight, orientedWidth, orientedHeight)
  -> NoteCanvasView.intrinsicWidth = encodedWidth
```

对 encoded `3000×2000`、EXIF 6 输入，实际应为 oriented `2000×3000`；旧路径
写成 `3000×2000`，会让 block fit、CREATE_BLOCK size 与 decoded oriented 校验
不一致。

## Phase 529 修复

- normalizer 以 `info.size.width/height`（encoded axes）调用
  `planOriginalImageDownscale()`；
- 由 downscale 结果和 EXIF 再计算 `targetOriented`；旋转/缩放后的实际 PixelMap
  必须匹配该目标；
- 重写输出的 bytes、encodedWidth/Height、orientedWidth/Height 全部描述无 EXIF
  WebP 的最终物理轴；
- persistence helper 与 `NoteCanvasView` 均以 orientedWidth/Height 作为 intrinsic。

## 渲染坐标桥接

原版 `g3` 返回 oriented bitmap，`b40` 使用 oriented `dp5.size` 解释 crop。Harmony 的
`ImageAssetLoader` 为保留平台差异仍可返回 raw encoded bitmap；`ImageCanvasRenderer` 以
raw 宽高生成 encoded→oriented `orientationTransform`，随后在 oriented intrinsic 域做
crop、用户翻转与 block fit。这样 caller、持久化校验和渲染使用同一 oriented 尺寸，而不
把 90°/270° 的 raw 轴误当作 block 轴。

## 验证

`d02-original-photo-oriented-dimensions.mjs` 固定原版 gate、encoded-axis sampling、
90°/270° 目标轴交换、照片 caller、persistence 传递链和 renderer bridge；专项结果
`D02_ORIGINAL_PHOTO_ORIENTED_DIMENSIONS_OK TOTAL=19 FAILED=0`。未启动模拟器、虚拟机、
真机或 Hypium；`T-042` 继续为 Goal 最后一项。

Phase 529 终验还通过 renderer/crop 增量专项（19/19）与全量 Desktop Replay
（`REPLAY_FILES=424 PASSED=424 FAILED_FILES=0`，32.013 秒）。clean、`note@ohosTest` 与
`note@default` 静态 HAP 均成功；这些结果只代表静态编译/打包，不替代真实设备像素验收。
