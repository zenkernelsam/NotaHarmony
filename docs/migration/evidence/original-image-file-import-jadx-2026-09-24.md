# 原版独立图片文件导入 — JADX 证据（2026-09-24）

范围：`decompiled_1.0.3` 下「Import File → 图片」链路的静态证据，
支撑 Phase 653。与 Phase 652（PDF 分支）共用 `i58.c = */*` 选择器
与 `jv5` 类型嗅探入口。

## 选择器与路由

- `i58.java:6`：`new i58("*/*")` —— 选择器接受任意类型，导入后按
  MIME/内容分发。
- `yq8.java:30-34`：负载路由 —— `uu5Var instanceof qu5 → dhj.S`（图片），
  `su5 → PDF`（Phase 652），`pu5 → 音频`，`tu5 → dhj.p0`。
- `qu5.java`：`File K`（临时文件）+ `float L`（本征宽）+ `float M`
  （本征高）+ `String N`（MIME）；`a()` 负责删除临时文件。

## cv5 → vuh.b：解码与规范化

`vuh.java`（约 50–140 行，`vuh.b(file, mime)`）：

```java
// 编码尺寸
int i2 = options.outWidth;  int i = options.outHeight;
if (i2 <= 0 || i <= 0) { file.delete(); return null; }          // 失败即清理
// EXIF 方向（w34.l() 返回 0/90/180/270 度）换轴
int iL = w34Var != null ? w34Var.l() : 0;
boolean z = iL == 90 || iL == 270;
int i3 = z ? i : i2;   int i4 = z ? i2 : i;
ep5 ep5Var = new ep5(i3, i4, str);      // 本征尺寸 = 换轴后
if (i3 <= 3000 && i4 <= 3000) return ep5Var;   // ≤3000 保留原字节+mime
// >3000：目标尺寸 = 编码尺寸 × (3000/max)，幂二次采样 + 等比缩放
float fMax = 3000.0f / Math.max(i2, i);
int i5 = max(1, round(i2*fMax));  int i6 = max(1, round(i*fMax));
options2.inSampleSize = 最大2的幂（i2/(2s)≥i5 且 i/(2s)≥i6）;
bitmapDecodeFile = BitmapFactory.decodeFile(file, options2);
scaled = Bitmap.createScaledBitmap(decoded, i5, i6, true);
if (iL != 0) scaled = Bitmap.createBitmap(scaled, 0,0,i5,i6, rotate(iL)); // 烘焙旋转
scaled.compress(WEBP_LOSSY, 85, fos);    // 重写为有损 WebP q85
// 返回值：重写后的（换轴）尺寸 + "image/webp"
return new ep5(z ? i6 : i5, z ? i5 : i6, "image/webp");
```

- ≤3000 路径：保留原始编码字节与解码 MIME，本征尺寸按 EXIF 换轴。
- >3000 路径：inSampleSize（2 的幂）先采样、`createScaledBitmap` 精确
  缩到 `(i5,i6)`、EXIF 旋转烘焙进像素、`WEBP_LOSSY,85` 重写文件；
  返回的 `ep5` 是**重写产物**的换轴尺寸 + `image/webp`。

## dhj.S → bvh.a → ip5 → kp5：几何与落页

`dhj.java`（约 692–702 行）：

```java
qed qedVar = m09.b;                 // 默认页尺寸寄存器 = a79.N = 612×792pt
float fD = 页宽pt, fC = 页高pt;
if (尺寸缺失) ip5Var = new ip5(fD/2f, fC/2f, 1.0f);          // 兜底居中
else {
  lp5 lp5VarA = bvh.a(f, f2, Float.valueOf(fD), Float.valueOf(fC), null);
  float f3 = lp5VarA.a;              // 适配宽
  ip5Var = new ip5((fD - f3)/2f, (fC - lp5VarA.b)/2f, f3/f); // 居中+等比
}
kp5Var = new kp5(ip5Var, qu5Var, dp5Var);
```

