# ADR-0259：原版大图规范化的 Harmony Adapter

- 状态：Accepted（Phase 281，2026-08-22）
- 范围：超过原版 3000px 边界的本地图片字节 → 缩放 / EXIF rotation / WebP lossy 85 重编码 → Phase 280 持久化入口
- 相关：ADR-0258（原版图片插入原子持久化）

## 决策

新增 `planOriginalImageDownscale()` 与 `normalizeOriginalImageBytes()`。大图规范化先产出完整的重编码字节
快照，再交给既有 `commitOriginalImageInsert()`；持久层继续验证 header、MIME、EXIF、实际 PixelMap、3000px
边界并计算 SHA-512 AssetHash。

返回契约同时包含：

```text
bytes
mimeType
encodedWidth/encodedHeight
orientedWidth/orientedHeight
```

`normalizedOriginalImagePersistencePlan()` 只把 bytes、MIME 和 intrinsic dimensions 传给 persistence plan。
因此 fileSize、AssetHash、CREATE_BLOCK metadata 与 final asset file 都描述同一次重编码后的内容。

## 原版对齐

1. EXIF 3/4→180、5/8→270、6/7→90，其他或缺失为 0。
2. rotation 90/270 时对外宽高交换；但 Android sample size 循环仍使用 encoded 宽高。
3. oriented 任一轴超过 3000 才规范化。
4. ratio 是 Java float：Harmony 用 `Math.fround(3000 / max(encodedWidth, encodedHeight))` 复现。
5. 目标尺寸 half-up round 且最小 1；sample size 只按 power-of-two 增加，且两个 encoded 轴除后都不得小于目标。
6. 需要规范化时统一重编码为 WebP lossy quality 85，并把 MIME 改为 `image/webp`。

## Harmony 适配与失败语义

- Android `BitmapFactory + ExifInterface + Matrix + Bitmap.compress` 映射为 ImageKit 的
  `ImageSource.getImageInfo/getImageProperty(ORIENTATION)/createPixelMap` 和 `ImagePacker.packing`。
- `createPixelMap` 使用 `sampleSize`、`rotate`、`desiredSize` 与 `editable:true`；实际 decode 尺寸必须等于计划。
- 不预读或伪造 `supportedFormats`。WebP packing 失败时异常外抛，由 caller fail closed。
- 输入先复制 stable snapshot；成功且未规范化时返回独立输入副本，需要规范化时返回 packing 新副本。
- `PixelMap`、`ImageSource` 与 `ImagePacker` 在异步路径中释放；主异常不被清理异常覆盖。

## 文件名与资产身份

canonical 资产身份是 SHA-512 内容 hash，不是原始文件名。重编码产生新 bytes 后会自然获得新 AssetHash；
caller 提供的稳定文件名继续进入 metadata。禁止在 normalization 后保留旧 MIME 或旧长度来“保持文件名兼容”。

## 明确未闭环

- URI/FD/Pasteboard/系统相册 caller、权限、100 MiB ingress 与产品 UI 未接线；
- 真实设备 decode/EXIF/WebP encoder 兼容性、色彩、透明度、内存和性能未验收；
- 小尺寸带 EXIF 图片的 renderer 显示方向仍开放；
- Undo/Redo、重启、导入导出/同步与端到端体验仍需设备验证；
- `T-042` 继续严格留到整个 Goal 最后一项。