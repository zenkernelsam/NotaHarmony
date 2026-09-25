# 原版库卡片标题兜底与回收站副标题 JADX 证据（2026-09-25）

Phase 739。本文件钉死原版两处"空标题 → 默认题"渲染兜底及回收站行
副标题格式（`decompiled_1.0.3` 直接证据）。

## 证据一：`e5j.h` —— 库卡片空标题兜底

`sources/defpackage/e5j.java:322`：

```java
public static final String h(String str, t42 t42Var) {
    uz4 uz4Var = (uz4) t42Var;
    if (str == null) {
        return nb.d(uz4Var, -741140099,
            R.string.data_library_state__default_note_title, uz4Var, false);
    }
    ...
    return str;
}
```

卡片渲染点把 `w09.d`（物化标题，可空）交给 `e5j.h`：为 null 时替换为
`data_library_state__default_note_title`（`"New Note"`），否则原样显示。

三个消费点（三种卡面布局变体共用同一兜底）：

- `sources/defpackage/b5j.java:115` — `e5j.h(w09Var.d, uz4Var)`
- `sources/defpackage/cti.java:104` — 同上
- `sources/defpackage/m5j.java:156` — 同上

同类"空题 → 默认题"兜底在原版其它列表构建器同样存在：

- `nti.java:808`、`ksh.java:935`（组件/订阅源构建）
- `y5j.java:59` — `(strL == null || strL.length() == 0)` →
  `default_note_title`（显式空串兜底，最直接证据）
- `bib.java:43` — 回收站行 `strL != null ? ... : default_note_title`
- `id7.java:1172` — 建篇默认题（Phase 716 已对齐创建侧）

Harmony 侧 `note.title` 列为 `TEXT NOT NULL DEFAULT ''`（schema 1895），
`renameNote('')` → `updateNoteTitle(null)` → 物化 `''` —— 即原版的
null 标题在 Harmony 规范化为空串，渲染侧等价判定为 `length > 0`。
本 Phase 在两处库卡片 `Text(note.title)` 应用既有
`untitled_note` 兜底约定（`ImportDetailsSheet:353`、
`RecentlyDeletedPage:177` 已有同款）。

## 证据二：`bib`/`nhb` —— 回收站行副标题

`sources/defpackage/bib.java:43`：

```java
th7VarS.add(new nhb(ttfVar,
    strL != null ? new gvd(strL) : new bxb(R.string.data_library_state__default_note_title, ...),
    new bxb(R.string.feature_settings__note_deleted_at,
        Arrays.copyOf(new Object[]{z5c.n(j)}, 1)), ...));
```

- 行标题：空（null）→ `default_note_title`（Harmony 既有兜底一致）。
- 行副标题：`feature_settings__note_deleted_at` = `"Deleted %1$s"`，
  `%1$s` 由 `z5c.n`（`ofLocalizedDate(MEDIUM)`，Phase 738 已钉）填充 —
  即 `"Deleted Jan 5, 2026"` 形态，**无**"剩余天数"段。
- 原版资源树无 days-left/remaining-days 文案（strings.xml/plurals.xml
  全量检索 0 命中）。

## Harmony 端口

1. `LibraryPage.ets` 两处卡片 `Text(note.title)` →
   `note.title.length > 0 ? note.title : $r('app.string.untitled_note')`。
2. 组件卡 `FolderNotesCard`/`RecentNotesCard`/`NoteThumbnailEditPage`
   三个 `Text(item.title)`/`Text(note.title)` 同法兜底 —— 原版组件
   订阅源 `nti`/`ksh` 同样走 `default_note_title`。
3. `RecentlyDeletedPage.ets`：
   - `formatDeletedTime` 改 `Intl.DateTimeFormat(undefined,
     { dateStyle: 'medium' })`（z5c.n 等价物，带兜底）。
   - `recently_deleted_meta` 值改 `"Deleted %s"` / `"删除于 %s"`，
     去掉 Harmony 自加的 `· %d days left` 段与 `daysLeft`/`MS_PER_DAY`
     死代码（原版无此信息）。
   - 行标题空题兜底（`untitled_note`）已存在，不动。
