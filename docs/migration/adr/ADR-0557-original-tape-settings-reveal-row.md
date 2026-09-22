# ADR-0557: 胶带工具设置面内的 Hide/Reveal Tapes 行

## Status

Accepted, 2026-09-28.

## Context

原版 Hide/Reveal Tapes 行位于**胶带工具自身的设置页**（`ipi.b` →
`o94(z,14)`，与图案行 `lfe.b`/`mh9` 同一设置面），标签随
`tapesRevealed` 翻转，点击 `oh9 → np0 case5` 对全部可见 tape ID 做
集合 toggle，空集 no-op。

Harmony Phase 583 已实现同语义的全局开关但仅暴露于编辑页 ⋮ 选项
菜单；Phase 585 的图案行已落在 `ToolboxSettingsDialog` REVIEW 行
⋯ 菜单（Harmony 无单工具设置页的既定表面偏差）。同一设置面内的
Hide/Reveal 行缺失。

## Decision

- `ToolboxSettingsDialog`：新增 `@Prop tapeCount`、
  `@Prop anyTapeRevealed`、`onTapeToggle`；REVIEW 行 ⋯ 菜单在
  `tapeCount > 0` 时增 Hide/Reveal 项（动态标签，与 ⋮ 菜单一致）。
- `EditorToolbar`：同名 props + 回调透传至对话框。
- `NotePage`：注入 `pageTapeCount`/`anyTapeRevealed`，
  `onTapeToggle` → `tapeToggleSignal++`——与 ⋮ 菜单项共用同一
  信号，两处入口语义完全一致。

## Consequences

- 表面偏差记录延续：Harmony 无单工具设置页，原版"胶带设置页内行"
  落在 REVIEW 行 ⋯ 菜单（与 `tape_patterns` 同面）；动作语义不变。
- `tapeCount > 0` 门控延续 Phase 583 的一致策略（原版空集即 no-op；
  行是否由上游按可见 tape 条件组合未能静态取证，取保守一致行为）。
- 回放 `d02-original-tape-settings-reveal-row.mjs` 钉死 props 链路、
  动态标签、门控与双入口同信号。
