# ADR-0621 独立文本文件导入（dv5 默认分支 / dhj.p0）

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：654
- 接续：ADR-0619（PDF 导入）、ADR-0620（图片导入）
- 证据：`docs/migration/evidence/original-text-file-import-jadx-2026-09-24.md`

## 背景

原版 Import File 的纯文本分支：`dv5` 默认分支把选中的 `.txt`
（`nj3.txt`，导入类型表唯一纯文本类型）复制到临时文件后
`tf4.x0(file, ej1.a)` 按 UTF-8 全文读出并删临时文件，包装为
`tu5(string)`；`yq8.f` 路由 `tu5 → dhj.p0`：非空 → `te0`
（`haj.a` 建 UNBOOKMARKED Letter 页 + `kci.b(null, text, null)`
生成 `f46` 文本实体 → `haa.INSERT_STRING` 落 richtext 寄存器位 0）；
空文件 → 记「Empty text file, skipping import」日志 + `dca.c` 无 op。

Harmony 此前 picker 已含 `.note/.pdf`/图片后缀（Phase 652/653），
文本导入缺失；`TextBlockElement`/`textBlockWorldBounds` 与
`saveElements` 文本持久化均已存在。

## 决定

1. **选择器**：`fileSuffixFilters` 追加 `.txt`。
2. **分发**：`importFromFile` 在图片后缀检查后追加 `.txt` →
   `importTextFromBytes`；UTF-8 `TextDecoder` 解码对齐
   `tf4.x0(file, ej1.a)`。
3. **空文件**：解码为空串 → `CORRUPTED` + 「空文本文件，未导入」，
   零写库（对齐原版 log + `dca.c` 无 op）。
4. **落库**：`importMutex` 内 `createNoteWithMeta` →
   `addImportedPage`（m09.b Letter 612×792pt→mm，PLAIN/PORTRAIT/
   `originalDefaultNoteBackground()`/bookmarked=false）→
   `saveElements`（单 TEXT 元素 zIndex=0）；任一异常 →
   `removeFailedImport` 清理后 `CORRUPTED`。
5. **文本块**：`buildImportedTextElement` —— `textOrigin {0,0}`、
   `blockWidth = 612pt`（页文本寄存器横向占满页宽）、
   `blockHeight = max(40, lines×(fontSize+8)+top+bottom)`（沿用
   `TextBlockTool.updateText` 行高规则）、BlockCommon 内边距
   5/3/5/10、fontSize 17、fontColor 黑、`corner/textWrap=0`、
   `enableCaption=false`、`resizesWidthToFitText=false`、
   `positionLocked=false`，bounds 经 `textBlockWorldBounds`；
   id 前缀 `imported-text-`。
6. **标题**：URI 尾段去最后一个后缀（复用 `imageImportTitle`）；
   空 stem 回退 `'导入笔记'`。

## 有意差异（fail-closed / 记录项）

- **块几何**：原版 `te0`/`kci.b` 不携带显式位置 —— INSERT_STRING
  落寄存器位 0 后块几何由 cde 默认寄存器决定；Harmony 以「页顶
  (0,0) + 页宽 612pt + 行高测量」物化等价呈现，行高公式沿用既有
  `updateText` 规则，非逐像素等价（文档化近似）。
- **临时文件**：原版经临时文件中转再删；Harmony 直接读 picker
  URI 字节，无临时文件（语义等价）。
- 其余原版约 30 种类型（Office/音视频等）仍 fail-closed。

## 验证

- 专项 Replay `d05-original-text-file-import.mjs`：25 项全绿。
- 既有 `d02-note-import-file-handle-lifecycle.mjs`：7/7。
- `d02-local-create-page-outbound.mjs` 的 `addImportedPage` 计数
  pin 更新为 5。
- 全量 Desktop Replay：见 Phase 654 报告记录的最终计数。
- `note@ohosTest` / `note@default` clean HAP 构建均成功
  （仅既有告警，无新增错误）。
- 未做模拟器/真机验证（按项目约束）。
