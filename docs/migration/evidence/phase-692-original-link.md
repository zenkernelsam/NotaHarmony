# Phase 692 — 原版链接（tte / aue / en5 → zyd.h）Evidence

## 范围

把原版链接 authoring（选择菜单 LINK → `en5` 对话框 → `tte` 确认 →
`fm7.l` replaceSelectedText + `zyd.h`；`aue`/`wm5` 移除链接）移植到
Harmony 文本块编辑覆盖层。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/cve.java` —— `tte` 分支（L167-175）

```java
if (nueVar instanceof tte) {
    do { ... } while (!asdVar4.i(value8, null));   // 清链接对话框态
    tte tteVar = (tte) nueVar;
    j().e.l(tteVar.b,                 // linkTitle
        new zyd(null, null, null, null, null, null, null,
            tteVar.a,                 // arg8 = url → zyd.h
            null, null, null, 1919));
    return;
}
```

`tte.toString = "OnHyperlinkConfirmed(url=..., linkTitle=...)"`。

### 2. `cve.java` —— `aue` 分支（L187-196）

```java
if (nueVar.equals(aue.a)) {
    fm7Var.c.U("removeHyperlinkFromSelection", new yl7(fm7Var, i));
    ...
}
```

`ose.java`：`wm5`（选择菜单 RemoveLink）→ `cveVar.k(aue.a)`；
`um5`（编辑既有链接）→ `cveVar.k(new mte(url,title))`（mte→`en5`
对话框预填）；`tm5` → `asd.i(new en5(str, tm5Var.a, str.length()>0))`
——`en5{title,url,edit}` 对话框态，`edit` 标志 = **标题非空**。

### 3. `sources/defpackage/fm7.java` —— `l(str, zyd)`（L275-293）

```java
public final void l(String str, zyd zydVar) {
    this.c.U("replaceSelectedText", new wc(this, str, zydVar, ...));
    ...
}
```

**replaceSelectedText**：把当前选区替换为 `linkTitle` 文本，
并对插入文本应用 `zyd{link:url}`。

### 4. `sources/defpackage/zyd.java`

`public final String h` —— `zyd` 第 8 字段即 link 负载槽。

### 5. 字符串

`ui_text__link`="Link"、`ui_text__link_title`="Link title"；
`tqe.LINK(4)` 为选择菜单第 4 项。

## Harmony 现状（Phase 692 之前）

- `RichTextCharacterStyle.link?: string` 字段存在；
  `Canvas2DTextRenderer` 在 `characterStyles[linkIndex]?.link !==
  undefined` 时识别链接 run（点击分发由上层处理）。
- 缺口：**无 authoring 入口**。

## 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `tqe.LINK` 选择菜单项 | `Link` 工具条钮（Harmony 选择菜单为系统级——既有注册差异） |
| `en5` 对话框（url+title，edit=标题非空） | `bindSheet`：`linkUrlDraft`+`linkTitleDraft` 双 TextInput，确认钮 `enabled(url非空 && title非空)` |
| `um5`→`mte` 编辑既有链接预填 | `openLinkSheet()`：`linkTitleDraft`=选中文本、`linkUrlDraft`=`linkUrlAt(s,e)`（首个携 link run 的 url） |
| `tte`→`fm7.l` replaceSelectedText | `confirmLink()`：`draftText` 选区替换为 title → `adjustCharRunsForEdit` 差分平移 run → `applyLinkUrl(url, s, s+title.length)` → 光标落标题尾 → `onDraftChange` |
| `aue`/`wm5`→removeHyperlinkFromSelection | `removeLink()` → `applyLinkUrl(null, s, e)` 清 `link` 字段（JSON 归并剔空样式） |
| 折叠光标 | `en5.c` 语义保留：标题必填——折叠光标输入标题即在该处插入题文+链接（等价 replaceSelectedText 的空选区退化） |

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`

## 验证

- `docs/migration/replays/d02-original-link.mjs`：18 项静态钉全绿。
