# ADR-0625 多选文件导入（ALLOW_MULTIPLE → rv5/qv5 逐文件物化）

- 状态：Accepted
- 日期：2026-09-24
- 关联 Phase：658
- 接续：ADR-0624（编辑器 Add Files 入既有笔记）
- 证据：`docs/migration/evidence/original-multi-file-import-jadx-2026-09-24.md`

## 背景

原版 `nti.R` 为「Add Files」装配双契约启动器：`f35(3)` =
OPEN_DOCUMENT + `ALLOW_MULTIPLE`（主），`f35.c` = GET_CONTENT +
`ALLOW_MULTIPLE`（回退），MIME 过滤 `oj3.f` = 图片9+音频6+Office7+
pdf+txt+`application/octet-stream`（**不含 .note/.nbn/.ntb**）。选中
URI 列表经 `sl(29)` 复制后进 `zvh.a`/`ou5` 导入详情页，再按 `qv5`
（并入既有笔记，编辑器默认）/`sv5`（单新笔记）/`rv5`（每文件一笔记）
物化。Phase 652-657 的选择器均为单选（取 `uris[0]`）。

## 决定

1. **双选择器开多选**：`importFromFile` 与
   `importFileIntoNoteFromPicker` 均设
   `maxSelectNumber = IMPORT_PICKER_MAX_SELECT = 500`
   （Harmony API 上限 1~500；原版 ALLOW_MULTIPLE 不设上限）。
2. **多选分发**：
   - 独立导入 `importPickedFilesStandalone`：逐 URI 读取 → 同一
     分发表（PDF magic/图片/txt/音频/.note 归档）→ 每文件物化为
     独立笔记（对齐 `rv5` CreateSeparateNotes 语义）。
   - 并入 `importPickedFilesIntoNote`：逐 URI →
     `importFileIntoNote(noteId, ...)`（对齐 `qv5` 把负载列表应用
     到既有笔记）。
3. **逐文件读取** `readPickedFile`：与单选路径一致的
   尺寸（`ZIP_MAX_ARCHIVE_BYTES`）/空文件检查，独立 try/finally
   关句柄——单选路径代码与生命周期 fixture 不变。
4. **聚合报告** `aggregatePickedReports`：全败 → CORRUPTED；
   有成功有失败 → PARTIAL；全胜 → SUCCESS；noteId 取首个成功创建
   者（into-note 恒为目标笔记）；pageCount/warnings 累计；
   message 报「已导入 N 个文件（，M 个失败）」。
5. **编辑器刷新**：`importFileIntoCurrentNote` 对 PARTIAL 同样
   重载页列表 + `pageContentVersion++` + `loadRecordings`
   （部分成功已实际落库）。

## 登记的差异（fail-closed / 未实现）

- **导入详情页未实现**：原版 `zvh.a`/`ou5` 提供逐文件预览、目标
  选择（当前笔记/新笔记/各自笔记）、导入进度；Harmony 直接按
  qv5（into-note）/rv5（standalone）默认语义物化。
- **加密 PDF 密码提示未实现**：`ou5.onPasswordSubmitted` 表明原版
  支持加密文档；Harmony `loadDocument` 直接失败 → CORRUPTED。
- **选择上限**：原版不设上限，Harmony 取 API 最大 500。
- **多选顺序**：按选择器返回顺序逐文件物化（原版 `list` 顺序同理）。
- **rv5 titleOverrides**：原版可逐文件改题；Harmony 沿用文件名
  词干自动标题。

## 后果

- 选择器行为与原版对齐（多选 + 同类过滤表）；单选路径完全不变。
- 多选部分失败不丢已成功内容（PARTIAL + 逐文件警告）。
- 导入详情页与密码流程成为明确登记的后续候选项。
