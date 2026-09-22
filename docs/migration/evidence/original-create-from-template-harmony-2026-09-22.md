# 原版从模板新建笔记 → HarmonyOS 移植证据（2026-09-22）

## 原版证据

`decompiled_1.0.3/sources/defpackage/cd.java` 的 `case 0`（新建表单）依次渲染：

1. `feature_library__import` — Import 行
2. `feature_library__templates` — Templates 行（`ac4.K0` flag 控制）
3. `feature_library__docscan` — Doc scan 行（`ac4.a0` flag 控制）
4. `feature_library__create_note` — Create note 行

点击 Templates 行调用 `cd.invoke(h31Var, "feature_library__templatenewnote")`，
打开 `feature_library__templatenewnote` 对应的新建表单模板选择页（独立 sheet，
选择模板后用该模板新建笔记）。

`decompiled_1.0.3/resources/res/values/strings.xml`：
`feature_library__templates` = "Templates"，`feature_library__create_note` = "Create note"。

## Harmony 移植

- `LibraryPage` 快速动作区（Phase 545 speed-dial）在 Record audio / Import file
  之后新增 `templates` chip，打开 `TemplatePickerDialog`。
- `TemplatePickerDialog` 提供四款可移植纸张：`PaperTemplate.PLAIN / LINES /
  GRID / DOTS`（`template_plain/lines/grid/dots`），选择后经 `onPick` 回调走
  `createFromTemplate(template)` → `createAndLaunch(false, templateOverride)`。
- `LibraryViewModel.createNote(title, templateOverride?)` →
  `NoteRepository.createNote(title, folderId, templateOverride?)`：有覆盖时
  `applyOriginalPaperSettings(resolved, size, override, orientation)` 只替换纸张
  类型，尺寸/方向沿用解析出的默认模板，随后照常走
  `persistOriginalBlankNoteBootstrap`。
- 与原版相同的点：新建入口提供模板选择；选择模板即以该纸张新建并打开笔记；
  不改变持久化的默认模板偏好。
- 已登记差异：原版 `ac4.K0` 模板 flag 与 `ac4.a0` docscan flag 对应的完整模板
  管理页/文档扫描不可移植；Harmony 仅提供四款内置纸张的一键新建。

## 验证

- 回放：`docs/migration/replays/d02-original-create-from-template.mjs`
  覆盖原版 `cd` 行序/字符串锚点、Harmony 对话框/芯片/管线锚点及覆盖语义模型。
- `node@default`、`note@ohosTest` 双构建通过。
