# Phase 725 中文报告：plurals.xml 尾部收口（PDF 截断导入 + 复数化 + 边界登记）

## 范围

`resources/res/values/plurals.xml` 全部 15 条复数量词资源的审计收口。
多数键已被既有 Phase 覆盖或落在已登记边界族；本 Phase 落地三个可移植
残留项，其余登记为缺失面/平台/后端边界。

## 原版证据

见 `docs/migration/evidence/original-plurals-tail-jadx-2026-09-25.md`：

- `fr1.java:113`——`pageCount > 10000 ? 10000 : pageCount`，原版对超限
  PDF 只导前 10000 页并置 truncated 标记，由 `vs8` 弹
  `ui_fileimport__pdfs_truncated`（one/other 双文案）。
- `i8.java` case4——多删确认对话框标题即 `feature_library__delete_note_message`
  复数量词（"Delete Note?"/"Delete Notes?"）。
- `aeh:87`——导入清单 `ui_fileimport__n_files_capitalized` 计数标题。
- `bib.java:28-30`——Recently Deleted 多选工具条 + 批量永久删除确认
  （Harmony 该页无多选模式 → 缺失面边界）。
- `uui.java:986`、`hof.java:126`——note-limit/库选择计数消费点。

## 变更

- `NoteImporter.ets`：
  - `parseImportedPdf()` 超上限不再抛错：`rawPageCount > 10000` 时按
    10000 遍历页尺寸，`ImportedPdfParse.truncatedPages` 记录截断量；
    `pageCount<=0`/非法尺寸校验保留。
  - `StagedPdfParse` 增 `truncatedPages` 并透传；`ImportReport` 增
    `truncatedPages`/`truncatedCount` 可选字段；两处 PDF 成功报告回填；
    `aggregatePickedReports` 累计截断文件数，聚合报告回填
    `truncatedPages=PDF_IMPORT_MAX_PAGES`。
- `LibraryPage.ets`：新增 `toastTruncatedPages(report)`——
  `truncatedCount>1` 用 `import_pdfs_truncated_other`、否则
  `import_pdf_truncated_one`；`importSharedAndOpen`/`importAndOpen`
  成功路径挂载。`confirmMultiDelete` 标题按 count 复数化
  （`delete_note_title_one`/`delete_notes_title_other`），单数正文
  改用 `delete_notes_message_one` 修复 "1 notes" 语法。
- `ImportDetailsSheet.ets`：标题行下新增文件计数行
  （`import_files_count_one`/`other`），排列模式不受影响。
- 资源 en/zh 各 +7 键。

## 边界登记（ADR-0673）

Recently-Deleted 多选（`delete_confirmation_message`/`notes_selected`）、
版本历史两条、paywall footnote、note-limit、picker `selected_files`、
`ntb_files_could_not_be_imported` 专用粒度——均登记为缺失面/平台/后端
边界，不臆造实现。

## 验证

- `d02-original-plurals-tail.mjs` 全绿。
- 全量 Desktop Replay 全绿。
- `note@ohosTest` + `note@default` clean 构建成功，无新增 ArkTS 错误。
