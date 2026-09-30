# Phase 1396 证据 — content_manager 面板开合 outline 切换

## 原版 1.4.2 硬证据

| 证据 | 位置 | 内容 |
|------|------|------|
| 图标注册 | `defpackage/fp0.java` | `ui_designsystem__content_manager` 注册为 `p2c` RichIcon |
| 双轮廓 | `p2c` 模型 | `fill` + `overlay` + `outline_default`/`outline_selected` 双轮廓——页面管理器面板开合时切换 outline |
| 开关位置 | `x90.g`/`gs8 case2` | content-manager = 顶栏首项，页面面板开关（undo/redo 之前） |

## Harmony 状态（Phase 1370 遗留）

Phase 1370（ADR-1306）把 `▦` 占位换成 `content_manager` 字形，并把
`content_manager_selected` 双轮廓数据提取进 `TOOL_GLYPHS`——但工具条
只收 `onTogglePagesPanel()` 回调、不持面板开合态，始终渲染
`outline_default`。登记为「待面板状态透传」近似。

## 本 Phase 接线

| 项 | 实现 |
|----|------|
| 状态透传 | `EditorToolbar` 新增 `@Prop pagesPanelOpen`；`NotePage` 传 `showPageOverview` |
| 轮廓切换 | 按钮 glyph `pagesPanelOpen ? 'content_manager_selected' : 'content_manager'` |
| 关闭路径 | `.bindSheet(showPageOverview)` 双向绑定——滑走/显式关闭均回落默认轮廓 |
| 行为/无障碍 | `onTogglePagesPanel`、`cd_pages_panel_toggle`、lease 门禁原样 |

## 有界差异

无新增。`p2c` 的 fill/overlay 两轮廓共用，仅 outline 随态切换——与原版
一致（selected 轮廓仅改 outline 路径，fill 不动）。
