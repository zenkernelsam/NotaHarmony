# Phase 756 证据：代码块段基字号 `d − 24`（docPx，下限 1）

> 证据基线：`decompiled_1.0.3`（JADX 输出，`C:\Users\Cisco He\Desktop\Notability\` 只读）。
> 关联：ADR-0648（quote/code 块移植，本项登记"单位体系不同"）、ADR-0704。

## 1. 原版证据（lj3.java）

`defpackage/lj3.java:298-304` 与 `:853-859`（两处同型分支）：

```java
f2 = this.d;                          // = ti3.e 段基字号
if (fy2Var3 == fy2.CODE_BLOCK) {
    f3 = f2 - 24.0f;
    if (f3 < 1.0f) { f3 = 1.0f; }
} else { f3 = f2; }
// 随后 Math.abs((int)(qi3Var.c.c>>32) − f3 * f5) > 0.01f 对照 span 尺寸
```

## 2. 单位解析（修复 ADR-0648 的"单位体系不同"悬案）

- `lj3.c` = `mke.h` 传入的 `f` ← `ake.m` ← `x82.T(context)`
  = `densityDpi / di3.J`（x82.java:362-366）——**显示密度**。
- `di3` 是 docPx 值类（`di3.b` 返回 `"X.docPx"`，`J = m09.g` = 160 基准）。
- 故 `lj3.d`（=`ti3.e`，段基字号）以 **docPx** 计量；
  `f3 × f5`（docPx × density = 屏幕 px）对照 span 存储的 `qi3.c.c>>32`
  px 尺寸——自洽。
- Harmony `element.fontSize` 同为 docPx（页面 doc 域，实测 .note
  载荷 `fontSize:24`）。**单位同域，−24 直接可移植**——ADR-0648
  的"单位不同"判据证伪。

## 3. Harmony 修复（Canvas2DTextRenderer.ets）

- `applyCodeBlockFace(..., baseFontSize)`：CODE_BLOCK(5) 字符除
  `familyName='monospace'` 外，`fontSize === undefined` 时写入
  `max(base − 24, 1)`——段基收缩经字形样式数组贯通
  measure/layout/render/hit；段内显式 run 字号保留（span 自带尺寸
  不被段基收缩覆盖，对齐原版 span 尺寸对照语义）。
- 新增 `paragraphFontSize(element, paragraph)`：`decoratorStyle===5`
  → `max(element.fontSize − 24, 1)`，否则原值。
- 行度量全部改用段字号：4 处首行基线 init、行高/底带/推进
  （bandTop/lineHeight/baseline advance/覆盖高度共 6 处 `element.fontSize`
  直读点）。

## 4. 文件清单

- `note/src/main/ets/core/adaptation/Canvas2DTextRenderer.ets`
- `docs/migration/replays/d02-original-quote-code-blocks.mjs`（+5 钉）
- ADR-0648 差异表"lj3 −24f"行更新为已闭环。
