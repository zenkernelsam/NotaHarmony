# Phase 1370 报告 — 编辑器工具条操作按钮改用原版矢量动作图标

## 改动概要

工具条六个 **Unicode 占位**按钮（`▦`/`...`/`⚙`/`↶`/`↷`/`↗`）换成原版
`ui_designsystem__*` 矢量字形，复用 Phase 1368 的 `Shape + Path +
viewPort(24)` `ToolGlyph` 管线。

| 占位 | 动作 | 原版资源 |
|---|---|---|
| `▦` | 页面面板开关 | `content_manager`（p2c）|
| `...` | 紧凑溢出 | `hamburger` |
| `⚙` | 工具箱设置 | `settings_*`（m4f 分层）|
| `↶` | 撤销 | `topnavundo` |
| `↷` | 重做 | `topnavredo` |
| `↗` | 分享 | `share` |

## 实现

- `_gen_toolglyphs.cjs` 追加 7 键；`ToolGlyphs.ets` 现 18 键。
- 平面图标（undo/redo/share/hamburger）走 `o` 槽 `contentColor` 描边，
  等价 `go5.b` ColorFilter；`settings`/`content_manager` 走分层槽。
- 所有点击回调、`enabled`、`bindMenu`/`bindPopup`、`accessibilityText`
  原样保留；undo/redo 的 `.opacity(canUndo/canRedo?1:0.4)` 保留禁用态。

## 文件

- `note/src/main/ets/ui/components/ToolGlyphs.ets`（重新生成）
- `note/src/main/ets/ui/editor/EditorToolbar.ets`
- `docs/migration/replays/d02-original-editor-toolbar-action-glyphs.mjs`（新）
- `docs/migration/adr/ADR-1306-toolbar-action-glyph-mapping.md`（新）
- `docs/migration/evidence/phase-1370-editor-toolbar-action-glyphs.md`（新）

## 验证

- 新 fixture：41/41。
- 全量 Replay 基线：1223/1223。
- `note@default` / `note@ohosTest` clean 构建成功。

## 已知近似

`content_manager` 的 selected 轮廓待面板状态透传后接线（ADR-1306）。
