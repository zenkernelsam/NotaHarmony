# ADR-0554: 胶带图案选择器（mh9 → t7f → nh9 对齐）

## Status

Accepted, 2026-09-28.

## Context

原版胶带工具的图案选择链路：工具设置页图案行（`lfe.b` 预览小样）→
`mh9` 打开 `t7f` 底栏 → `lfe.a` 按 `ife` 声明序渲染 9 个工具色图案
小样并标选中 → 点击经 `i31` case26 派发 `nh9(序数)` → `yh9(i3=1)`
用 `g5f.h` 复制工具态替换 tapePattern，`ti9.q` 应用并持久化到
`tool_state.tape_pattern`。

Harmony Phase 584 已使 REVIEW 工具可画（默认 STRIPES），但图案不可
切换——`tool_state.tape_pattern` 列与 `renderTapePattern` 9 图案渲染
器已就位，缺的是选择 UI 与写入路径。

## Decision

- 新增 `TapePatternPicker.ets`：`TAPE_PATTERN_ORDER` 与 `lfe.a`/`ife`
  声明序一致的 9 图案网格；`TapePatternSwatch` 用合成笔画经既有
  `renderTapePattern` 实绘小样（带体色 = `tool.brush.color`，PLAIN
  绘纯色带），`tool.tapePattern` 标选中。
- `ToolboxSettingsDialog`：REVIEW 行 ⋯ 菜单增 `tape_patterns` 项，
  打开选择面板（`tapePatternToolId` 切换对话内容）；选择后 refresh。
- `EditorViewModel.setToolTapePattern(toolId, pattern)`：仅限 REVIEW
  行 + 序数范围校验，经 `updateState` 写 `state.tapePattern` 并
  `saveToolState` 持久化；激活行经 `applyActiveState` →
  `activeTapePattern` 即时生效（`g5f.h` + `ti9.q` 等价）。

## Consequences

- 表面偏差：原版入口在胶带工具自身设置页内（`s7f`/`lfe.b` 预览行），
  Harmony 无单工具设置页，置于工具箱设置对话框 REVIEW 行菜单——
  动作语义（作用于该工具行的 tapePattern）一致，已记录。
- 选择器复用真实图案渲染管线，小样即所见笔迹图案。
- 回放 `d02-original-tape-pattern-picker.mjs` 钉死图案序、工具色
  着色、选中态、写入路径与表面接线。
