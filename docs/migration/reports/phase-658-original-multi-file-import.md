# Phase 658：多选文件导入（ALLOW_MULTIPLE → rv5/qv5 逐文件物化）

日期：2026-09-24
接续：Phase 657（编辑器「Add Files」物化进当前笔记）

## 原版依据

- `f35` case 3：`OPEN_DOCUMENT` + `ALLOW_MULTIPLE`（主契约）；
  `f35.c` = case 1：`GET_CONTENT` + `ALLOW_MULTIPLE`（回退）。
- `nti.R`：注册双启动器 `fad.O`，经 `yt0(...)` 按可用性挑选；
  MIME 过滤 `oj3.f`（i2=1 → z2=false）。
- `oj3` 静态表：图片9 + 音频6 + Office7 + pdf + txt（`oj3.e`），
  `oj3.f` 再加 `application/octet-stream`；**不含 .note/.nbn/.ntb**。
- 结果流：`lb` case 8 → `tf9` case 21 → `sl(29)` 复制 →
  `gl8Var.setValue(list)` → `u49` 检测非空 → `zvh.a(list, ttf, ...)`
  渲染 `ou5` 导入详情页（含 `onPasswordSubmitted` 加密密码流程）；
  `ub2` case 4 `ou5.p(ttf)` → `qv5` 默认并入当前笔记；`rv5` =
  CreateSeparateNotes。
- 详见 `docs/migration/evidence/original-multi-file-import-jadx-2026-09-24.md`。

## Harmony 实现

1. `NoteImporter.ets`：
   - `IMPORT_PICKER_MAX_SELECT = 500`（API 上限；原版不设上限）。
   - `importFromFile` / `importFileIntoNoteFromPicker` 均设
     `maxSelectNumber`；`uris.length > 1` 走多选循环，单选路径不变。
   - `importPickedFilesStandalone`：逐 URI `readPickedFile` → 同一
     分发表（PDF magic/图片/txt/音频/`importFromData`）→ 每文件
     独立成笔记（rv5 语义）。
   - `importPickedFilesIntoNote`：逐 URI → `importFileIntoNote`
     （qv5 语义，全部并入既有笔记）。
   - `readPickedFile`：逐文件 open/stat/尺寸/空检查/read/close，
     独立 try/finally 句柄清理。
   - `aggregatePickedReports`：全败 CORRUPTED / 部分 PARTIAL /
     全胜 SUCCESS；noteId 取首个成功者；pageCount/warnings 累计。
2. `NotePage.ets`：`importFileIntoCurrentNote` 对 PARTIAL 同样
   刷新页列表 + `pageContentVersion++` + `loadRecordings`。

## 登记差异（ADR-0625）

- `ou5`/`zvh.a` 导入详情页（逐文件预览 + 目标选择）未实现，按
  qv5/rv5 默认语义直接物化。
- 加密 PDF 密码提示未实现（loadDocument 失败 → CORRUPTED）。
- 上限 500（原版无上限）；rv5 titleOverrides 未实现（沿用词干标题）。

## 验证

- 桌面回放：`d05-original-multi-file-import.mjs` 33 断言绿；
  全量套件见提交信息。
- HAP：`note@ohosTest` / `note@default` clean 构建通过（见提交信息）。
