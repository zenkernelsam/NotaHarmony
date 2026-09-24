# ADR-0620 独立图片文件导入（cv5 图片分支 / dhj.S）

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：653
- 接续：ADR-0619（PDF 文件导入）、ADR-0507（拍摄图片入库）
- 证据：`docs/migration/evidence/original-image-file-import-jadx-2026-09-24.md`

## 背景

原版 Import File 的图片分支：`cv5` 选中图片后 `vuh.b(file, mime)`
解码编码尺寸并按 EXIF 换轴得本征尺寸（`ep5`），≤3000px 保留原字节
与解码 MIME；>3000px 经幂二次 `inSampleSize` + `createScaledBitmap`
等比缩放 + EXIF 旋转烘焙后重写为 `WEBP_LOSSY,85`，`ep5` 报告重写
产物的换轴尺寸。负载 `qu5(file, w, h, mime)` 经 `yq8.f` 路由到
`dhj.S`：在 `m09.b` 默认 Letter（612×792pt）页上经 `bvh.a`
（`min(1, min(0.8·页W/图W, 0.8·页H/图H))`，绝不放大）算适配尺寸，
`ip5` 居中偏移 + `scale = fitW/srcW`，`kp5` 产出
`CREATE_BLOCK(cz0.IMAGE, ty0.SQUARE, ive.PIXEL_ALIGN)`。

Harmony 此前 picker 仅 `.note`+`.pdf`（Phase 652），图片导入缺失；
但已具备 `planOriginalImageDownscale`/`originalImageOrientedDimensions`
（`vuh.b` 镜像）、`prepareLocalOriginalImageAsset`、
`imageBlockWorldBounds` 与 `commitOriginalImageInsert` 原语。

## 决定

1. **选择器**：`fileSuffixFilters` 扩为 `.note/.pdf/.png/.jpg/.jpeg/
   .webp/.gif/.heif/.heic/.tif/.tiff`；其余原版约 30 种类型
   fail-closed。
2. **分发**：`importFromFile` 读字节后先查 `%PDF-` magic 与 `.pdf`
   后缀 → PDF；`IMPORTED_IMAGE_SUFFIXES` 命中 →
   `importImageFromBytes`；其余 → `.note` ZIP。
3. **规范化**：`prepareImportedImageBytes` 复用既有
   `originalImageOrientedDimensions`/`planOriginalImageDownscale`
   镜像 `vuh.b`：≤3000 保留字节+解码 mime+换轴本征；>3000 统一
   采样因子 `factor = plan.width/encodedW` 作用于解码 PixelMap
   （无论 `createPixelMap` 是否已应用 EXIF，等比缩放都保持其域），
   `packToData(webp, q85)`，本征尺寸取缩放产物实际像素域 —— 对齐
   `ep5`「重写文件自身尺寸」语义。`ImageSource/PixelMap×2/ImagePacker`
   全部 `finally release()`；解码失败 `CORRUPTED` 零写库。
4. **几何**：`buildImportedImageElement` 逐步 `Math.fround` 复刻
   `bvh.a`/`ip5`：`fitMin = min(1, min(0.8·612/srcW, 0.8·792/srcH))`，
   `origin = (页 − 适配)/2`，`scale = fitW/srcW`，transform =
   `[s,0,x,0,s,y]`，`blockWidth/Height = intrinsicW/H`（ep5 尺寸），
   `corner/textWrap = 0`、`enableCaption = false`，bounds 经
   `imageBlockWorldBounds`。
5. **落库**：`importMutex` 内 `createNoteWithMeta`（无默认空白页）→
   `storeImportedOriginalAsset`（sha512 → assetHashBits）→
   `addImportedPage`（Letter 612×792pt→mm，PLAIN/PORTRAIT/
   `originalDefaultNoteBackground()`/bookmarked=false）→
   `saveElements`（单 IMAGE zIndex=0）；任一异常 →
   `removeFailedImport` 清理后 `CORRUPTED`。
6. **标题**：URI 尾段去最后一个后缀；空 stem 回退 `'导入笔记'`。

## 有意差异（fail-closed / 记录项）

- **EXIF 旋转烘焙（仅 >3000px 且 iL≠0 的图片）**：原版把旋转烘焙进
  WebP 像素；Harmony 不主动调 `pixelMap.rotate`，依赖解码器是否已
  应用 EXIF。若未应用，产物保持编码方向（像素方向最多差
  90/180/270），但 WebP 无 EXIF、本征尺寸取自产物实际域 ——
  数据自洽，仅显示方向可能与原版不同。该边界影响面窄且
  fail-closed 可接受；后续若确证 `createPixelMap` 不应用 EXIF，
  可补 `pixelMap.rotate` 完全对齐。
- `*/*` → 后缀白名单：picker 能力限制；Office/音视频等其余类型
  另立 Phase。
- 不使用编辑器插入的 320pt 显示上限：原版 `bvh.a` 的 `f5` cap 在
  导入路径为 `null`（320pt 上限属 `bgj` 编辑器插入路径），故导入
  仅按 0.8·页占比适配。

## 验证

- 专项 Replay `d05-original-image-file-import.mjs`：34 项全绿。
- 既有 `d02-note-import-file-handle-lifecycle.mjs`：7/7（边界未变）。
- 全量 Desktop Replay：见 Phase 653 报告记录的最终计数。
- `note@ohosTest` / `note@default` clean HAP 构建均成功
  （仅既有告警，无新增错误）。
- 未做模拟器/真机验证（按项目约束）。
