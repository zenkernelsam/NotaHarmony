# ADR-1332 — content_manager 面板开合 outline_selected 接线

- 状态：已接受
- 日期：2026-08（Phase 1396）
- 证据：`docs/migration/evidence/phase-1396-original-content-manager-selected-outline.md`
- 修订：ADR-1306「content_manager_selected 待面板状态透传」的已知近似——
  本 Phase 完成接线。

## 决策

把 `showPageOverview` 面板开合态经 `@Prop pagesPanelOpen` 透传进
`EditorToolbar`，content_manager 按钮在面板开启时渲染
`content_manager_selected`（fp0 p2c `outline_selected`），关闭时回落
`outline_default`。

## 实现要点

- `TOOL_GLYPHS` 的 `content_manager_selected` 数据在 Phase 1370 已提取，
  本 Phase 仅接线、不动字形。
- `.bindSheet(this.showPageOverview)` 双向绑定天然覆盖滑走/显式关闭
  两条回落路径，无需额外信号。
- 行为/无障碍零变更：`onTogglePagesPanel` 回调、`cd_pages_panel_toggle`
  无障碍标签、lease 门禁原样。

## 行为差异

无。fill/overlay 共享、仅 outline 随态切换，与 fp0 p2c 双轮廓语义一致。

## 回归

`d02-original-content-manager-selected-outline.mjs`（12 检查）。
