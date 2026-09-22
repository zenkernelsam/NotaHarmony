# 修复总结 — Phase 588：原版 Tape 设置行 Hide/Reveal Tapes（2026-09-28）

## 原版契约（证据）

- `o94` case14：胶带工具设置页内的行，`z`(tapesRevealed) 翻转
  "Hide Tapes"/"Reveal Tapes" 文案+图标；`ipi.b(z,onClick)` 发出该行，
  点击 `oh9 → np0 case5` 全量 toggle（空集 no-op）。

证据文档：`docs/migration/evidence/original-tape-settings-reveal-row-2026-09-28.md`
ADR：`docs/migration/adr/ADR-0557-original-tape-settings-reveal-row.md`

## Harmony 实现

- `ToolboxSettingsDialog` REVIEW 行 ⋯ 菜单增 Hide/Reveal 项（动态
  标签，`tapeCount > 0` 门控）——与 `tape_patterns` 同处胶带设置面。
- `EditorToolbar` 增 `tapeCount`/`anyTapeRevealed`/`onTapeToggle` 并透传。
- `NotePage` 注入会话态，`onTapeToggle` → `tapeToggleSignal++`
  （与 ⋮ 选项菜单项同一信号）。

## 验证

- 回放 `d02-original-tape-settings-reveal-row.mjs`：11 项断言全绿。
- `note@default`：构建成功，无新增 ArkTS 错误。

## 遗留

- 原版行是否由上游按可见 tape 条件组合未静态取证，取 `tapeCount > 0`
  门控（与 Phase 583 ⋮ 菜单一致），已在 ADR 记录。
