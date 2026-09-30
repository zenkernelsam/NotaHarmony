# Phase 1392 报告 — `note_state.last_code_block_language` 代码块语言记忆

- 阶段：1392
- ADR：ADR-1328
- 证据：`docs/migration/evidence/phase-1392-original-code-block-language-restore.md`
- Replay：`docs/migration/replays/d02-original-code-block-language-restore.mjs`（17 检查）

## 背景

延续 Phase 1391 的 Room schema 逐表比对，对 `NoteStateEntity`
（`ca3.java:519`）比对发现 `note_state` 缺 `lastCodeBlockLanguage` 列。
Harmony 已有代码块语言选择器（`TextBlockOverlay` `CODE_LANGUAGES`/
`programmingLanguage`），但未持久化「上一次使用的代码块语言」，新建代码块
缺默认恢复——原版 `ya8.java:34` 明确 CODE_BLOCK toggle 需恢复
`lastCodeBlockLanguageId`。

## 修复

- **schema**：`note_state.last_code_block_language TEXT DEFAULT NULL`；
  migration 74（同款原版 `r4a.java:70`）；`DB_VERSION 73→74`。
- **持久化**：`NoteViewState.lastCodeBlockLanguage`；`getViewState` 读；
  `saveViewState` `undefined`→保留已存值（REPLACE 不整行清）；
  `saveLastCodeBlockLanguage(noteId, lang)` 专写。
- **行为**：`TextBlockOverlay` `@Prop lastCodeBlockLanguage` +
  `onCodeLanguageSelected`；`setCodeLanguage` 选语言即持久化（plaintext→null）；
  `toggleDecoratorStyle` 新代码块默认恢复上次语言；`NoteCanvasView` 载入+回写。

## 改动文件

- `note/src/main/ets/data/DatabaseHelper.ets` — DB_VERSION=74、note_state DDL、migration 74
- `note/src/main/ets/core/model/NoteTypes.ets` — `NoteViewState.lastCodeBlockLanguage`
- `note/src/main/ets/data/RepositoryInterfaces.ets` — `saveLastCodeBlockLanguage` 签名
- `note/src/main/ets/data/NoteRepositoryImpl.ets` — getViewState 读 / saveViewState 保留 /
  saveLastCodeBlockLanguage
- `note/src/main/ets/ui/editor/NoteCanvasView.ets` — 载入、@State、persistCodeBlockLanguage、prop+callback
- `note/src/main/ets/ui/components/TextBlockOverlay.ets` — @Prop + restore + 写回
- `note/src/test/DatabaseHelper.test.ets` — `assertEqual(74)`
- `docs/migration/replays/d02-original-code-block-language-restore.mjs`（新增）
- 版本钉线 fixtures `DB_VERSION=73→74`

## 验收

- 硬证据：`ca3.java:519`、`r4a.java:70`、`chb.java:44`、`ws3.java:277`、
  `e83/f83.java`、`ya8.java:34`。
- `d02-original-code-block-language-restore` 17 检查绿；全量基线全绿。
- `note@default`/`note@ohosTest` HAP 构建成功，无新增 ArkTS 错误。

## fail-closed / 边界

- plaintext→null（清除记忆），按「最后显式选择」语义；原版精确清除边界混淆
  不可逐位取证。
- `zoomViewSourceRect`/`zoomViewShown`/`isTextOnly` 留待后续 Phase
  （ZOOM-view 持久化 / text-only 模式）。
