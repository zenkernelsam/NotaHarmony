# Phase 891 证据 — `mmf` = UInt 值类 + `xw9` 布局枚举

## 目的

实名两个贯穿全图的值类：`mmf`（页数/尺寸包装）与
`xw9`（PDF 布局行为枚举）。`decompiled_1.0.3`。

## `mmf` = Kotlin UInt 内联值类

```java
public final class mmf implements Comparable {
    public final int I;                     // 原始位
    public static String a(int i) {
        return String.valueOf(((long) i) & 4294967295L);  // 无符号格式化
    }
    compareTo: ba6.w(this.I ^ 0x80000000, o.I ^ 0x80000000)  // 无符号比较
}
```

- `a(i)` = `i & 0xFFFFFFFF` 无符号打印；`compareTo` =
  `XOR MIN_VALUE` 标准无符号比较——**Kotlin `UInt`**
  （混淆名）。所有 `mmf.a(...)` 包装点 = UInt32 语义：
  - `ln2.pageCount`（885/867）
  - `sw9.totalPageCount/pagesConsumed/pageOffset`（889）
  - `wa0.fileSize`（890）
- 推论：页数/文件尺寸在线上为 **无符号 32 位**；
  Harmony `number` 侧须按无符号解释（负 int 位 = 大正数）。

## `xw9` = PDF 布局行为 byte 枚举（三值实证）

```java
DOWNSCALING_AND_MAX_BOX  = (byte) 0
DOWNSCALING_AND_CROP_BOX = (byte) 1
FIT_AND_CROP_BOX         = (byte) 2   // j7j.c 默认值
```

- `xw9.L = nz3` = Kotlin EnumEntries。
- 语义：PDF 页面在背景上的三种铺放——按媒体框降采样
  留白(0)/按裁切框降采样裁切(1)/拉伸适配裁切框(2)。
- `j7j.c` `c(1,b,2)` 默认 2 = **FIT_AND_CROP_BOX**。

## Harmony 侧

- `PdfBackgroundLoader`/背景编码的 PDF 适配模式枚举 ↔
  三值逐值对应（868 已对齐三值；现值名实名）。
- 页数/尺寸字段的 UInt32 语义与 Harmony number 无符号
  读取一致（无符号位不会触发为负）。

## 结论

`mmf`=UInt 值类实名（无符号语义钉死）；`xw9` 三值实名
+默认 FIT_AND_CROP_BOX。纸面/PDF 子图全部叶子实名完毕。
纯文档+fixture 阶段。
