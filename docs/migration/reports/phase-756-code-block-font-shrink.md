# Phase 756：代码块段基字号 d−24 docPx 收缩

> 日期：2026-09-25
> 证据：`docs/migration/evidence/phase-756-code-block-font-shrink.md`
> ADR：`docs/migration/adr/ADR-0704-code-block-font-shrink.md`（纠正
> ADR-0648"单位体系不同"判据）
> Replay：`d02-original-quote-code-blocks.mjs`（37 断言，全绿）

## 背景

ADR-0648 把 `lj3` 的 CODE_BLOCK 字号收缩 `f3 = max(d−24f, 1f)` 登记为
"单位体系不同"的近似项。Phase 756 复核完整单位链：
`lj3.d = ti3.e`（docPx 段基字号），`lj3.c = x82.T(context)` =
densityDpi/160（密度），`f3×f5` 对照 span 布局 px——Harmony
`element.fontSize` 同为 docPx，单位同域、−24 直接可移植。

## 实现（Canvas2DTextRenderer.ets）

- `applyCodeBlockFace` 增 `baseFontSize`：CODE_BLOCK 字符无显式
  fontSize 时写 `max(base−24, 1)`（显式 run 字号保留）。
- 新 `paragraphFontSize(element, paragraph)`：decoratorStyle===5 →
  `max(fontSize−24, 1)`。
- 6 处行度量点（首行基线×4、lineHeight/bandTop、推进、覆盖高、
  code 底带）改用收缩后段基字号，等宽字族保持原状。

## 验证

- 专项 Replay：37/37（2 钉演进 + 5 新钉）
- 全量 Desktop Replay：**PASS=631 FAIL=0**
- `note@default` / `note@ohosTest` HAP 构建：BUILD SUCCESSFUL
- ADR-0648 差异表对应行已更新为闭环（CRDT 编码器/语言选择器/语法
  高亮登记不变）。
