# ADR-0501：原版照片入口使用 oriented intrinsic 尺寸

日期：2026-08-29

## 状态

Accepted

## 背景

原版 `vuh.b()` 读取 encoded header 后，先按 EXIF rotation 计算对外的 oriented
宽高，再把该尺寸放进 `ep5`。`bgj` 随后用 `ep5` 的宽高创建 IMAGE block 的尺寸
与 fit 几何。Harmony 的照片 ingress 已同时返回 encoded/oriented 两套尺寸，但
`NoteCanvasView` 曾把 encoded 轴直接写进 persistence plan；90°/270° 小图因此
会产生错误 intrinsic 尺寸，且与 `ImageAssetPackageStore` 的 oriented 校验冲突。

## 决策

1. `OriginalPhotoIngressItem` 继续保留 encoded 与 oriented 两套轴，便于证据和
   解码校验区分物理字节与显示尺寸；
2. 从照片 ingress 转换为 `OriginalImageInsertPersistencePlan` 时，统一使用
   `orientedWidth/orientedHeight` 作为 IMAGE intrinsic 与 CREATE_BLOCK size；
3. `normalizeOriginalImageBytes()` 的 planner 严格使用原始 encoded 轴计算采样，
   旋转后把目标尺寸转换为 oriented 轴；重写后的 WebP 无 EXIF，两个输出轴即为
   其物理 encoded/oriented 尺寸；
4. 剪贴板输入本身已是无 EXIF 的 normalized WebP，继续使用同一轴契约。

## 原版依据

- `vuh.java:64-70`：90°/270° 先交换 `ep5` 对外宽高，并在不超过 3000px 时
  直接返回；
- `vuh.java:72-86`：采样 ratio 与 `inSampleSize` 仍按 encoded `i2/i`；
- `vuh.java:113-137`：大图旋转后的 WebP 返回交换后的物理宽高；
- `bgj.java:113-131`：使用返回的图片属性计算 block fit 与 transform。

## 结果

EXIF 90°/270° 的小图不再把宽高写反；大图采样、旋转、WebP 结果和持久化
校验共享同一最终 oriented intrinsic 契约。新增尺寸专项 Replay 与 fixture，
并同步修正旧 Replay 对 encoded/oriented 轴的断言。

## 未闭环

- 真实设备 EXIF、色彩、WebP/HEIF 编码和像素视觉仍需设备验收；
- oriented-crop 编辑完整矩阵仍开放；
- `T-042` 继续严格留到整个 Goal 最后一项。
