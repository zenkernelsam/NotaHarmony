# ADR-0555: 胶带点按揭示（dl1 → xtc.b → ej9 case20 → xo5 对齐）

## Status

Accepted, 2026-09-28.

## Context

原版在每次画布 pointer-down 先执行 tape 命中检测（`dl1` case2 →
`xtc.b`）：命中元素为 tape 时，收集覆盖该点的**全部** tape 元素 ID
（`fu1.f` 区域查询 + `I.k()` 过滤，空集回退首命中 ID），派发
`ej9` case20 → `xo5` case2 对会话级 `revealedTape` 集合做
containsAll→removeAll / else→addAll 的 toggle，且该手势被消费、不再
进入工具分发。

Harmony Phase 583 已落地会话级 `revealedTapeIds` 与全局 Hide/Reveal
开关，但点按揭示链路未移植——点按 tape 只会进入书写/橡皮等工具分发。

## Decision

- `EraserEngine.hitStrokeAtPoint(point, stroke)`：公开点命中测试，
  复用 `sampleStroke` 采样管线（transform、三次曲线细分、widthFactor
  插值），判定半径 = `brushWidth·widthFactor·maxLinearScale/2`。
- `ShapeGeometry.tapeHitTestShape(point, shape)`：抽取
  `shapeCoveredByPath` 与 `eraserPathHitsShape` 共用覆盖几何（中心线
  带宽 + 闭合填充内部），但不继承 `positionLocked` 早退——揭示不是
  编辑操作。
- `NoteCanvasView.tapeIdsAtPoint`：收集覆盖点的全部 tape ID——笔画
  `renderSpec.tapePattern != null` + 形状 `originalTool === 3`。
- `NoteCanvasView.tapRevealTapeAt`：`xo5` toggle（全揭示→delete，否则
  →add），`emitTapeRevealState()` + `renderFrame(true)`，命中返回
  true。
- `onTouchDown` 接线：DEFAULT 文本分支头部与选区菜单守卫之后各探测
  一次——对橡皮/选区/激光/书写全部分发先行拦截，命中即早退消费手势；
  `pageTapeIds` 扩展含 tape 形状使全局开关与点按集合域一致。

## Consequences

- 顺序偏差记录：选区菜单（屏幕坐标覆盖层）守卫先于 tape 探测——覆盖
  层按钮不被 tape 命中干扰；其余工具分发顺序与 `dl1` 一致。
- tape 形状（`originalTool===3`）当前不渲染图案层（后续 tape 形状
  渲染阶段补齐），其 ID 进入揭示集合无可见效果但语义忠实。
- 点按命中即消费：tape 上的单击不会误起笔/误擦除，与原版一致。
- 回放 `d02-original-tape-tap-reveal.mjs` 钉死命中几何、全集合收集、
  toggle 语义与指针顺序。
