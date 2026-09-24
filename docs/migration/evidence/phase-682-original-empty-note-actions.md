# Phase 682 证据 — 原版 u49/mw3 空笔记动作面

## 原版证据（decompiled_1.0.3）

| 文件 | 证据 |
|------|------|
| `sources/defpackage/mw3.java` | case0：`p40.b` 四动作卡。L54-62：`ui_designsystem__record_mic_outline` + `feature_note__empty_note__record_audio`，`function0`/`function1` 经 `uz4Var.g(...)` 判可合并为单录音入口（`new sc(function0, function1, 5)`）。L63：`ui_designsystem__import_new_note` + `empty_note__import_file`（function2）。L66：`zA` 门内 `ui_fileimport__docscan` + `empty_note__scan`（function3）。L72-77：`function4 != null` 才显示 `ui_designsystem__capture_screen_content` + `empty_note__capture_and_add`。 |
| `sources/defpackage/u49.java` | L1752：`final boolean zA = lc4.a(ac4.a0);` — Scan 卡沿用 LIBRARY_DOC_SCAN 旗标。L1756：失败串 `feature_note__empty_note__scan_failed`。L1824：`p40.a(0, uz4Var7, null, function18, function7, (Function0) objS49, function16, function0A, zA)` — 空笔记表面分发。 |
| `resources/res/values/strings.xml` | `empty_note__capture_and_add`="Capture and add"、`__import_file`="Import"、`__record_audio`="Record"、`__scan`="Scan"、`__scan_failed`="Couldn't scan the document. Make sure Google Play services is up to date." |
| `sources/defpackage/ac4.java` | `a0 = LIBRARY_DOC_SCAN(15)`（P680 已登记）。 |

## 原版行为

- 空笔记（无内容）时正文区显示动作卡列：Record → Import → Scan → Capture。
- Record：进入录音（function0/function1 合并语义）。
- Import：文件导入当前笔记。
- Scan：`ac4.a0` 门控；ML Kit 文档扫描，结果并入**当前**笔记（区别于
  资料库「+」扫描建新笔记）；失败弹 `empty_note__scan_failed`。
- Capture：仅当相机回调（function4）非空时显示——拍照并入当前笔记。
- 卡面 = 图标 + 标签（`p40.b`）。

## Harmony 实现（本 Phase）

- `NotePage.ets`
  - `refreshEmptyNoteActions()`：`StrokePersistence.getPageElementCounts`
    （d05 页面总览同一数据源）全表元素总数为 0 → `emptyNoteActions=true`；
    计数失败 fail-closed 不显示。刷新时机：初始载入、可撤销内容变更
    （`onUndoRedoChanged`）、文件导入成功、扫描导入成功。
  - 画布 `Stack(alignContent=Bottom)` 内叠四 `EmptyNoteActionChip`
    （`CreateActionChip` 文本风格）；`photoImportLeaseActive` 时整面隐藏。
  - Record → `startRecording()`（lease 门同 onRecord）。
  - Import → `photoImportLeaseActive=true; importFileIntoCurrentNote()`
    （lease 门同 onAddFiles）。
  - Scan → `docScanAvailable`（`canIUse(SystemCapability.AI.Component.DocScan)`，
    等价 `lc4.a(ac4.a0)`）门内显示；`bindContentCover` 全屏
    `DocumentScanner`（DOC/PDF/50 页/不可分享——P680 同一契约）；
    `onDocScanResult`：200→`scanIntoCurrentNote`、-1→静默、其余→
    `empty_note_scan_failed` toast。
  - Capture → `photoImportLeaseActive=true; cameraCaptureSignal++`
    （与 Take Photo 同一 ingress lease）。Harmony 编辑器相机入口恒可用
    ——对齐原版「function4 非空即显示」。
  - `scanIntoCurrentNote`：`NoteImporter.importScannedIntoNote` →
    `importPickedFilesIntoNote`（qv5 AddToExistingNote 语义）→
    重载页面 + `pageContentVersion++` + 重评估动作面 + toast。
- `NoteImporter.ets`：`importScannedIntoNote(noteId, uris, prompt)`
  薄封装 `importPickedFilesIntoNote`。
- 资源：`empty_note_{capture_add,import,record,scan,scan_failed}`
  base+zh（`scan_failed` 尾句按 Harmony 去掉 GMS 提示——ADR-0649）。

## 有界差异（ADR-0649）

1. 原版卡面为图标+标签（`p40.b`），Harmony 用既有文本 chip 风格——
   四个媒体图标资源未建，登记为视觉差异。
2. 原版 `scan_failed` 文案提示「Google Play services 需更新」——GMS
   专属，Harmony 文案简化为「请重试」。
3. 空判定：原版以会话内模型为空为准；Harmony 以持久化快照元素总数
   为 0 为准（等价语义，异步评估）。
