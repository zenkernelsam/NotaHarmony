# 修复总结：Phase 281 原版大图规范化 Adapter

## 1. 阶段范围与纪律

- 唯一修改工程：`C:\HarmonyProject\NotaHarmony`；Desktop Notability 仅读取原版反编译证据。
- 全程未启动模拟器、虚拟机、真机或 Hypium。
- 本阶段闭环 Phase 280 明确开放的原版大图规范化底层 adapter；不宣称 URI/FD/Pasteboard/相册产品入口上线。
- `T-042` APK 版本追踪继续严格留到整个 Goal 最后一项。

## 2. 原版证据结论

直读 `vuh.java:44-137` 与 `w34.java:978-991` 后确认：

1. 先读取 encoded header 与 EXIF orientation；EXIF 90/270 度交换对外宽高。
2. oriented 任一轴超过 3000px 时，按 `3000.0f / max(encodedWidth, encodedHeight)` 计算目标尺寸。
3. 使用 power-of-two `inSampleSize`、实际 decode、scaled bitmap 与显式 EXIF rotation。
4. 重编码为 `Bitmap.CompressFormat.WEBP_LOSSY, 85`，返回新尺寸和 `image/webp`。
5. 解码失败或目标尺寸无效时原版 fail closed，不会只改 metadata。

哈希与片段见
`docs/migration/evidence/original-image-normalization-jadx-2026-08-22.md`。

## 3. Harmony Adapter

### 3.1 纯数学计划

`OriginalImageInsertPlan.ets` 新增 `planOriginalImageDownscale()`：

- 只接受正的安全整数；
- `3000px` 以内返回 `sampleSize=1` 且不改尺寸；
- 用 `Math.fround()` 复现 Java float ratio；
- 目标宽高使用 half-up round 并最小为 1；
- 按 Android 循环选择 power-of-two sample size。

### 3.2 字节规范化边界

新增 `OriginalImageNormalizer.ets`：

- 输入复制为 stable snapshot；
- ImageKit 读取 header MIME/尺寸和 EXIF orientation；
- `originalImageOrientedDimensions()` 判定交换轴，`originalRotationDegrees()` 映射 3/4→180、5/8→270、6/7→90；
- 需要缩放或旋转时用 `createPixelMap({ sampleSize, rotate, desiredSize, editable:true })`；
- 实际 decode 尺寸必须等于计划尺寸；
- `ImagePacker.packing(..., image/webp, quality:85)` 成功后整体返回新 bytes、MIME、encoded/oriented dimensions；
- 不支持 WebP 或任一步失败时异常 fail-closed；
- `PixelMap`、`ImageSource` 和 `ImagePacker` 在异步路径中释放。

### 3.3 持久化接线

`StrokePersistence.ets` 新增 `normalizedOriginalImagePersistencePlan()`。caller 可在构造
`OriginalImageInsertPersistencePlan` 前调用它，再把返回的 bytes/MIME/intrinsic dimensions 一并传入既有
`commitOriginalImageInsert()`。这样 SHA-512 AssetHash、fileSize、CREATE_BLOCK metadata 和本地资产文件都来自
重编码后的同一字节快照，不存在“只改元数据”的路径。Phase 280 的 asset → editor mutex、pending fsync/
atomic rename、单 SQLite transaction 与 rollback 边界不变。

文件名继续由 caller 稳定提供；资产存储 key 是 canonical content hash，因此重编码后的新内容自然获得新
AssetHash。后续 caller 层如需展示原始文件名，可在 UI 层处理，不得反向把旧 MIME/长度写进 CREATE_BLOCK。

## 4. Fixture、Replay 与文档

- ArkTS：新增 `OriginalImageNormalizer.test.ets`，覆盖 3000px 边界、Float32/sample-size 数学、EXIF 轴交换、
  无效尺寸拒绝，并注册到 `List.test.ets`。
- Replay：`docs/migration/replays/d02-original-large-image-normalization.mjs` 同时断言原版片段、Harmony
  关键链路、fixture 注册和六组数值 fixture。
- ADR：`docs/migration/adr/ADR-0259-original-image-normalization.md`。
- Evidence：`docs/migration/evidence/original-image-normalization-jadx-2026-08-22.md`。
- 已更新两份修复总纲与总进展。

## 5. 验证结果

| 门禁 | 结果 |
|---|---|
| Phase 281 专项 Replay | `D02_ORIGINAL_LARGE_IMAGE_NORMALIZATION_OK TOTAL=18 FAILED=0` |
| 全量 Desktop Replay | `REPLAY_FILES=266 FAILED=0` |
| `git diff --check` | 通过（仅 CRLF 提示） |
| clean | `BUILD SUCCESSFUL in 2 s 50 ms` |
| clean 后 `note@ohosTest` | `BUILD SUCCESSFUL in 8 s 82 ms` |
| 同一次 clean 后 `note@default` | 首次暴露 ArkTS 错误并修复；最终重跑 `BUILD SUCCESSFUL in 48 s 506 ms` |

构建只有项目既有 warning（函数可能抛出、deprecated API）与 unsigned signing 提示，没有 Phase 281 编译错误。

## 6. 明确未完成边界

本阶段仍不宣称“任意图片可直接插入”。以下继续开放：

- URI/FD/Pasteboard/系统相册 caller、权限、100 MiB ingress 和产品 UI 接线；
- 真实设备上的 JPEG/PNG/WebP/HEIF decode、EXIF 属性兼容性、WebP encoder 支持矩阵、色彩/透明度与压缩质量验收；
- Undo/Redo、保存重启、导入导出/同步、内存峰值与大图交互性能；
- 小尺寸带 EXIF 图片的 renderer 显示方向仍需设备验证；
- 真实设备端到端体验与 crash/failure injection 验收。

静态 Replay、ArkTS 编译和 unsigned HAP 打包不能代替上述设备与端到端验证。