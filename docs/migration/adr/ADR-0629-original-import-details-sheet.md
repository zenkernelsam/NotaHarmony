# ADR-0629 原版导入详情页（ou5/zvh.a：目的地选择 + 逐文件题覆盖）

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：662
- 接续：ADR-0624（Add Files）、ADR-0625（多选导入）、ADR-0627（加密
  PDF 密码——`zvh.e` 同一 sheet 的密码分区）、ADR-0628（共享入口）
- 证据：`docs/migration/evidence/phase-662-original-import-details-sheet.md`

## 背景

原版选择器返回文件列表后并不直接导入，而是弹出 `zvh.a` 共享导入
详情 sheet（宿主 `ou5` ViewModel）：文件行 + `tv5` 三态目的地
（`qv5` 并入既有笔记 / `sv5` 新建单篇 / `rv5` 各自成篇）+
`fu5` 事件（`wt5` 逐文件题、`tt5` 搜索、`st5` 选笔记、`yt5` 选
文件夹、`zt5` 确认、Dismiss 取消）。编辑器（`u49`）、库（`zvi`）、
共享入口（`ib0`）三处复用同一 sheet；编辑器上下文 `ttf` 预置为
当前笔记 → 默认 `qv5(当前笔记)`。

Harmony 此前（Phase 652-658）选择器直接物化：库上下文多选恒
`rv5`、编辑器上下文恒 `qv5(当前笔记)` —— 无法选目的地、无法改题、
sv5 路径完全缺失。这是导入党系最后一块登记偏差（ADR-0625 曾标注
「详情页未实现」）。

## 决定

1. **契约层**：`NoteImporter` 新增 `ImportFileDescriptor` /
   `ImportDestination` / `ImportPlan` / `ImportSheetPrompt` 类型。
   `sheetPrompt` 为可选回调 —— 未提供的既有调用方保持 Phase 658
   默认语义（向后兼容，BackupPage 恢复路径同理不经 sheet）。
2. **分发层**：`dispatchImportPlan` 对齐 `ou5.l` 三分支：
   `EXISTING_NOTE → importPickedFilesIntoNote`（qv5）；
   `SINGLE_NOTE → importFilesIntoSingleNewNote`（sv5：
   `createNoteWithMeta` 建篇 → 逐文件并入 → 全败则 `removeFailedImport`
   清场）；`SEPARATE_NOTES → importPickedFilesStandalone(...,
   titleOverrides)`（rv5）。
3. **题覆盖管道**：四个 standalone 物化方法加可选 `titleOverride`
   （`!== undefined && length > 0` 生效，PDF 回退 `pdfImportTitle`、
   其余回退文件词干）；`normalizeImportTitleOverride` =
   trim + 截 200 字符，对齐 `o1` 中 `lvd.b1(200, lvd.d1(title))`。
   into-note 路径不消费题覆盖（原版 wt5 只影响 rv5 的 per-note 题表）。
4. **共享对话框** `ImportDetailsSheet`：文件行（emoji+名称+大小）、
   三枚目的地 chip、逐行题输入（rv5）、题+文件夹（sv5/rv5）、
   搜索+笔记列表（qv5）、导入/取消。遮罩取消 → `null`。
5. **接线**：`LibraryPage`（`importFromFile` + `importSharedUris`）与
   `NotePage`（`importFileIntoNoteFromPicker`，`context='note'` 预选
   当前笔记）。笔记列表用 `getAllNotes()`（原版搜全库）、文件夹用
   `getAllFolders()`。
6. **顺带修复**：`CustomDialogController.cancel` 回调补 `resolve(null)`
   —— 遮罩关闭原本会使密码/详情 Promise 悬挂、导入互斥锁永久占用；
   对齐原版 Dismiss=取消语义。

## 差异与 fail-closed

- `.note` 归档在 sv5/qv5 路径下并入笔记的语义上游不透明，维持
  fail-closed（该项 UNSUPPORTED/CORRUPTED，不影响同批其余文件）。
- sheet 文件夹 chips 限 8 项、笔记列表限显 60 条（原版无界）——
  UI 预算差异，语义无损。
- 原版 `ou5.l` 对 sv5 亦按文件循环起协程；Harmony 先建篇再逐文件
  并入，语义等价。

## 验证

- `d05-original-import-details-sheet.mjs`：53 断言（证据 + 契约 +
  分发 + 题覆盖 + 页面接线 + 字符串）。
- 全量 Desktop Replay 套件与双 HAP 构建见 Phase 662 report。
