# 原版导入详情页确认按钮文案 JADX 证据（2026-09-25）

Phase 740。本文件钉死原版 `ui_fileimport` 详情页确认按钮的上下文文案
（`decompiled_1.0.3` 直接证据）。

## 结论

原版确认按钮**不是**静态 "Import"，而是随目的地变化的三个文案：
现有笔记 → `add_to_note`（"Add to \"%1$s\""）、合并单篇 →
`create_single_note`（"Create single note"）、各自新建 →
`create_new_note`（"Create new note"）。

## 证据链

1. `sources/defpackage/y5j.java:59-77` — 确认按钮文案 `strD`/`strD2`：
   ```java
   bxbVar = (strL == null || strL.length() == 0)
       ? new bxb(R.string.data_library_state__default_note_title, ...)
       : gvd.b(strL);                       // 目标笔记题，空→默认题
   strD = tl7.T(R.string.ui_fileimport__add_to_note, {bxbVar...});  // "Add to X"
   // bxbVar==null（未选笔记/加载中）时：
   strD = ttfVarH != null ? loading : add_to_existing_note;
   strD2 = z ? create_single_note : create_new_note;
   // z = pt5Var.k().size() > 1 —— 多文件时第二钮 = "Create single note"
   ```
   `gwh.java:171`/`mu.java:100` 为 `y5j.a` 的两个消费点
   （文件导入编排页与单页导入路径）。
2. `resources/res/values/strings.xml`：
   - `ui_fileimport__add_to_note` = `"Add to \"%1$s\""`
   - `ui_fileimport__add_to_existing_note` = `"Add to existing note"`
   - `ui_fileimport__create_new_note` = `"Create new note"`
   - `ui_fileimport__create_single_note` = `"Create single note"`
   - `ui_fileimport__loading` = `"Loading…"`

## 语义映射

| 原版状态 | 原版确认文案 | Harmony 目的地 |
|----------|--------------|----------------|
| 选中现有笔记 | `Add to "<题>"` | `EXISTING_NOTE` + selectedNoteId |
| 未选/加载中 | `Add to existing note`/`Loading…` | （Harmony importEnabled 门禁覆盖） |
| 多文件→合并 | `Create single note` | `SINGLE_NOTE` |
| 单文件/各自 | `Create new note` | `SEPARATE_NOTES` |

## Harmony 端口

`note/src/main/ets/ui/components/ImportDetailsSheet.ets`：

- 新增 `confirmLabel()`：EXISTING → `$r(import_add_to_note, title)`
  （空题经 `getStringSync(untitled_note)` 兜底，等价 y5j 的
  null||empty→default_note_title）；SINGLE → `import_create_single`；
  SEPARATE → `import_create_new`。
- `Button($r('app.string.import_confirm'))` → `Button(this.confirmLabel())`。
- `import_confirm` 键保留（d05 fixture 仍钉其存在性）。
- 新增字符串（base/zh_CN）：`import_add_to_note`、
  `import_create_single`、`import_create_new`。
