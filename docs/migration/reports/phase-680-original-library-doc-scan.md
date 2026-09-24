# Phase 680 — 原版 LIBRARY_DOC_SCAN（资料库文档扫描）移植

## 范围

`ac4` 旗标清扫中确认 `LIBRARY_DOC_SCAN(15)`（`ac4.a0`）为已发布且未覆盖的
本地功能：资料库「+」菜单「Document Scan」→ ML Kit 扫描 → 扫描产物建
新笔记并打开。HarmonyOS VisionKit `DocumentScanner` 组件能力等价，本期
完整移植（非 fail-closed）。

## 原版行为（证据见 phase-680 evidence）

- `cd.java` case 0：「+」展开菜单 import → templates（K0 门控）→
  docscan（`ac4.a0` 门控，`ui_fileimport__docscan` 图标）。
- `zvi.java`：标题 `feature_library__scanned_document_title`、失败
  `feature_library__doc_scan_failed`。
- `ga7.java`/`cd.java`：`onDocScanned(Uri, String, Function1, Function0)` —
  扫描 URI + 标题模板 → 成功跳笔记 / 失败 toast。
- `muh.java`：`GmsDocumentScanningResult{pages, pdf}` —— 应用侧消费 PDF。
- `u49.java`：空笔记页 Scan 入口（结果并入当前笔记）——登记未覆盖。

## Harmony 实现

- `LibraryPage.ets`：`canIUse(DocScan syscap)` 等价旗标门控；FAB 尾位
  `docscan` chip；`bindContentCover` 全屏 `DocumentScanner`；配置
  `DOC` 类型 + `PDF` 产出 + `maxShotCount=50` + `isShareable=false`；
  结果码 200/–1/其他 → 导入并打开 / 静默 / `doc_scan_failed` toast；
  新笔记标题 `scanned_document_title` + `M/D H:MM` 时间戳，落当前文件夹。
- `NoteImporter.ets`：`importScannedDocument` 薄封装
  `importFilesIntoSingleNewNote`（sv5 CreateSingleNewNote 语义）。
- 资源：`docscan`/`scanned_document_title`/`doc_scan_failed`（base+zh）。

## 验证

- 新增 Replay `d02-original-library-doc-scan.mjs`：27 断言。
- 全量 Desktop Replay：564/564 全绿。
- `note@ohosTest`、`note@default` clean 构建成功（无新增编译错误）。
- ADR-0647 登记差异与未覆盖面（空笔记页 Scan）。
