# ADR-1328 — `note_state.last_code_block_language` 每笔记代码块语言记忆

- 状态：已接受
- 日期：2026-08（Phase 1392）
- 证据：`docs/migration/evidence/phase-1392-original-code-block-language-restore.md`

## 决策

补齐 `note_state` 对照 `NoteStateEntity`（`ca3.java:519`）缺落的
`lastCodeBlockLanguage` 列，并实现其**恢复默认**行为：

1. **schema**：migration 74 `ALTER TABLE note_state ADD COLUMN
   last_code_block_language TEXT DEFAULT NULL`（与原版 `r4a.java:70` 同款）；
   canonical DDL 同步增列；`DB_VERSION 73→74`。

2. **持久化链**：`NoteViewState.lastCodeBlockLanguage?: string | null`；
   `getViewState` 读（null 容忍）；`saveViewState` 在字段 `undefined` 时
   **读现值保留**（`ON_CONFLICT_REPLACE` 整行重写，避免 viewport 保存误清）；
   新增 `saveLastCodeBlockLanguage(noteId, lang)` 专写（保留 zoom/scroll）。

3. **行为**：`TextBlockOverlay` 新增 `@Prop lastCodeBlockLanguage` +
   `onCodeLanguageSelected` 回调；`setCodeLanguage` 显式选语言即回传持久化
   （plaintext→null）；`toggleDecoratorStyle` `decorator===5` 新建代码块无
   既有 `programmingLanguage` 时默认 `lastCodeBlockLanguage`——复刻
   `ya8.java:34` 的 restore 语义。`NoteCanvasView` `getViewState` 载入、
   `persistCodeBlockLanguage` 写库。

## 显式差异

- plaintext 选择 → `null`（清除记忆）。原版 `lastCodeBlockLanguage` 的精确
  清除边界（plaintext 是否覆写）被混淆压缩不可逐位取证——按「最后显式选择的
  代码块语言」语义实现，plaintext 视为清除。
- `zoomViewSourceRect`/`zoomViewShown`/`isTextOnly` 仍缺——对应 ZOOM-view
  持久化与 text-only 模式，另行 Phase，不在本 Phase。

## 回归

`d02-original-code-block-language-restore.mjs`（17 检查）；版本钉线 fixtures
随升 74 同步 `DatabaseHelper.test.ets` `assertEqual(74)`。全量基线全绿。
