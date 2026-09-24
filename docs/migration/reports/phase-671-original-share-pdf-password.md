# Phase 671 — 原版分享面板 PDF 密码保护迁移

日期：2026-09-24
前置：Phase 670（`7a0bc882`）

## 目标

迁移原版分享面板的 PDF 导出密码保护：`v6d.k` 密码态 +
`r6d.PASSWORD_ENTRY` 录入屏 + 主屏 On/Off 行 + 双密码框
mismatch 校验 + `PdfDocument.setPdfPassword` 产物加密。

## 原版行为（证据：v6d/r6d/b7d/dih/h32/zy7/kw1/kv1/strings）

- `v6d.k` = `String` PDF 密码，**null = 关**。
- `b7d.o(str)`：`length()==0 → null` 否则写回 `v6d.k` 回 MAIN。
- `dih.g` PASSWORD_ENTRY 屏：Password 标题 + "Protect your
  PDF with a password." 副题 + Enter/Confirm 双密码框 +
  条件 mismatch 错误。
- `kw1`：Remove 仅 `k!=null` 渲染；Save `enabled=draft>0`。
- `kv1` Save 点击：draft==confirm 且非空 → `b7d.o(draft)`，
  否则 mismatch 置位。
- `zy7` 主屏 Password 行：`k!=null` → On 否则 Off。
- `strings.xml`：九个 `ui_share__password_*` 键。

## Harmony 实现

- `EditorToolbar.ets`：`sharePassword`（v6d.k）+ 三草稿态；
  MAIN 屏 Password 行（On/Off + 点击进屏回填）；`password`
  屏（‹/标题/Remove(仅已设)/Save(空 no-op；不一致→mismatch；
  一致→写回)/副题/双 `InputType.Password`/红字）；onDisappear
  连带清密码态；`onSharePdf(pageIndexes, password)`。
- `NotePage.ets`：`shareNoteAsPdf` 增 password 形参透传。
- `PagePdfExporter.ets`：`exportPdf(..., password?)`；非空时
  `encryptPdfFile` = PDFKit `loadDocument`→`setPdfPassword`→
  `saveDocument`→`release` 产出加密副本作保存源；双临时文件
  finally 清理；失败抛错不静默。
- 字符串：九键双语。

## 适配差异（文档化）

1. 空 draft 点击 Save = no-op（原版按钮禁用等价）。
2. `InputType.Password` + 回填替代 Compose 密码键盘字段。
3. 加密为 PDFKit 二次加密独立临时文件（语义等价管线内加密）。
4. 密码仅 PDF 行消费（原版同）；include_* 开关另组登记。

## fail-closed 保留

- `v6d.i`/`v6d.j`（include_recording/include_background）、
  多笔记分享、LINK 格式——登记后续。

## 验收

- `d05-original-share-pdf-password.mjs`：29/29。
- `d05-original-editor-share/-page-range/-pdf/-page-subset/
  -page-image` 针脚更新后全绿。
- 全量 Desktop Replay、clean + `note@ohosTest` + `note@default`
  构建全绿。

## 变更文件

- 修改：`note/src/main/ets/ui/editor/EditorToolbar.ets`、
  `note/src/main/ets/ui/editor/NotePage.ets`、
  `note/src/main/ets/data/PagePdfExporter.ets`、
  `note/src/main/resources/base/element/string.json`、
  `note/src/main/resources/zh_CN/element/string.json`、
  `docs/migration/replays/d05-original-editor-share.mjs`、
  `docs/migration/replays/d05-original-share-page-range.mjs`、
  `docs/migration/replays/d05-original-share-pdf.mjs`、
  `docs/migration/replays/d05-original-share-page-subset.mjs`、
  三份跟踪文档。
- 新增：`docs/migration/replays/d05-original-share-pdf-password.mjs`、
  `docs/migration/evidence/phase-671-original-share-pdf-password.md`、
  `docs/migration/adr/ADR-0638-original-share-pdf-password.md`、
  本报告。
