# Harmony 证据：原版小图 EXIF 归一化边界

日期：2026-08-29

## 原版来源

只读来源：

`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3\sources\defpackage\vuh.java`

关键事实：

- `vuh.java:64-68` 先读取 EXIF rotation 并计算 oriented 宽高；
- `vuh.java:69-71` 在 `i3 <= 3000 && i4 <= 3000` 时立即 `return ep5Var`；
- `vuh.java:77-86` 之后才创建 downscale decode options；
- `vuh.java:113-137` 仅大图路径执行缩放、rotation 和 WebP lossy 85 重编码。

因此 `rotationDegrees != 0` 不能单独触发字节重写。

## Harmony 复审

复审前的条件为：

```text
plan.width !== oriented.width || plan.height !== oriented.height ||
rotationDegrees !== 0
```

这会错误地把 3000×2000、EXIF 6 的输入送入 PixelMap 与 WebP 路径。

Phase 528 改为：

```text
const needsNormalization: boolean = !isOriginalNormalizedImageDimensions(
  oriented.width, oriented.height);
```

stable-byte 返回位于 `createPixelMap()` 之前，并保留 `rewroteBytes: false`、源
MIME、encoded/oriented dimensions；只有 oriented 轴越过 3000px 才进入旋转、缩放
和 WebP packing。

## 方向与镜像边界

小图的 EXIF 方向仍由显示链读取和应用，归一化不提前烘焙方向；这与原版
`vuh.b()` 的立即返回及 Phase 446 的 rotate-only 大图裁决一致。该阶段不把显示端
的镜像修复扩展到持久化字节。

## Replay / fixture

- `d02-original-small-exif-byte-preservation.mjs` 锁定原版 gate → immediate return
  → decode 顺序、Harmony stable return → decode 顺序，以及 3–8 方向的小图/越界矩阵；
- `OriginalImageNormalizer.test.ets` 覆盖 3000×2000 + EXIF 6 保留原始路径和
  3001×2000 + EXIF 6 进入规范化边界；
- `d02-original-large-image-normalization.mjs` 和
  `d02-original-normalization-mirror-parity.mjs` 同步禁止 rotation-only 重写回归。

## 终验结果

- 小图 EXIF 专项：`D02_ORIGINAL_SMALL_EXIF_BYTE_PRESERVATION_OK TOTAL=12 FAILED=0`；
- 大图规范化：`TOTAL=19 FAILED=0`；镜像一致性：`TOTAL=13 FAILED=0`；
  四分之一旋转顺序：`TOTAL=9 FAILED=0`；
- 全量 Desktop Replay：`REPLAY_FILES=423 PASSED=423 FAILED_FILES=0`（37.752 秒）；
- ArkTS 目标无新增错误，仅既有 `ImagePacker.packing` 弃用信息；clean、ohosTest 与
  default 静态 HAP 均 `BUILD SUCCESSFUL`。

静态 Replay 不能替代真实设备的 EXIF 像素和 WebP 编码验收；未启动模拟器、虚拟机、
真机或 Hypium，`T-042` 继续为 Goal 最后一项。
