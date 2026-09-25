# ADR-0673 plurals.xml 尾部收口：PDF 截断导入 + 复数化标签 + 边界登记

- 状态：Accepted
- 日期：2026-09-25
- 关联 Phase：725
- 证据：`docs/migration/evidence/original-plurals-tail-jadx-2026-09-25.md`
- Replay：`docs/migration/replays/d02-original-plurals-tail.mjs`

## 背景

字符串族审计全部收口后，审计向量转入非 string 资源。`plurals.xml` 共 15 条
复数量词资源，其中多数已在既有 Phase 覆盖（`notes_selected`、
`indexing_notes`、`unindexed_note` 等）或落在已登记的边界族
（version_history / paywall / settings）。本 Phase 处理四个可移植残留项与
边界登记。

## 决策

### 已移植

1. **PDF 超 10000 页截断导入**（`fr1.java:113`）：
   原版 `z66VarV = rh8.V(0, pageCount > 10000 ? 10000 : pageCount)` +
   `ada(..., pageCount > 10000)`——超上限只导入前 10000 页并标记 truncated，
   由 `vs8` 状态机弹 `ui_fileimport__pdfs_truncated` 提示
   （one="PDF was too long. Imported the first %1$d pages."；
   other="Some PDFs were too long. Imported the first %1$d pages of each."）。
   Harmony 此前 `pageCount > PDF_IMPORT_MAX_PAGES` 直接抛错拒绝，属于迁移
   引入的缺陷。现改为：parse 层按 `min(rawPageCount, 10000)` 遍历页尺寸，
   `ImportedPdfParse.truncatedPages` 记录截断标记，`StagedPdfParse` 透传，
   成功 `ImportReport` 回填 `truncatedPages`/`truncatedCount`，
   `aggregatePickedReports` 累计截断文件数，`LibraryPage.toastTruncatedPages`
   按 `truncatedCount > 1` 分流 one/other 文案（共享打开与文件选取两条
   成功路径均挂载）。`pageSizes` 只含已导入页，不制造越界页引用；
   密码 PDF 与 500MB 共享上限语义不变。

2. **多笔记删除确认标题复数化**（`i8.java` case4 →
   `feature_library__delete_note_message`）：原版对话框标题即复数量词
   （one="Delete Note?"；other="Delete Notes?"），`tpe.b` 直渲标题。
   Harmony 此前固定单数 `delete`。现 `confirmMultiDelete` 按 `count===1`
   分流 `delete_note_title_one`/`delete_notes_title_other`；正文补
   `delete_notes_message_one`（单数语法 "Move %d note…"）修复 "1 notes"
   语法缺陷，多数仍走 `delete_notes_message`。

3. **导入清单文件计数标题**（`aeh:87` →
   `ui_fileimport__n_files_capitalized`）：清单头部标题下新增计数行，
   one="%d File"、other="%d Files"，zh_CN 两形态均 "个文件"。

### 边界登记（不移植）

- `feature_settings__delete_confirmation_message` +
  `feature_settings__notes_selected`（`bib.java`）：原版 Recently Deleted
  页面的**多选模式**工具条计数与批量永久删除确认。Harmony 最近删除页仅
  单条操作，多选模式整体缺位——登记为缺失界面边界（非资源缺口），
  待该面补建后随附复数资源。
- `feature_settings__note_limit_notes`（`uui.java:986`）：免费层笔记
  数量上限在设置订阅行的展示——依附于订阅面，随 ADR-0662
  账号/付费边界 fail-closed。
- `feature_note__version_history_editor_count` /
  `version_history_upsell_title`：版本历史编辑器计数与 upsell 标题——
  版本历史面已 fail-closed（ADR-0544，远端 flag `ac4.d0` + 后端）。
- `feature_paywall__free_trial_footnote`：免费试用脚注——付费墙面
  fail-closed（ADR-0662）。
- `ui_fileimport__selected_files`：系统文件选取器工具条标题
  （"Selected file/files"）——属平台 picker 内部文案，HarmonyOS
  `DocumentViewPicker` 为系统面，无注入点。
- `ui_fileimport__ntb_files_could_not_be_imported`（`i8.java` case3）：
  .ntb 批量导入部分失败计数提示——Harmony 的 .ntb 导入沿既有
  `import_failed`/`PARTIAL` 聚合消息报告（含失败数），文案粒度差异
  记录于此，不另增专用复数键。
- `feature_library__empty_folder_note_count` /
  `empty_folder_subfolder_count` / `indexing_notes` / `unindexed_note` /
  `notes_selected`：已在 Harmony 资源/页面以 one/other 双形态覆盖
  （Phase 717/723 等既有工作），本 Phase 不再重复。

## 后果

- 10000+ 页 PDF 从"整体拒绝"改为与原版一致的截断导入 + 提示。
- 多删确认标题随数量切换单复数，单数正文语法修复。
- 导入清单出现文件计数行（one/other）。
- `plurals.xml` 15 键全部有归属（实现 3 簇 + 覆盖确认 5 键 +
  边界登记 7 键）。
