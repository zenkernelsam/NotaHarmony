# Phase 1330 报告 — 渲染合成

## 完成内容

- `EraserEngine` 部分橡皮 = 几何裁剪（`erasePartial` 把命中
  Ink 拆成 `partialReplacements` 残余+删源实体，对照 `w4b`/
  `h4f` clip——原版部分橡皮不留 tool 5）；`StrokeLayerManager`
  = 分层合成（completed+current→main + 脏区 `clip()` +
  destination-out 橡皮）—— 渲染合成保真。

## 产出

- evidence `phase-1330-render-composite.md`
- fixture `d02-render-composite.mjs`（10/10）
- ADR-1274