`bvh.java` `a(f, f2, f3, f4, f5)`（f=图宽 f2=图高 f3=页宽 f4=页高 f5=null）：

```java
fFloatValue  = f3 != null ? f3 * 0.8f : Float.MAX_VALUE;
fFloatValue2 = f4 != null ? f4 * 0.8f : Float.MAX_VALUE;
fFloatValue3 = f5 != null ? f5 : Float.MAX_VALUE;
fMin = min(1.0f, min(min(fFloatValue,  fFloatValue3)/f,
                      min(fFloatValue2, fFloatValue3)/f2));
return new lp5(f*fMin, f2*fMin);       // 适配尺寸，绝不放大
```

`kp5.java`：`cz0.IMAGE` + `ty0.SQUARE` + `ive.PIXEL_ALIGN`，
CREATE_BLOCK 操作，block 尺寸 = `qu5.L/M` 本征尺寸，
transform = `[s, 0, x, 0, s, y]`（s = fitW/srcW，x/y = 居中偏移）。

## Harmony 适配决策

1. **选择器**：`fileSuffixFilters` 扩为
   `['.note', '.pdf', '.png', '.jpg', '.jpeg', '.webp', '.gif',
   '.heif', '.heic', '.tif', '.tiff']`；其余原版类型 fail-closed。
2. **分发**：`.pdf` magic/后缀 → PDF；`IMPORTED_IMAGE_SUFFIXES` 后缀 →
   `importImageFromBytes`；其余回退 `.note` ZIP 路径。
3. **规范化**：`prepareImportedImageBytes` =
   `createImageSource.getImageInfo`（编码尺寸+mime）→
   `ORIENTATION` 属性 → `originalImageOrientedDimensions` 换轴；
   ≤3000 保留字节+mime；>3000 走 `planOriginalImageDownscale`
   （既有 `vuh.b` 镜像：inSampleSize 幂二 + 等比目标）→
   `createScaledPixelMap(factor, factor)` → `packToData(webp, q85)`，
   本征尺寸取缩放产物实际像素域（对齐 `ep5`「重写文件自身尺寸」）。
4. **几何**：`buildImportedImageElement` 逐步 `Math.fround` 复刻
   `bvh.a`/`ip5`：`fitMin = min(1, min(0.8·612/w, 0.8·792/h))`，
   `origin = (页-适配)/2`，`scale = fitW/srcW`，transform 六分量同构。
5. **落库**：`importMutex` 内 `createNoteWithMeta` →
   `storeImportedOriginalAsset`（sha512→assetHashBits，
   mime=保留/重写 mime）→ `addImportedPage`（Letter 612×792pt→mm，
   PLAIN/PORTRAIT/`originalDefaultNoteBackground()`/bookmarked=false）
   → `saveElements`（单 IMAGE 元素 zIndex=0）；异常 →
   `removeFailedImport`。
6. **资源生命周期**：ImageSource/PixelMap×2/ImagePacker 全部在
   `finally` 中 `release()`；解码失败返回 `CORRUPTED`，零写库。

## 已知差异（fail-closed / 记录项）

- **EXIF 烘焙差异（仅 >3000 且 iL≠0）**：原版把旋转烘焙进 WebP 像素；
  Harmony 依赖 `createPixelMap` 是否自动应用 EXIF。若未应用，WebP
  产物保持编码方向 —— 但 WebP 容器无 EXIF，本征尺寸取自产物实际
  像素域，与 `ep5`「重写文件自身尺寸」语义自洽（像素方向可能与
  原版差 90/180/270 度，≤3000 路径无此问题）。
- **图片页尺寸**：原版 `m09.b` 默认页 = Letter 612×792pt；Harmony 用
  `IMAGE_IMPORT_PAGE_*_PT` 常量 + `POINTS_TO_MM` 落 mm。
- **选择器**：Harmony 无法 `*/*`；其余原版约 30 种类型中 Office/
  音视频等仍 fail-closed（音频为下一候选 Phase）。
