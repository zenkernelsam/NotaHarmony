# ADR-0704：代码块段基字号 d−24 docPx 收缩（纠正 ADR-0648 登记）

- 状态：Accepted
- 日期：2026-09-25
- 关联：ADR-0648（quote/code 块；其中"单位体系不同"判据被本 ADR 纠正）、
  `phase-756-code-block-font-shrink.md`

## 背景

ADR-0648 将 `lj3` 的 CODE_BLOCK 字号收缩（`d − 24.0f`，下限 1.0f）
登记为"单位体系不同、视觉已可辨"的近似项。Phase 756 复核完成单位链：

- `lj3.c` ← `cu9.c` ← `mke` ctor `f` ← `ake.m = x82.T(context)`
  = `densityDpi / 160`（显示密度）；
- `di3` 为 docPx 值类 → `lj3.d = ti3.e` 为 **docPx** 段基字号；
- 比较式 `f3×f5` = docPx×density → px，对照 span 的 `qi3.c.c>>32`
  布局尺寸——单位链自洽。
- Harmony `element.fontSize` 同为 docPx → **−24 直接可移植**。

## 决定

- `applyCodeBlockFace` 增 `baseFontSize` 形参：CODE_BLOCK 字符无
  显式 `fontSize` 时写入 `max(base−24, 1)`（monospace 字族不变）；
  显式 run 字号保留。
- `paragraphFontSize(element, paragraph)` 供行度量（基线 init、
  lineHeight、bandTop、推进、覆盖高度）使用——CODE_BLOCK 段全部
  以收缩后基字号为准。

## 后果

- 代码块字形与行几何均按原版 `d−24` 收缩，行距/底带联动一致。
- ADR-0648 差异表该登记行标记闭环（CRDT 编码器、语言选择器、
  语法高亮登记维持不变）。

## 验证

- `d02-original-quote-code-blocks.mjs` 新增 5 钉；专项与全量见提交。
- `note@default`/`note@ohosTest` HAP 构建通过。
