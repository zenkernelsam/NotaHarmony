# 原版 plurals.xml 尾部证据（JADX 1.0.3 decompiled）

日期：2026-09-25。来源：`decompiled_1.0.3/resources/res/values/plurals.xml` +
`sources/defpackage/` 消费点。

## plurals.xml 全量 15 键

| key | one | other |
|---|---|---|
| feature_library__delete_note_message | Delete Note? | Delete Notes? |
| feature_library__empty_folder_note_count | %d note | %d notes |
| feature_library__empty_folder_subfolder_count | %d folder | %d folders |
| feature_library__indexing_notes | Indexing %1$d note | Indexing %1$d notes |
| feature_library__notes_selected | %1$d Note Selected | %1$d Notes Selected |
| feature_library__unindexed_note | %1$d Unindexed Note | %1$d Unindexed Notes |
| feature_note__version_history_editor_count | %d editor | %d editors |
| feature_note__version_history_upsell_title | %d day of version history | %d days of version history |
| feature_paywall__free_trial_footnote | *Try free for %1$d day, then %2$s %3$s | *Try free for %1$d days, then %2$s %3$s |
| feature_settings__delete_confirmation_message | Permanently delete %1$d note?\nThis action cannot be undone. | Permanently delete %1$d notes?\nThis action cannot be undone. |
| feature_settings__note_limit_notes | %1$d note | %1$d notes |
| feature_settings__notes_selected | %1$d note selected | %1$d notes selected |
| ui_fileimport__n_files_capitalized | %1$d File | %1$d Files |
| ui_fileimport__ntb_files_could_not_be_imported | %1$d .ntb file could not be imported | %1$d .ntb files could not be imported |
| ui_fileimport__pdfs_truncated | PDF was too long. Imported the first %1$d pages. | Some PDFs were too long. Imported the first %1$d pages of each. |
| ui_fileimport__selected_files | Selected file | Selected files |

## 关键消费点

### fr1.java:113 — PDF 页数截断

```java
z66VarV = rh8.V(0, pageCount > 10000 ? 10000 : pageCount);
adaVar = new ada(arrayList2, pageCount > 10000);
```

原版不拒绝超 10000 页 PDF：`rh8.V(0, min(pageCount,10000))` 只取前段页
范围，`ada` 第二参标记 truncated。该标记经导入状态机（`vs8` 簇）映射为
`ui_fileimport__pdfs_truncated` 提示——单个截断用 one、多个截断用 other。

### i8.java case4 — 多删标题复数

```java
tpe.b(((Resources) uz4Var5.k(fq.c)).getQuantityString(
    R.plurals.feature_library__delete_note_message, i2), ...);
```

`tpe.b` 即删除确认对话框的标题渲染；`i2` 为选中数。标题本身复数化，
无独立 body 数量词。

### i8.java case3 — ntb 部分失败

```java
tpe.b(tl7.H(R.plurals.ui_fileimport__ntb_files_could_not_be_imported,
    i2, new Object[]{Integer.valueOf(i2)}, uz4Var4), ...);
```

### bib.java:28-30 — Recently Deleted 多选模式

```java
eqa eqaVar  = set.isEmpty() ? null : new eqa(
    R.plurals.feature_settings__notes_selected, set.size(), ...);
eqa eqaVar2 = !z ? null : new eqa(
    R.plurals.feature_settings__delete_confirmation_message, set.size(), ...);
```

原版最近删除页有多选工具条（`notes_selected` 计数）与批量永久删除确认
（`delete_confirmation_message`）。Harmony `RecentlyDeletedPage` 当前
无多选模式 → 缺失界面边界。

### uui.java:986 — 订阅设置行

```java
String strH = tl7.H(R.plurals.feature_settings__note_limit_notes,
    b89Var.a(), ...);
```

免费层笔记上限数量（`b89Var.a()`）在设置订阅区展示 — 付费/账号边界。

### hof.java:126 — 库选择计数

```java
tl7.H(R.plurals.feature_library__notes_selected, size, ...);
```

库多选计数 — Harmony `notes_selected`/`note_selected_singular` 已复数化。

### aeh:87 — 导入清单计数

`ui_fileimport__n_files_capitalized` 渲染清单文件计数（"%1$d File(s)"）。

## 结论

- `fr1` 截断语义、删除标题复数、清单计数三个可移植项已在本 Phase 落地。
- Recently-Deleted 多选、版本历史、paywall、note-limit、picker 标题、
  ntb 专用提示按缺失面/后端/平台边界登记。
