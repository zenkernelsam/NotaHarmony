# Phase 654：独立文本文件导入（dv5 默认分支 / dhj.p0）

日期：2026-09-24
接续：Phase 653（独立图片文件导入）
ADR：ADR-0621
证据：`docs/migration/evidence/original-text-file-import-jadx-2026-09-24.md`
专项 Replay：`docs/migration/replays/d05-original-text-file-import.mjs`（25 项）

## 原版行为（硬证据）

- `i58.java:6`：选择器 `i58.c = new i58("*/*")`。
- `nj3.java`：`txt` 为导入类型表唯一纯文本类型。
- `dv5.java` 默认分支：`jv5.f` 复制到临时文件 → `tf4.x0(file2, ej1.a)`
  UTF-8 全文读出 → `file2.delete()` → `new tu5(o88(nj3.txt, name,
  1页, 32), strX0)`；读失败记 `Failed to read text file` 走失败路径。
- `tu5.java`：仅 `String K`；`a()` 无操作（无临时文件）。
- `yq8.java:32-34`：`uu5 instanceof tu5 → dhj.p0`。
- `dhj.java`（约 705–723）：`tu5Var.K.length() != 0` → `new te0(tu5Var, i3)`；
  否则记 `Empty text file, skipping import` → `dca.c` 无 op。
- `te0.java`：`haj.a(cxcVar, null, 1, oz9.UNBOOKMARKED, 16)` 建页 +
  `nti.g(..., 0)` 寄存器位 0 + `kci.b(null, tu5.K, null)` 文本实体。
- `kci.b`：构造 `f46` flatbuffer（字段 6 = 必填字符串，`f46.a()` 校验
  「Cannot insert empty string」；exc/qo5 均 null → 默认样式）。
- `zq9.java:21`：`f46.class → haa.INSERT_STRING`（type 8）。

## Harmony 实现（`NoteImporter`）

1. **选择器**：`fileSuffixFilters` 追加 `.txt`。
2. **分发**：图片后缀检查后追加 `.txt` → `importTextFromBytes`；
   `TextDecoder` UTF-8 解码对齐 `tf4.x0`。
3. **空文件**：空串 → `CORRUPTED` +「空文本文件，未导入」，零写库。
4. **落库**：`importMutex` 内 `createNoteWithMeta` →
   `addImportedPage`（Letter 612×792pt→mm，PLAIN/PORTRAIT/
   `originalDefaultNoteBackground()`/bookmarked=false）→
   `saveElements`（单 TEXT zIndex=0）；异常 → `removeFailedImport`。
5. **文本块**：`buildImportedTextElement` —— `textOrigin {0,0}`、
   `blockWidth = 612pt`、`blockHeight = max(40, lines×25+13)`、
   insets 5/3/5/10、fontSize 17、fontColor 黑、`corner/textWrap=0`、
   `enableCaption=false`、`resizesWidthToFitText=false`，bounds 经
   `textBlockWorldBounds`；id `imported-text-…`。
6. **标题**：复用 `imageImportTitle`（去最后后缀；空 stem →
   `'导入笔记'`）。

## 有意差异（fail-closed / 记录项）

- **块几何**：原版不携带显式位置，块几何由 cde 默认寄存器决定；
  Harmony 以「页顶 + 页宽 + 行高测量」物化等价呈现（文档化近似，
  非逐像素等价）。
- **临时文件**：原版临时文件中转；Harmony 直读 URI 字节（语义等价）。
- 其余原版类型（Office/音视频等）仍 fail-closed。

## 验证

- 专项 Replay：25/25 全绿。
- 既有回归：`d02-note-import-file-handle-lifecycle` 7/7；
  `d02-local-create-page-outbound` 计数 pin 更新为 5。
- 全量 Desktop Replay：539/539。
- `note@default` 构建成功，无新增错误（仅既有告警）。
- `note@ohosTest`/`note@default` clean HAP 构建均成功。
- 未做模拟器/真机验证（按项目约束）。

## 文件清单

- `note/src/main/ets/data/NoteImporter.ets`（+`textBlockWorldBounds`
  导入/常量/`.txt` 过滤与分发/`importTextFromBytes`/
  `buildImportedTextElement`/`isImportedTextFileName`）
- `docs/migration/replays/d05-original-text-file-import.mjs`（新增）
- `docs/migration/replays/d02-local-create-page-outbound.mjs`（pin 更新）
- `docs/migration/evidence/original-text-file-import-jadx-2026-09-24.md`
- `docs/migration/adr/ADR-0621-original-text-file-import.md`
- `docs/migration/reports/phase-654-original-text-file-import.md`
- 三份跟踪文档
