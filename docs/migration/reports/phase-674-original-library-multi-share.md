# Phase 674 — 原版多笔记分享（v6d.a + 多文件系统分享）

日期：2026-09-24
前置：Phase 673（`37af2772`）

## 目标

交付 Phase 673 登记的 `lc4.a(ac4.L)` 旗标 Share 图标：
多选底栏增 Share 入口 → `v6d.a`（isMultiNote）形态的
分享面板 → 逐笔记按格式产出文件 → 系统分享面板多文件
交付（`ACTION_SEND_MULTIPLE` 等价物）。

## 原版行为（证据：b7d/v6d/dih/s6d/zy7/strings/ExportFileProvider/l05）

- `b7d`：`v6d.a = noteIds.size()>1`；默认格式多笔记 →
  PDF（单笔记 → LINK）；`b7d.i` 导出协程消费整个 `v6d`。
- `dih`：`v6d.a` 短路页范围 `e()` composable（顶层与
  `dih.h` 两处）；PDF 选项保留双开关 + 密码行；NOTE=
  录音开关；JPG/PNG=背景开关；LINK=账号域权限行。
- `s6d`/`strings`：`_multi` chip（PDFs/Notes/JPGs/PNGs）
  与 `action_*_multi`（Share PDFs/…）标签；
  `multi_subject`="Notes"、`subtitle_multi`="Share a PDF,
  a note or an image."。
- `zy7`/`dih.g`/`kw1`/`kv1`：密码行 On/Off → 草稿+确认，
  空草稿禁 Save、仅相等且非空回写。
- `ExportFileProvider`：FileProvider 暴露 `exports/`
  content URI，`ACTION_SEND_MULTIPLE` 交付。
- `l05` 底栏 Share 图标受 `lc4.a(ac4.L)` 门控——本期交付。

## Harmony 实现

`LibraryPage.ets`：

- `MultiSelectActionBar` 增 Share 按钮（首位），点击重置
  v6d 默认（PDF/bg=false/rec=true/密码空）并开
  `multiShareOpen`。
- `MultiShareSheet`（bindSheet MEDIUM）：subject/subtitle
  头 + `MultiShareFormatChip` 行（_multi 标签、LINK 置灰）
  + 分格式选项（**无页范围——v6d.a**；PDF=双开关+密码行、
  NOTE=rec、JPG/PNG=bg、LINK=unavailable）+ Cancel/
  `action_*_multi` 动作行。
- `MultiSharePasswordRow`：On/Off → 内联 draft+confirm
  PasswordInput + mismatch + Save（空草稿禁用）/Remove。
- `multiShare()`：
  - `.note` = `exportNote(id, includeRecording)`；
  - PDF = `getPages(id)` 全页 → `renderPageExport` →
    JPEG → `buildPdf` → 可选 `encryptPdfFile`；
  - JPG/PNG = 全页图像 → `page_NNN.<ext>` →
    `<title>_pages.zip`（P644 同构适配）；
  - `systemShare.SharedData` 多记录（utd + `fileUri` URI）
    → `getWant` → `startAbility`；成功 `export_done` +
    关面板，失败 `multi_share_failed`。
- `PagePdfExporter.encryptPdfFile` 导出复用。
- 字符串：base+zh_CN 增 `share_multi_subject/subtitle`、
  `share_chip_*_multi` ×4、`share_action_*_multi` ×4、
  `multi_share_failed`。

## 登记差异

1. 交付：FileProvider+`ACTION_SEND_MULTIPLE` →
   `systemShare` 多 `SharedRecord` + 系统分享面板。
2. 图像：逐页独立文件 → 每笔记 `page_NNN.<ext>` zip
   （P644 同构）。
3. 密码逐 PDF 复用（与原版 `v6d.k` 语义一致）。
4. 临时文件交 tempDir 生命周期（面板异步消费）。
5. `systemShare` 需 `Collaboration.SystemShare` syscap；
   未做设备验证，缺失走 `multi_share_failed` fail-closed。

## 验证

- `d02-original-library-multi-share.mjs`：38/38。
- 全量 Desktop Replay：559/559。
- `note@ohosTest` + `note@default` 双 HAP clean 构建成功。
- 无模拟器/真机/Hypium（按约束）。

## 后续登记

- LINK 分享保持 fail-closed（`dih.b` 账号域权限行不可迁移）。
