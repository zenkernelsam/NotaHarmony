# Phase 674 证据 — 原版多笔记分享（v6d.a + s6d _multi + 多文件交付）

日期：2026-09-24
前置：Phase 673（`37af2772`）

## 原版证据（decompiled_1.0.3）

### 多笔记分享态（b7d.java / v6d.java）

- `b7d(List noteIds, ...)`：构造器要求 noteIds 非空；
  `P` = 首笔记 id；`v6d.a` = `list.size() > 1` ——
  **isMultiNote**。
- 默认格式：`list.size() > 1 ? s6d.PDF : s6d.LINK` ——
  多笔记默认 PDF。
- `b7d.i`（导出协程）：消费整个 `v6d`（格式 c、bg i、
  rec j、密码 k、页集 l），经 `ml4.m`/`ya9.m` 产出
  `y09`（分析元数据）；导出后 `qp8.c(pj(...))` 记分析
  事件（`includesRecordings`/`includesBackground`/
  `includesPageRange`），LINK 格式直接跳过导出。

### 面板结构（dih.java / s6d.java / strings.xml）

- `dih.a`（顶层分派）：`if (v6dVar.a) { /* 空 */ } else {
  e(v6dVar, ...) }` —— **页范围 composable `e()` 在多笔记
  态整体不渲染**。
- `dih.h`（PDF 选项）：同样的 `v6dVar.a` 短路跳过页范围
  `e()`，但 **密码行与 include_* 双开关保留**。
- `dih.d`（NOTE）：`include_recording` 开关；`dih.a`
  （JPG/PNG）：`include_background` 开关；`dih.b`（LINK）：
  账号域权限行。
- `s6d`：LINK/PDF/NOTE/JPG/PNG 枚举；chip/action 标签分
  单复数两组。
- `strings.xml`：
  `ui_share__chip_{pdf,note,jpg,png}_multi`（"PDFs"/"Notes"/
  "JPGs"/"PNGs"）、`ui_share__action_*_multi`（"Share PDFs"/…）、
  `ui_share__multi_subject`="Notes"、
  `ui_share__subtitle_multi`="Share a PDF, a note or an image."。
- `zy7` 密码行 On/Off → `dih.g` PASSWORD_ENTRY（草稿+确认，
  `kw1`：draft 空时 Save 禁用；`kv1`：仅相等且非空时回写）。
  多笔记 PDF 保留密码行——同一密码施加到每个导出 PDF。

### 底栏 Share 入口（l05/fj9/gj9 + lc4）

- 多选底栏含 Share 图标，受 `lc4.a(ac4.L)` 功能旗标门控。
- Phase 673 登记为 fail-closed；本期交付。

### 多文件交付（ExportFileProvider.java）

- `ExportFileProvider extends ye4`（FileProvider）：
  `openFile` 暴露 `exports/<name>` 内容 URI —— 导出文件经
  content URI 挂入 `ACTION_SEND_MULTIPLE`/`ACTION_SEND`
  意图，由系统分享面板交付到任意目标。

## Harmony 落点

`note/src/main/ets/ui/library/LibraryPage.ets`：

- `MultiSelectActionBar` 增 Share 按钮（首位，lc4 旗标交付），
  `enabled = count>0 && !busy && !shareBusy`；点击重置
  v6d 默认（PDF + bg=false + rec=true + 密码清空）并开
  `multiShareOpen`。
- `MultiShareSheet`（bindSheet，SheetSize.MEDIUM）：
  `share_multi_subject`/`share_multi_subtitle` 头；
  `MultiShareFormatChip` 行（pdf/note/jpg/png 用 _multi
  标签，link 置灰 `.enabled(false)` + `opacity 0.4` 吞点）；
  分格式选项（PDF=bg+rec 开关 + `MultiSharePasswordRow`；
  NOTE=rec；JPG/PNG=bg；LINK=unavailable 文案）——
  **无页范围行（v6d.a）**；
  Cancel + `multiShareActionLabel()`（_multi action 标签）
  动作行。
- `MultiSharePasswordRow`：On/Off 行 → 内联 PASSWORD_ENTRY
  （draft+confirm PasswordInput + mismatch + Save/Remove，
  draft 空禁用 Save——kw1/kv1 语义）。
- `multiShare()`：
  - `.note`：`NoteExporter.exportNote(id, includeRecording)`
    → `<title>.note`（utd=FILE）。
  - PDF：`PageRepositoryImpl.getPages(id)` 全页 →
    `ThumbnailRenderer.renderPageExport` → JPEG →
    `buildPdf` → `<title>.pdf`；密码非空 →
    `encryptPdfFile`（v6d.k 逐笔记复用，utd=PDF）。
  - JPG/PNG：全页栅格化 → `page_NNN.<ext>` 打进
    `<title>_pages.zip`（utd=ZIP_ARCHIVE）——Phase 644
    整册图像 zip 的同构适配。
  - `systemShare.SharedData`：`records[0]` 构造 + 其余
    `addRecord`；`getWant` → `context.startAbility` ——
    **ACTION_SEND_MULTIPLE 的 Harmony 等价物**。
  - 成功 → `export_done` toast + 关面板；失败 →
    `multi_share_failed`。
- `PagePdfExporter.encryptPdfFile` 改为 `export` 供复用。

## 登记差异

1. **交付机制**：原版经 FileProvider content URI +
   `ACTION_SEND_MULTIPLE` 由用户任选目标应用；Harmony 经
   `systemShare.SharedData` 多 `SharedRecord`（`fileUri`
   sandbox URI + utd）拉起系统分享面板——同一"多文件交
   系统面板分发"语义，面板细节由系统实现。
2. **图像扇出**：原版逐页产出独立 JPG/PNG 文件；Harmony
   每笔记打包 `<title>_pages.zip`（`page_NNN.<ext>` 序），
   与 Phase 644 单笔记整册图像导出的 zip 适配一致——
   避免 N×M 条分享记录失控。
3. **密码逐 PDF 复用**：`dih.h` 多笔记保留密码行，原版
   将 `v6d.k` 施加于产出 PDF；Harmony 同语义，每 PDF 经
   `encryptPdfFile` 加密。
4. **临时文件生命周期**：产物写入 `tempDir/multishare_*`
   交系统分享面板读取；不主动删除（分享面板异步消费），
   由系统 tempDir 清理接管。
5. `systemShare` 需 `SystemCapability.Collaboration.SystemShare`
   （API 12+，`getWant` API 12）；目标 SDK 6.0.1(21)。未做
   设备运行时验证（按约束），若目标设备缺 syscap 则
   `getWant` 失败走 `multi_share_failed`——fail-closed。
