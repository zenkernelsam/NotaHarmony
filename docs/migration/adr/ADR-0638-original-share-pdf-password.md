# ADR-0638 — 原版分享面板 PDF 密码保护（v6d.k / r6d.PASSWORD_ENTRY）

日期：2026-09-24
状态：已实施（含 4 项文档化适配；include_* 开关/多笔记分享/
LINK 继续登记）

## 决策

为分享面板迁移原版的 PDF 导出密码能力：`sharePassword:
string | null`（null=Off，对应 `v6d.k`）+ 面板内第三屏
`password`（对应 `r6d.PASSWORD_ENTRY`）+ 主屏 Password 行
（On/Off，对应 `zy7` case17）+ 录入屏双密码框 + mismatch +
Save/Remove（对应 `dih.g`/`kw1`/`kv1` 语义）；导出侧
`onSharePdf`/`shareNoteAsPdf`/`exportPdf` 增 `password` 形参，
非空时经 `pdfService.PdfDocument.setPdfPassword` 对产物加密。

## 证据锚点

`v6d.java`（`String k` 密码 null=关）、`r6d.java`
（PASSWORD_ENTRY 屏）、`b7d.java`（`o(str)`：`length()==0
→null`）、`dih.java`（密码屏：标题/副题/双密码框/mismatch
条件渲染）、`h32.java`（enter/confirm 标签）、`zy7.java`
（主屏 On/Off 行）、`kw1.java`（Remove 仅 k!=null、Save
enabled=draft>0）、`kv1.java`（draft==confirm && 非空 →
`b7d.o`，否则 mismatch）、`strings.xml`（九个 ui_share__
password_* 键）、Harmony `@kit.PDFKit`（`PdfDocument.
setPdfPassword`）。详见 `docs/migration/evidence/
phase-671-original-share-pdf-password.md`。

## 连带修正

- `d05-original-editor-share/-page-range/-pdf/-page-subset`
  四个既有 fixture 的 `onSharePdf` 针脚同步更新为
  `(pageIndexes, password)` 双参签名。

## 文档化适配（非 fail-closed）

1. 空 draft 点击 Save 为 no-op——原版按钮禁用等价（`b7d.o("")`
   的 null 分支在 UI 不可达）。
2. `InputType.Password` + 进屏回填替代 Compose `e7j.a` +
   `y7a` 密码键盘。
3. 加密由 PDFKit 对手写 PDF 1.4 产物二次加密为独立临时文件
   （load→setPdfPassword→save→release），语义等价原版管线内
   加密；加密失败不静默降级——抛错走 `export_failed`。
4. 密码仅作用于 PDF 行——原版 `v6d.k` 亦仅 PDF 消费；
   `v6d.i`/`v6d.j` include_* 开关为另一组选项，继续登记。

## fail-closed 保留

- `v6d.i`/`v6d.j`（include_recording / include_background，
  `fw2.java`）、多笔记分享（`b7d(List noteIds)`）、LINK 格式
  —— 登记后续。

## 验收

- 专项 `d05-original-share-pdf-password.mjs` 29/29 绿；五个既有
  分享 fixture 更新后全绿。
- 全量 Desktop Replay、clean + note@ohosTest + note@default
  双 HAP 构建全绿。
