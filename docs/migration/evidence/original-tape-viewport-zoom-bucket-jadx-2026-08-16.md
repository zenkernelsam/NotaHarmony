# 原版 Tape pattern viewport zoom 分桶：JADX 证据

## 来源

- APK：`C:\Users\Cisco He\Desktop\Notability\Notability_1.0.3\com.gingerlabs.notability.apk`
- SHA-256：`3C616F6ED15B4DA14108A66B67A480BBA5789916A901FCDF7DE5192FA55B674B`
- 反编译目录：`C:\Users\Cisco He\Desktop\Notability\decompiled_1.0.3`
- 日期：2026-08-16

本证据复核 Phase 155 当时暂缓的 Tape pattern bitmap 分辨率语义。结论来自原版
`defpackage/qfe.java`、`mfe.java`、`c5g.java`，不把 Tape 笔宽或显示 Density 猜作参数。

## `c5g`：传给 `qfe` 的参数就是 viewport zoom

`c5g.java:275-281`：

```java
qfe qfeVar = this.m;
Function0 function0 = this.c;
if (function0 == null) {
    ba6.d0("zoom");
    throw null;
}
qfeVar.a(canvas, path, ifeVar, i, i2,
    ((Number) function0.invoke()).floatValue(), f, f2);
```

这里的 `Function0 c` 缺失时明确报 `zoom`。因此 `qfe.a()` 的第六个参数 `f` 是 viewport zoom，
不是 `brushWidth`，也没有再乘 Density。

## `qfe`：半档 bucket 与完整缓存身份

`qfe.java:60-63`：

```java
int iY0 = m18.y0(rh8.u(f, 1.0f, 8.0f) * 2.0f);
mfe mfeVar2 = new mfe(
    ifeVar,
    i2,
    ifeVar == ife.FLOWERS ? i : 0,
    iY0);
Bitmap bitmap2 = (Bitmap) this.f.c(mfeVar2);
```

`m18.y0(float)` 是 `Math.round(float)`，`rh8.u(value,min,max)` 是闭区间 clamp。因此原版键中的
整数 bucket 为：

```text
round(clamp(viewportZoom, 1, 8) × 2)
```

实际 raster scale 是 `bucket / 2`，范围 1×～8×、步长 0.5×。

`mfe.java:34` 进一步给出键的四个字段：

```java
PatternCellKey(pattern=..., overlayColor=..., tapeColor=..., scaleBucket=...)
```

其中只有 `FLOWERS` 把 Tape 本色加入键；其他 pattern 的 `tapeColor` 固定为 0。

## `qfe`：bucket 只改变 cell 像素密度

`qfe.java:120-126`：

```java
float f10 = iY0 / 2.0f;
int iMax = Math.max(1, m18.y0(f8 * f10));
int iMax2 = Math.max(1, m18.y0(f10 * f9));
Bitmap bitmapCreateBitmap = Bitmap.createBitmap(
    iMax, iMax2, Bitmap.Config.ARGB_8888);
Canvas canvas2 = new Canvas(bitmapCreateBitmap);
canvas2.scale(iMax / f8, iMax2 / f9);
```

`qfe.java:551-561` 随后把 bitmap 映射回固定逻辑 cell 尺寸：

```java
BitmapShader bitmapShader = new BitmapShader(bitmap2, REPEAT, REPEAT);
matrix.setScale(f6 / bitmap2.getWidth(), f7 / bitmap2.getHeight());
bitmapShader.setLocalMatrix(matrix);
canvas.drawPath(path, paint2);
```

所以 zoom bucket 改变的是 bitmap 像素尺寸与采样质量；页面坐标中的 pattern 重复周期仍是原版每种
pattern 的固定逻辑宽高。Phase 155 ADR 中“逻辑重复周期也随 bucket 变化”的表述据此更正。

## Harmony 对应原则

- 主画布、当前笔迹、完成层重建和局部擦除有序重绘使用同一 `viewport.zoom`。
- 缩略图没有交互 viewport，使用 page-to-output `pageTransform.scale` 作为等价输出倍率。
- cache key 必须同时包含 pattern、overlayColor、FLOWERS 专用 tapeColor 和整数 scaleBucket。
- 生成 bitmap 时按 Float32 乘法与正数 `Math.round` 还原原版边界；异常或非正平台输入安全回退 1×。
- 逻辑 tile 宽高保持不变，不能把 bitmap 像素宽高直接当作页面重复周期。
