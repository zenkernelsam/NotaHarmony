# Phase 1330 证据 — 渲染合成（部分橡皮+分层合成）

来源：`rendering/{EraserEngine,StrokeLayerManager}.ets`。

## `EraserEngine` 部分橡皮 = 几何裁剪

```
erasePartial(eraserPath, strokes):
  命中的 Ink → 裁剪为零/多个新 Ink 残余（partialReplacements）
  + 删除源实体
// Notability 1.0.3 部分橡皮不保留 CREATE_INK tool 5：
//   逐命中 Ink 裁剪成残余实体（对照 w4b/h4f clip 语义，
//   pencil/custom-outline 裁剪）
```

→ 部分橡皮 = **几何裁剪**（非像素 destination-out 擦除
—— 实体级拆分，对照 `w4b`/`h4f`）。

## `StrokeLayerManager` 分层合成

```
每帧：已完成层 + 当前笔画 → 主画布
  mainCtx.clip() 脏区 clipRect 限制重绘
  destination-out —— 完整有序页内容上执行
```

→ 分层合成（completed+current→main）+ 脏区 clip +
destination-out 橡皮 —— 对照原版离屏层合成。

## 渲染合成语义

- 部分橡皮 = 几何裁剪（实体拆分 `partialReplacements`）
- 整体橡皮 = 实体删除
- 合成 = 分层 + 脏区 clip + destination-out

## Harmony 决策

渲染合成 = 几何裁剪橡皮 + 分层脏区合成 —— 对照
原版（`w4b`/`h4f` clip + 离屏层）。

## 产出

- fixture `d02-render-composite.mjs`（10 断言）。
- ADR-1274；中文报告。
