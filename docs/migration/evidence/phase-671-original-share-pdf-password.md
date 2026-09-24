# Phase 671 — 原版分享面板 PDF 密码保护证据

日期：2026-09-24
对应 Replay：`docs/migration/replays/d05-original-share-pdf-password.mjs`

## 原版证据（decompiled_1.0.3）

### 密码状态与屏态

- `sources/defpackage/v6d.java` —— 分享面板不可变状态：
  `public final String k` = PDF 密码，**null = 关**（另有 `l` 页
  集合 / `m` 页数 / `n` 屏态 / `o` 缩略图映射等字段）。
- `sources/defpackage/r6d.java` —— 屏态枚举：
  `MAIN` / `PAGE_SELECTION` / `PASSWORD_ENTRY`。
- `sources/defpackage/b7d.java` —— `o(String str)`：
  `str.length() == 0 ? null : str` 写回 `v6d.k` 并回 MAIN
  （`r6d.I` 即 MAIN 入参）。

### PASSWORD_ENTRY 屏渲染（dih.g / h32 / kw1 / kv1）

- `sources/defpackage/dih.java` —— PASSWORD_ENTRY 屏组合：
  `ui_share__password` 标题 + `ui_share__password_subtitle`
  副题 + 两个 `e7j.a` 密码输入框（`y7a`/`nn6` 密码键盘选项，
  文本取自 `gl8` remember 态 `gl8Var4`=draft /
  `gl8Var5`=confirm）+ 条件渲染
  `ui_share__password_mismatch`（`gl8Var2` 布尔为 true 时显）。
- `sources/defpackage/h32.java` —— 字段标签：
  `ui_share__password_enter` / `ui_share__password_confirm`。
- `sources/defpackage/kw1.java` —— 屏顶按钮：
  `Remove`（`ui_share__password_remove`）**仅 `v6d.k != null`
  时渲染**；`Save`（`ui_share__password_save`）按钮
  `enabled = draft.length() > 0`。
- `sources/defpackage/kv1.java` —— Save 点击（case 2）：
  `ba6.o(draft, confirm) && draft.length() > 0` →
  `ix4Var.invoke(draft)`（→ `b7d.o`），否则 mismatch 标志
  `gl8Var.setValue(TRUE)`。

### 主屏密码行（zy7）

- `sources/defpackage/zy7.java` —— 主屏 Password 行：
  `v6d.k != null` → `ui_share__password_on` 否则
  `ui_share__password_off`。
- `strings.xml`：`ui_share__password`="Password"、
  `_subtitle`="Protect your PDF with a password."、
  `_enter`="Enter password"、`_confirm`="Confirm password"、
  `_mismatch`="Passwords do not match"、`_on`="On"、
  `_off`="Off"、`_save`="Save"、`_remove`="Remove"。

### Harmony 加密 API（SDK 证据）

- `@kit.PDFKit` → `pdfService.PdfDocument`：
  `loadDocument(path): ParseResult`、`setPdfPassword(password):
  boolean`、`saveDocument(path): boolean`、`releaseDocument()`、
  `isEncrypted(path)`、`removeSecurity()`。`ParseResult` 枚举
  `PARSE_SUCCESS = 0`。

## Harmony 对齐

- `EditorToolbar.ets`：
  - `@State sharePassword: string | null`（v6d.k 等价，
    null=Off）+ `sharePasswordDraft`/`sharePasswordConfirm`/
    `sharePasswordMismatch` 三个 PASSWORD_ENTRY 屏草稿态。
  - MAIN 屏新增 Password 行（页范围行之下、格式行之上）：
    `v6d.k!=null` → `share_password_on` 否则 `_off`；点击进
    `password` 屏并以既有密码回填双框。
  - `buildSharePassword`（r6d.PASSWORD_ENTRY 等价）：‹ 返回
    MAIN + `share_password` 标题 + Remove（仅 `sharePassword
    !== null` 渲染，点击清空回 MAIN）+ Save（`draft.length>0`
    时高亮；点击：空 draft → no-op 等价禁用按钮；
    draft!=confirm → `sharePasswordMismatch=true`；一致 →
    写 `sharePassword` 回 MAIN）+ `share_password_subtitle`
    + 两个 `InputType.Password` 框 + mismatch 红字。
  - `bindSheet.onDisappear`：屏态 + 页集合 + 全部密码态重置
    （v6d 随 sheet 重建语义延续）。
  - 分发：`onSharePdf(pageIndexes, password)`；
    `onShareImage`/`onShareNote` 不消费密码（原版
    `ui_share__password_*` 仅在 PDF 路径生效——密码行是
    PDF 专属选项，NOTE 归档与图像导出不参与）。
- `NotePage.ets`：`shareNoteAsPdf(pageIndexes, password)`；
  `password !== null ? password : undefined` 传入导出器。
- `PagePdfExporter.ets`：`exportPdf(..., password?: string)`：
  临时 PDF 写出后 `needsPassword` 时经 `encryptPdfFile` —
  `PdfDocument.loadDocument(tmp)` → `setPdfPassword(pwd)` →
  `saveDocument(encrypted)` → `releaseDocument()` — 生成加密
  副本作为保存对话框的拷贝源；两个临时文件均 finally 清理；
  任一步失败抛错走 catch → `export_failed` toast（不静默降级）。
- 字符串：九个 `share_password*` 键 base/zh_CN 双语新增。

## 适配差异（文档化）

1. 原版 `o("")` 的空串→null 分支在 UI 不可达（Save 禁用）；
   Harmony 同样：空 draft 点击为 no-op（禁用等价），Remove
   承担清空职责。
2. 原版密码屏字段为 Compose `e7j.a` + `y7a` 密码键盘；
   Harmony 用 `TextInput` `InputType.Password` + 明文回填
   （进屏时 draft/confirm 双框同填既有密码）。
3. 加密落点：原版在 PDF 生成管线内加密；Harmony 在手写
   PDF 1.4 写出后由 PDFKit 二次加密为独立临时文件——产物
   语义等价（保存对话框只见到加密副本）。
4. 密码不作用于 JPG/PNG/NOTE 行（原版 `v6d.k` 亦仅 PDF 消费；
   其余格式的导出选项走 `v6d.i/j` include_* 开关——仍登记）。

## fail-closed 保留

- `v6d.i`/`v6d.j`（include_recording / include_background
  开关行，`fw2.java` 渲染）、多笔记分享（`b7d(List noteIds)`）、
  LINK 格式 —— 继续登记后续 Phase。
