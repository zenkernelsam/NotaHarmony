# Phase 894 证据 — `ka4` 校验契约 + `ddg` 校验链

## 目的

实名 `ka4` 校验接口语义与页面/资产校验规则全集。
`decompiled_1.0.3`。

## `ka4` = 校验接口

```java
public interface ka4 { String a(); }
```

契约：**null = 合法，非 null = 错误消息**（857 的
`ybg.c` 驱动：非 null → MODEL 日志 + ValidationException）。

## `ln2.a()` CreatePage 校验（实证）

1. `m()==0` → `"Cannot create 0 pages"`。
2. `nz9!=null` → `ddg.g(nz9)` 背景级联。
3. `nz9.l()`（sw9 PDF）非 null：
   `m() != sw9.o()` → `"Number of pages created must match
   the number of consumed pages in the PDF"`；
   匹配则 → `ddg.f(sw9)`。

## `ddg.f(sw9)` PDFAsset 校验（实证）

1. `p()==0` → `"Page count must be greater than 0,
   totalPageCount: N"`。
2. `o()==0` → `"Must consume more than 0 pages,
   pagesConsumed: N"`。
3. `o() != k()` → `"Must specify a crop box size for each
   page consumed"`（**cropBoxes 数 = pagesConsumed**）。
4. `o()+n() > p()`（无符号）→ `"Cannot consume pages
   beyond the total page count of the PDF"`。
5. 每个 cropBox → `ddg.k(qed,"Crop box")`。
6. 尾 → `sw9.m().a()` 级联 wa0。

## `wa0.a()` AssetMetadata 校验（实证）

1. `l() <= 0`（无符号）→ `"Asset file size must be larger than 0"`。
2. `m().isEmpty()` → `"Asset mime type must not be empty"`。
3. `k().isEmpty()` → `"Asset file name must not be empty"`。

## `ddg.g(nz9)` 背景校验（实证）

1. `l()!=null && n()==null` → `"PDF pages require an
   explicitly specified size to prevent fallback to the
   default note size"`。
2. `vy7` 边距：`vy7.a()` 级联 + `e()+d() > qed.d()` 或
   `c()+f() > qed.c()` → `"Cannot create margins larger
   than the page size"`。
3. 旋转基向：`m() ∉ {0, π/2, π, 3π/2}` → `"Cannot rotate
   to non cardinal directions, value: X"`。
4. `qed` → `ddg.i(qed)`；`sw9` → `ddg.f`；`k3a` →
   `k3a.a()` 级联。

## Harmony 侧

Harmony 编码侧 throw 门（857）+ 页面/PDF 创建检查 ↔
此规则集；PDF 页数/裁切框一致性、边距、基向旋转、
资产三字段非空 = 逐条可对齐。

## 结论

ka4 契约（null=合法）+ 页面/PDF/资产校验规则全链实名；
857 错误串清单获得精确归属。纯文档+fixture 阶段。
