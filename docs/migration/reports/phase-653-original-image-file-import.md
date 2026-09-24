# Phase 653：独立图片文件导入（cv5 图片分支 / dhj.S）

日期：2026-09-24
接续：Phase 652（独立 PDF 文件导入）
ADR：ADR-0620
证据：`docs/migration/evidence/original-image-file-import-jadx-2026-09-24.md`
专项 Replay：`docs/migration/replays/d05-original-image-file-import.mjs`（34 项）

## 原版行为（硬证据）

- `i58.java:6`：选择器 `i58.c = new i58("*/*")` —— 任意类型进入后
  `jv5`/`yq8.f` 按 MIME 与负载类型路由。
- `vuh.java` `b(file, mime)`：
  - 读编码尺寸；`w34.l()` 取 EXIF 旋转（90/270 换轴）→ `ep5{本征W,H,mime}`。
  - 换轴尺寸均 ≤3000 → 保留原编码字节与 MIME。
  - >3000 → `fMax=3000/max(编码W,H)`，目标 `(i5,i6)=round(编码×fMax)`，
    `inSampleSize`=最大 2 的幂，`createScaledBitmap(decoded,i5,i6)`，
    `iL≠0` 时 `Matrix.postRotate` 烘焙旋转，`compress(WEBP_LOSSY,85)`
    重写文件；返回 `ep5(重写产物换轴尺寸, "image/webp")`。
  - 解码失败 → `file.delete()` + `null`。
- `qu5.java`：`File K` + `float L/M`（本征宽高）+ `String N`（MIME）；
  `a()` 删临时文件。
- `yq8.java:30-34`：`uu5 instanceof qu5 → dhj.S`（图片分支）。
- `dhj.java`（约 692–702）：`m09.b` 默认页寄存器（= `a79.N` =
  `apb.h(612f,792f)` Letter）；`bvh.a(图W,图H,页W,页H,null)` 得适配
  尺寸 → `ip5((页W−fitW)/2,(页H−fitH)/2, fitW/图W)` 居中+等比 →
  `kp5(ip5, qu5, dp5)`。
- `bvh.java` `a(f,f2,f3,f4,f5)`：`fMin = min(1, min(0.8·f3,f5)/f,
  min(0.8·f4,f5)/f2)`；导入路径 `f5=null`（无 320pt cap）→ 仅
  0.8·页占比适配，绝不放大。
- `kp5.java`：`cz0.IMAGE` + `ty0.SQUARE` + `ive.PIXEL_ALIGN`，
  CREATE_BLOCK，block 尺寸 = `qu5.L/M`，transform=[s,0,x,0,s,y]。

## Harmony 实现（`NoteImporter`）

1. **选择器**：`fileSuffixFilters` 扩为 `.note/.pdf/.png/.jpg/.jpeg/
   .webp/.gif/.heif/.heic/.tif/.tiff`；库 FAB 与空笔记行自动获得
   图片导入。
2. **分发**：`%PDF-` magic / `.pdf` → PDF；`IMPORTED_IMAGE_SUFFIXES`
   → `importImageFromBytes`；其余 → `.note` ZIP。
3. **规范化（`prepareImportedImageBytes`）**：
   - `createImageSource.getImageInfo` 读编码尺寸+mime，
     `ORIENTATION` 属性 + `originalImageOrientedDimensions` 换轴。
   - ≤3000：保留原字节 + 解码 mime + 换轴本征。
   - >3000：`planOriginalImageDownscale`（既有 `vuh.b` 镜像）→
     统一因子 `plan.width/encodedW` 等比 `createScaledPixelMap` →
     `packToData(webp, q85)`；本征 = 缩放产物实际像素域（对齐
     `ep5`「重写文件自身尺寸」）。
   - `ImageSource/PixelMap×2/ImagePacker` 全 `finally release()`；
     解码失败 `CORRUPTED` 零写库。
4. **几何（`buildImportedImageElement`）**：逐步 `Math.fround` 复刻
   `bvh.a`/`ip5`：`fitMin=min(1,min(0.8·612/srcW,0.8·792/srcH))`、
   `origin=(页−适配)/2`、`scale=fitW/srcW`、transform=[s,0,x,0,s,y]；
   `blockWidth/Height=intrinsicW/H`（ep5 尺寸）、`corner/textWrap=0`、
   `enableCaption=false`，bounds 经 `imageBlockWorldBounds`。
5. **落库**：`importMutex` 内 `createNoteWithMeta` →
   `storeImportedOriginalAsset`（sha512→assetHashBits）→
   `addImportedPage`（Letter 612×792pt→mm，PLAIN/PORTRAIT/
   `originalDefaultNoteBackground()`/bookmarked=false）→
   `saveElements`（单 IMAGE zIndex=0）；异常 → `removeFailedImport`
   清理后 `CORRUPTED`。
6. **标题**：URI 尾段去最后一个后缀；空 stem 回退 `'导入笔记'`。

## 有意差异（fail-closed / 记录项）

- **EXIF 烘焙（仅 >3000px 且 iL≠0）**：原版把旋转烘进 WebP 像素；
  Harmony 依赖 `createPixelMap` 是否已应用 EXIF，未应用则产物保持
  编码方向（≤270° 差），但 WebP 无 EXIF、本征取自产物域 —— 数据
  自洽；后续若确证可补 `pixelMap.rotate` 完全对齐（ADR-0620）。
- `*/*` → 后缀白名单；Office/音视频等其余原版类型另立 Phase。
- 不用编辑器插入的 320pt cap：`bvh.a` 的 `f5` 在导入路径为 null，
  该上限属 `bgj` 编辑器插入路径。

## 验证

- 专项 Replay：34/34 全绿（原版证据 token + 实现对齐断言）。
- 既有回归：`d02-note-import-file-handle-lifecycle` 7/7；
  `d02-local-create-page-outbound`/`d05-original-pdf-file-import`
  两处旧 pin 更新后全绿。
- 全量 Desktop Replay：537/537 → 538/538（新增本 fixture）。
- ArkTS：`note@default` 构建成功，无新增错误（仅既有告警）。
- `note@ohosTest`/`note@default` clean HAP 构建均成功。
- 未做模拟器/真机验证（按项目约束）。

## 文件清单

- `note/src/main/ets/data/NoteImporter.ets`（+导入/常量/分发/
  `importImageFromBytes`/`prepareImportedImageBytes`/
  `buildImportedImageElement` 等 4 个私有 helper）
- `docs/migration/replays/d05-original-image-file-import.mjs`（新增）
- `docs/migration/replays/d02-local-create-page-outbound.mjs`（pin 更新）
- `docs/migration/replays/d05-original-pdf-file-import.mjs`（pin 更新）
- `docs/migration/evidence/original-image-file-import-jadx-2026-09-24.md`
- `docs/migration/adr/ADR-0620-original-image-file-import.md`
- `docs/migration/reports/phase-653-original-image-file-import.md`
- 三份跟踪文档
