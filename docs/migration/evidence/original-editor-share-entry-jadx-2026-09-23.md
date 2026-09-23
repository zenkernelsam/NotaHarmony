# 原版编辑器右上角 Share 入口与分享格式面板 — jadx 证据（2026-09-23）

阶段：Phase 641。结论：原版编辑器顶栏在 undo/redo 图标右侧渲染 Share
图标（`ac4.L` = NOTE_SHARE，PRODUCTION 档默认开启），点击打开分享面板；
面板格式枚举 `s6d` = LINK、PDF、NOTE、JPG、PNG。Harmony 此前编辑器内
无任何分享/导出入口（仅库级菜单的 .note 导出），属真实缺口。本 Phase
补上入口与面板骨架，NOTE 行复用既有 `NoteExporter.exportToFile` 管线；
LINK/PDF/JPG/PNG 因依赖账号后端或页级栅格化器置灰 fail-closed
（ADR-0608）。

## 原版证据（decompiled_1.0.3）

### 顶栏 Share 图标（x90.g 顶栏组合）

`defpackage/x90.java`（约 10541-10556 行）：

```java
// undo/redo 图标块（p9f composable）之后：
uz4Var2.g0(-1017590142);
if (lc4.a(ac4.L)) {                       // ac4.L = NOTE_SHARE
    m18.i(function3, bfd.o(md8Var, 48.0f), false, null, null,
          cq.b, uz4Var2, 1572864, 60);     // cq.b = ke1(15) share 图标
}
// 之后：lc4.a(ac4.r0) → AI/learn 图标；lc4.a(ac4.O0) → cq.c = ke1(16)
// youtube transcription 图标
```

`defpackage/ke1.java`（`case 15`）：

```java
go5.b(vh2.h(uz4Var15, R.drawable.ui_designsystem__share, uz4Var15, 0),
      tl7.U(uz4Var15, R.string.feature_note__toprighttoolbar_share_action),
      null, ev1.b(uz4Var15).c.b, uz4Var15, 8, 4);
```

→ Share 是顶栏 48dp 图标按钮，位于 undo/redo 之后，无障碍文案
`toprighttoolbar_share_action`。

### NOTE_SHARE 特性旗标

`defpackage/ac4.java`：

```java
ac4 ac4Var = new ac4("NOTE_SHARE", 0, zb4Var, ntbVar, null);  // zb4Var = zb4.L
L = ac4Var;
```

`defpackage/zb4.java`：`zb4.L = new zb4("PRODUCTION", 3)`。

`defpackage/lc4.java` `a(ac4)`：tier ordinal 3（PRODUCTION）走远端
kill-switch 检查后 `return true`——生产构建默认可见（对照
`INTERNAL_USERS_ONLY` 的 create_template，`g.compareTo(zb4.K) <= 0`
在生产档为 false 而被隐藏）。

### 分享面板格式枚举 s6d

`defpackage/s6d.java`：

```java
LINK(R.string.ui_share__chip_link, R.string.ui_share__action_link, ..., new atc(3)),
PDF (R.string.ui_share__chip_pdf,  ..., new atc(4)),
NOTE(R.string.ui_share__chip_note, ..., new atc(5)),
JPG (R.string.ui_share__chip_jpg,  ..., new atc(6)),
PNG (R.string.ui_share__chip_png,  ..., new atc(7)),
```

`defpackage/atc.java` case 3~7：分别渲染 `ui_designsystem__share_link /
share_pdf / share_note / share_jpg / share_png` 图标。

### 分享面板状态机 b7d / v6d

`defpackage/b7d.java`：分享面板 ViewModel；构造时
`s6d s6dVar = list.size() > 1 ? s6d.PDF : s6d.LINK`——单笔记默认选中
LINK，多笔记默认 PDF。导出完成经 `qp8.c(new pj(str, ...))` 按格式上报
（"Link"/"PDF"/"Note"/"JPEG"/"PNG"）。

`defpackage/v6d.java`：面板 UI 状态（21 字段）：选中格式 `s6d c`、
页选择集合 `Set l` + 页数 `m`、各格式进度 `Map b`/`o`、系统分享
`Intent t` 等。

### 分享执行

`defpackage/y59.java` `b(s6d, List, Map, File, ...)`：按格式导出；
`y59.b` 方法体未反编译（`UnsupportedOperationException`），PDF/JPG/PNG
的栅格化链路在 JADX 层不可见。

## Harmony 对齐（本 Phase 实现）

- `EditorToolbar`：Redo 按钮后新增 48vp Share 按钮（`↗` 字形 +
  `cd_share_action` 无障碍），点击置 `showShareSheet = true`；
- 同一 Column 追加 `.bindSheet(this.showShareSheet, this.buildShareSheet(),
  { height: SheetSize.MEDIUM })`；
- `buildShareSheet` 按 s6d 原序列出五行：Link/PDF/Note/JPG/PNG；
  NOTE 行可点 → 关面板 + `onShareNote()`；其余行 `opacity 0.4` +
  `share_format_unsupported` 标注，点击空转；
- `NotePage.onShareNote` 走 `photoImportLeaseActive/pageOperationBusy/
  historyPending` 门禁 → `shareNoteAsFile()`：
  `new NoteExporter(db, persistence).exportToFile(context, noteId,
  noteTitle)`（库级导出同款管线：.note zip + DocumentViewPicker 系统
  保存对话框 + `export_done`/`export_failed` toast）；
- 字符串：base/zh_CN 各新增 `cd_share_action`、`share_sheet_title`、
  `share_link`、`share_pdf`、`share_note`、`share_jpg`、`share_png`、
  `share_format_unsupported`。

## 与原版的差异（登记于 ADR-0608）

1. LINK/PDF/JPG/PNG 行置灰不可点：LINK 需账号/链接后端；PDF/JPG/PNG
   需页级栅格化器（ThumbnailRenderer 仅为缩略图分辨率）。
2. 原版面板为"选格式 chip + 页选择 + 动作按钮"两步交互（v6d 21 字段）；
   Harmony 子集为单行即点即导。
3. 原版单笔记默认选中 LINK；Harmony 无可默认项，NOTE 为唯一可执行行。
