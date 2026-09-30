# ADR-1329 — `note_state` 补齐 `NoteStateEntity` 全列（round-trip 完整性）

- 状态：已接受
- 日期：2026-08（Phase 1393）
- 证据：`docs/migration/evidence/phase-1393-original-note-state-parity.md`

## 决策

完成 `note_state` 对 `NoteStateEntity`（`ca3.java:519`，8 列）的全列对齐：

migration 75 增三列 `zoom_view_source_rect TEXT`/`zoom_view_shown INTEGER`/
`is_text_only INTEGER`（均 `DEFAULT NULL`），canonical DDL 同步；
`DB_VERSION 74→75`。`NoteViewState` 增三可选字段；`getViewState` 读；
`saveViewState` 经 `readPreservedNoteState` 在 REPLACE 前保留已存值
（4 个保留列 `undefined`→读现值），布尔列写 INTEGER 0/1。

## 逐列行为判定

| 列 | 原版 | Harmony 处理 |
|----|------|--------------|
| `zoom_view_source_rect` | 持久化放大窗源矩形 `"l,t,r,b"`（`sbe`/`ten`），reopen 恢复 | **保列**。Harmony 放大窗 tool-gated（`isShown`=工具激活挂载、`initZoomSourceRect` 锚定末笔/视口中心），模型不同；不强切恢复语义 |
| `zoom_view_shown` | 持久化放大窗显隐（`wmb:75`） | **保列**。同上 tool-gated |
| `is_text_only` | 「Text only」视图模式（`options_menu_text_only`/banner/auto-exit） | **保列**。隐藏非文本元素的渲染模式=独立 Phase（渲染管线+横幅+auto-exit） |

## 显式差异

- 三列为**导入 round-trip 完整性**而保留（同 googleInkBrushPackId 先例），
  当前无 Harmony 写侧行为接入——`zoomViewSourceRect`/`zoomViewShown` 的
  持久化恢复与 `isTextOnly` 的纯文本渲染模式留待各自 Phase。
- `pick` 语义：保留列 `undefined`→读已存值（防 REPLACE 清），显式值→写入。

## 回归

`d02-original-note-state-parity.mjs`（27 检查）；版本钉线 fixtures 随升 75
同步 `DatabaseHelper.test.ets` `assertEqual(75)`。全量基线全绿。
