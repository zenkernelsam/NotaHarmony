# ADR-0553: Tape 工具入箱（rz1:1075 REVIEW 默认工具态）

## Status

Accepted, 2026-09-28.

## Context

原版默认工具箱（`rz1.java:1075`）把 REVIEW（`a6f.S`，胶带）放在
Secondary 托盘 index 3，brush 态 `w31(-1706497, 36.0f, style=null,
colorWell=0, widthWell=1, tapePattern=0)` —— 首色井、中档宽度井、
STRIPES 图案。`dm2` 校验 tapePattern 仅随 TAPE 工具的 CreateInkOp
下发。

Harmony 此前 `ToolType.REVIEW` 仅作持久化枚举存在：`createDefaultStates`
无该行、`supportsBrushControls` 不含 REVIEW、`getRenderSpec` 不携带
tapePattern——胶带工具不可选、不可画。

## Decision

- `createDefaultStates` 增 `'tape'` 行：REVIEW + Secondary index 3 +
  color -1706497 + width 36 + colorWell 0 + widthWell 1 +
  `tapePattern: STRIPES`（逐字段对齐 w31）。
- `createState` 扩展可选 `tapePattern` / `colorWellIndex` /
  `widthWellIndex` 参数并写入 ToolState。
- `EditorViewModel.activeTapePattern`（缺省 STRIPES）承接当前 REVIEW 行
  的 `state.tapePattern`；`getRenderSpec()` 仅 REVIEW 时下发
  `tapePattern`，其余工具 `undefined`（dm2 语义）。
- `supportsBrushControls` 纳入 REVIEW（原版有 5 色井 + 3 宽度井）；
  `toolTypeLabel` REVIEW → `tape_tool`。
- 触摸分发无需改动：非橡皮/选区/激光工具落入既有笔迹管线，
  `renderSpec.tapePattern` 直通 StrokeSession → StrokeElementData →
  renderTapePattern（Phase 582 置顶分区同步生效）。

## Consequences

- 胶带工具在工具栏可选可画，产出的笔画带 `renderSpec.tapePattern`，
  自动获得 Phase 582 置顶渲染、Phase 583 揭示门控与既有图案渲染。
- 存量工具箱经 missing-defaults 回填在 Secondary 尾部补 REVIEW（index
  非 3）——与原版新安装顺序偏差已记录；不影响 trayType 语义。
- 胶带图案选择器（mh9/nh9）与点按揭示（xtc）仍待后续阶段。
- 回放 `d02-original-tape-tool-entry.mjs` 钉死默认态、井位、
  renderSpec 门控与标签。
