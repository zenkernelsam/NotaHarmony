# Evidence: `ui_text__` 族尾部（JADX）

- 日期：2026-09-25
- Phase：719（ADR-0667）
- 证据来源：`decompiled_1.0.3`（只读）

## add_text — 文本工具项标签

`fie.java:19`（`fie extends ake`，`uke.java:341` 注册到工具箱 `qo5`）：

```java
String string = context.getString(R.string.ui_text__add_text); // "Add Text"
yzVar.j(string);   // 工具项描述符 label
yzVar.l(iP);       // 图标 dv1.d
this.s = yzVar.q();
```

工具项唯一 label 源 → Harmony `toolTypeLabel` 默认分支 +
EditorToolbar 添加菜单项同步改 `add_text`。

## insert/edit hyperlink — 链接对话框标题择一

`bn5.java:127`：

```java
String strU = tl7.U(uz4Var2,
    en5Var2.c ? R.string.ui_text__edit_hyperlink     // 选区已有链接
              : R.string.ui_text__insert_hyperlink); // 新插入
```

字段标签 `ui_text__url`/`ui_text__link_title`（`x22:182`/`203`）——
Harmony 占位提示 `link_url_hint`="URL"/`link_title_hint`="Link title"
已等值。移植补 `linkSheetIsEdit` + 标题行。

## programming_language — 语言菜单标题

`i8j.java:42`：`koi.a(list, …, strU=programming_language, …)`——代码块
语言菜单带标题 "Programming language"。Harmony `bindMenu` 支持
`MenuOptions.title`（API≥12）→ `{ title: $r('app.string.programming_language') }`。

## 边界登记

| 项 | 原版实现 | 不移植原因 |
|---|---|---|
| `kbd_shortcut_*` ×12 + `group_text_editing` | `hke.java` 静态注册 `wl6` 键位→`kmi` 产出 `KeyboardShortcutGroup`（Android `onProvideKeyboardShortcuts` 系统快捷键帮助表） | HarmonyOS 无系统快捷键帮助面；快捷键本体已移植（清单 R-32） |
| `undefined_format`/"Format" + `hr4` | `br2` 工具条格式按钮显示当前具名样式，`ir4` 混合时兜底 "Format" | Harmony 预设写 `{bold,fontSize}` 原子，无具名样式字段可回读 |
| `fontsize` chevron | `whh.java:289` 字号值旁 chevron 的 contentDescription（开字号列表） | Harmony 为 ±1pt 步进器（ADR-0648 `kre` 对位），无 chevron 节点 |

## Replay

`d02-original-ui-text-tail-labels.mjs`（22 pins）。
