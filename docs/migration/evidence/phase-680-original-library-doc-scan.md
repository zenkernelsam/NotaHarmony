# Phase 680 — 原版 LIBRARY_DOC_SCAN（文档扫描）证据

## 原版证据（decompiled_1.0.3）

### 旗标

- `ac4.java`：`a0 = LIBRARY_DOC_SCAN(15)`，已发布通道。

### 入口（资料库「+」展开菜单）

- `cd.java` case 0：`cwi.b` 图标行列表——`feature_library__import` →
  `feature_library__templates`（`ac4.K0` 门控）→ `feature_library__docscan`
  （`ac4.a0` 门控，`ui_fileimport__docscan` 图标）。

### 扫描→笔记管线

- `zvi.java`：取 `feature_library__scanned_document_title` 与
  `feature_library__doc_scan_failed`；组装 `wc`/`vc` 回调。
- `ga7.java`/`cd.java`：`sa7` 方法引用指向
  `ib7.onDocScanned(Landroid/net/Uri;Ljava/lang/String;Lkotlin/jvm/functions/Function1;Lkotlin/jvm/functions/Function0;)V`
  与 `pk9` 同名方法——签名 = (扫描 Uri, 标题模板, 成功, 失败)。
- `muh.java`：`GmsDocumentScanningResult{pages=…, pdf=…}`——ML Kit 产出
  页面图 + PDF；应用侧 `onDocScanned` 消费单个 Uri（PDF 路径）。
- 成功后跳新笔记（`onShowNoteInFolder`）；失败弹
  `doc_scan_failed`（"Couldn't create note from scan. Please try again."）。

### 空笔记页 Scan（登记未覆盖）

- `u49.java`：`feature_note__empty_note__scan`/`_scan_failed`——空笔记页
  扫描入口把结果并入**当前**笔记。该空笔记快捷动作面在 Harmony 侧
  尚不存在，本 Phase 只实现资料库入口，见 ADR-0647。

## Harmony 实现

- `LibraryPage.ets`
  - `canIUse('SystemCapability.AI.Component.DocScan')` → `docScanAvailable`
    ——原版 `lc4.a(ac4.a0)` 旗标门控的等价物：无组件能力的设备不渲染
    「Document Scan」入口（fail-closed）。
  - FAB 展开菜单尾位新增 `docscan` chip → `docScanOpen = true`。
  - `.bindContentCover` 全屏承载 `DocumentScanner`（VisionKit 约束：
    扫描界面不得被遮挡）；`onWillDismiss` 下滑关闭 = 取消。
  - `DocumentScannerConfig`：`supportType=[DOC]`、`saveOptions=[PDF]`
    （对齐原版 PDF 消费路径）、`isShareable=false`、`maxShotCount=50`
    （原版 ML Kit 上限未解出，取 SDK 上限）。
  - `onDocScanResult`：`code=200` 成功 → `importScannedAndOpen`；
    `code=-1` 用户取消（静默）；其余（含 `1008601001` uri 无效）→
    `doc_scan_failed` toast。
  - `importScannedAndOpen`：标题 =
    `scanned_document_title` + `formatTime(now)`（原版 `%1$s` 占位），
    `NoteImporter.importScannedDocument(uris, title, currentFolderId)` →
    `vm.loadNotes` 刷新 → `router.pushUrl` 打开新笔记。
- `NoteImporter.ets`
  - 新增 `importScannedDocument(uris, title, folderId, passwordPrompt)` —
    薄封装既有 `importFilesIntoSingleNewNote`（原版 sv5
    CreateSingleNewNote 语义：单篇笔记 + 逐文件并入；全部失败清掉空笔记）。

## 差异登记

- 原版 ML Kit 由 Google Play services 提供；Harmony 用 VisionKit
  `DocumentScanner` 组件，能力等价（自动裁切/增强/编辑/多页）。
- 原版扫描→笔记只传一个 Uri（PDF）；Harmony `saveOptions=[PDF]` 同形。
- 原版标题占位 `%1$s` 内容未解出（启动器 `wc.invoke` 未反编译）；
  采用与库内 `formatTime` 一致的 `M/D H:MM` 时间戳。
- 空笔记页 Scan 入口（`u49`）未覆盖：该快捷动作面整体未建，登记为
  后续 Phase 候选。

## Replay

- `docs/migration/replays/d02-original-library-doc-scan.mjs`（27 断言）。
