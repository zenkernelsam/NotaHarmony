# Phase 682 — 原版 u49/mw3 空笔记动作面移植

## 范围

`ac4` 旗标清扫的延续：P680 登记的空笔记 Scan 入口实为更大的原版表面
——`u49`/`mw3` 空笔记动作面：笔记无内容时正文区显示
Record → Import → Scan(ac4.a0) → Capture 四动作卡，全部作用于当前
笔记。本期完整移植（非 fail-closed）。

## 原版行为（证据见 phase-682 evidence）

- `mw3.java` case0：`p40.b` 四卡——record_mic_outline+record_audio
  （录音入口合并 function0/function1）、import_new_note+import_file、
  zA 门内 docscan+scan、function4 非空才显示
  capture_screen_content+capture_and_add。
- `u49.java`：`zA = lc4.a(ac4.a0)` → `p40.a(…, zA)` 分发；
  `empty_note__scan_failed` 失败串。
- `strings.xml`：`empty_note__*` 五串，scan_failed 含 GMS 提示。

## Harmony 实现

- `NotePage.ets`：
  - `refreshEmptyNoteActions` 以 `getPageElementCounts` 总数为 0 判定
    空笔记；初始载入/可撤销变更/导入成功/扫描成功后刷新；失败
    fail-closed。
  - 画布 `Stack(alignContent=Bottom)` 底部四 `EmptyNoteActionChip`；
    `photoImportLeaseActive` 时隐藏整面。
  - Record→`startRecording`；Import→lease+`importFileIntoCurrentNote`；
    Scan→`docScanAvailable` 门 + `bindContentCover` 全屏
    `DocumentScanner`（DOC/PDF/50/不分享）；Capture→lease+
    `cameraCaptureSignal++`（恒显示，对齐回调存在语义）。
  - `scanIntoCurrentNote`：`importScannedIntoNote` 并入当前笔记 →
    重载页面 + 重评估 + toast；200/–1/其他 → 导入/静默/失败 toast。
- `NoteImporter.ets`：`importScannedIntoNote` 薄封装
  `importPickedFilesIntoNote`（qv5 AddToExistingNote 语义）。
- 资源：`empty_note_*` 五串 base+zh。

## 等价与差异

- Scan 卡门控：`canIUse(DocScan syscap)` 等价 `lc4.a(ac4.a0)`。
- Capture 恒显示：Harmony 相机入口恒可用，等价「回调非空即显示」。
- 差异（ADR-0649）：卡面无图标（文本 chip）、scan_failed 文案去 GMS
  尾句、空判定为异步持久化计数。

## 验证

- Replay：`d02-original-empty-note-actions.mjs` 39 项全绿；
  全量套件全绿（无既有 fixture 失效）。
- 构建：`note@default` assembleHap BUILD SUCCESSFUL；
  `note@ohosTest` clean assembleHap 见提交记录。
- 真机/模拟器：未验证（约束内）；DocScan 实机项沿用 P680 登记。

## 涉及文件

- `note/src/main/ets/ui/editor/NotePage.ets`
- `note/src/main/ets/data/NoteImporter.ets`
- `note/src/main/resources/{base,zh_CN}/element/string.json`
- `docs/migration/replays/d02-original-empty-note-actions.mjs`
- `docs/migration/evidence/phase-682-original-empty-note-actions.md`
- `docs/migration/adr/ADR-0649-original-empty-note-actions.md`
- 本报告 + 三份跟踪文档
