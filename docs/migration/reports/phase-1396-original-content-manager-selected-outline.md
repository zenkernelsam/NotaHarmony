# Phase 1396 报告 — content_manager 面板开合 outline 切换

- 阶段：1396
- ADR：ADR-1332（修订 ADR-1306 已知近似）
- 证据：`docs/migration/evidence/phase-1396-original-content-manager-selected-outline.md`
- Replay：`docs/migration/replays/d02-original-content-manager-selected-outline.mjs`（12 检查）

## 背景

Phase 1370（ADR-1306）把工具条 `▦` 占位换成原版
`ui_designsystem__content_manager`（fp0 p2c RichIcon）字形，并把
`outline_selected` 数据提取进 `TOOL_GLYPHS`——但工具条只收
`onTogglePagesPanel()` 回调、不持面板开合态，始终渲染默认轮廓。
登记为已知近似。

## 修复

- `EditorToolbar` 新增 `@Prop pagesPanelOpen`；按钮 glyph 切
  `pagesPanelOpen ? 'content_manager_selected' : 'content_manager'`。
- `NotePage` 传 `pagesPanelOpen: this.showPageOverview`；
  `.bindSheet(showPageOverview)` 双向绑定覆盖滑走/显式关闭回落。
- 行为/无障碍原样：`onTogglePagesPanel`、`cd_pages_panel_toggle`、
  lease 门禁不变。

## 改动文件

- `note/src/main/ets/ui/editor/EditorToolbar.ets` — prop + 轮廓切换
- `note/src/main/ets/ui/editor/NotePage.ets` — 状态透传
- `docs/migration/replays/d02-original-content-manager-selected-outline.mjs`（新增）

## 验收

- 硬证据：`fp0.java`（p2c RichIcon 双轮廓）、`x90.g`/`gs8 case2`
  （顶栏首项 = 页面面板开关）、ADR-1306 遗留项。
- `d02-original-content-manager-selected-outline` 12 检查绿；
  全量基线全绿。
- `note@default`/`note@ohosTest` HAP 构建成功，无新增 ArkTS 错误。

## fail-closed / 边界

无。fill/overlay 共享、仅 outline 随态切换，与原版 p2c 一致。
