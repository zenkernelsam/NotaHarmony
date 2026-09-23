# Phase 641 — 原版编辑器右上角 Share 入口（NOTE 格式先行）

- 日期：2026-09-23
- 证据：`docs/migration/evidence/original-editor-share-entry-jadx-2026-09-23.md`
- ADR：`docs/migration/adr/ADR-0608-original-editor-share.md`
- Replay：`docs/migration/replays/d05-original-editor-share.mjs`（41 断言）

## 原版行为

- `x90.g` 编辑器顶栏：undo/redo 图标块（`p9f`）之后，
  `lc4.a(ac4.L)` 门控渲染 48dp Share 图标按钮；`ac4.L` =
  NOTE_SHARE，`zb4.L` = PRODUCTION 档，`lc4.a` 对 PRODUCTION 默认
  返回 true——分享图标在生产构建常显。
- `ke1` case 15：`ui_designsystem__share` 图标 +
  `feature_note__toprighttoolbar_share_action` 无障碍文案。
- 点击打开分享面板（`b7d`/`v6d`，21 字段 UI 状态）：格式枚举 `s6d`
  = LINK、PDF、NOTE、JPG、PNG（`atc` case 3~7 各自图标）；单笔记
  默认选中 LINK，多笔记默认 PDF；导出按格式上报分析
  （Link/PDF/Note/JPEG/PNG）。
- `y59.b`（按格式导出执行体）在 JADX 层未反编译。

## Harmony 缺口（修复前）

- 编辑器内无任何分享/导出入口；`.note` 导出只存在于库级上下文菜单
  （`LibraryPage.exportNote` → `NoteExporter.exportToFile`）。
- `EditorToolbar` 顶行止于 Redo 按钮。

## 本 Phase 变更

### `note/src/main/ets/ui/editor/EditorToolbar.ets`

- 新增 `@State showShareSheet` 与 `onShareNote: () => void` 回调；
- Redo 按钮后新增 48vp Share 按钮（`↗` 字形，
  `cd_share_action` 无障碍，`photoImportLeaseActive` 门禁），点击
  打开分享面板；
- 同一 Column 追加第二个 `.bindSheet`（`buildShareSheet`）；
- `buildShareSheet` + `ShareFormatRow`：按 `s6d` 原序列出
  Link/PDF/Note/JPG/PNG 五行；仅 NOTE 行可点（关面板 →
  `onShareNote()`），其余 `opacity 0.4` + "暂不支持"标注、点击空转。

### `note/src/main/ets/ui/editor/NotePage.ets`

- 导入 `NoteExporter`；
- `onShareNote` 走 `photoImportLeaseActive/pageOperationBusy/
  historyPending` 门禁 → `shareNoteAsFile()`；
- `shareNoteAsFile()`：`NoteExporter.exportToFile(context, noteId,
  noteTitle)`——与库级导出同一管线（.note zip +
  DocumentViewPicker 保存对话框 + `export_done`/`export_failed`
  toast）。

### 字符串（base + zh_CN）

新增 `cd_share_action`、`share_sheet_title`、`share_link`、
`share_pdf`、`share_note`、`share_jpg`、`share_png`、
`share_format_unsupported` 各八条双语。

## Fail-closed 登记（ADR-0608）

- LINK/PDF/JPG/PNG 行置灰：PDF/JPG/PNG 需页级栅格化器
  （ThumbnailRenderer 仅缩略图分辨率不可复用），LINK 需账号/链接
  后端；
- 原版面板"chip 选择 + 页选择 + 动作按钮"两步交互简化为单行即点；
- 原版单笔记默认选中 LINK——Harmony 无可默认项；
- 原版经安卓系统分享 Intent 分发；Harmony 以 DocumentViewPicker
  保存对话框为原生对等物。

## 验证

- 专项 `d05-original-editor-share.mjs`：41 断言绿
  （`D05_ORIGINAL_EDITOR_SHARE_REPLAY_OK TOTAL=41 FAILED=0`）；
- 全量 Desktop Replay：526/526 全绿；
- `note@default` 与 `note@ohosTest` 双 HAP clean 构建成功，仅存量
  deprecated/"may throw" 告警，无新增 ArkTS 错误。

## 提交

见 git log `Phase 641` 提交。
