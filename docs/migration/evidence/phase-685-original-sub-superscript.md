# Phase 685 — 原版上下标互斥切换（Subscript / Superscript）Evidence

## 范围

把原版文本工具条的 subscript/superscript 互斥对移植到 Harmony 文本块编辑
覆盖层，沿用 Phase 684 的字符 run 管线；补齐原版 `zyd` 同包显式 FALSE
的互斥语义。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/cve.java` —— 派单（L159-165）

```java
if (nueVar.equals(kue.a)) {   // superscript 按钮
    n(!br2.f ? new zyd(null×8, Boolean.FALSE, Boolean.TRUE, null, 1279)
             : new zyd(null×9, Boolean.FALSE, null, 1535));
    return;
}
if (nueVar.equals(lue.a)) {   // subscript 按钮
    n(!br2.e ? new zyd(null×8, Boolean.TRUE, Boolean.FALSE, null, 1279)
             : new zyd(null×8, Boolean.FALSE, null, null, 1791));
    return;
}
```

- `br2.e` = subscript 当前态，`br2.f` = superscript 当前态。
- **启用**（`!br2.x` 为 true）：同一 zyd 载荷内本字段 `TRUE` + 兄弟字段
  显式 `FALSE`（mask 1279）——**互斥在单条变更内原子完成**。
- **停用**：只写本字段 `FALSE`，不触碰兄弟（mask 1535/1791）。

`zyd` 位置参数 9/10/11 = `i`/`j`/`k`（Boolean bool4/5/6），结合启用分支可定：

| zyd 字段 | 语义 |
|----------|------|
| `i` | **subscript**（lue 启用写 i=TRUE） |
| `j` | **superscript**（kue 启用写 j=TRUE） |
| `k` | strikethrough（P684 已定） |

### 2. `sources/defpackage/l32.java` —— 行序

格式行 case 序：`increase_indent(0)`、`decrease_indent(1)`、`italic(2)`、
`underline(3)`、**`subscript(4)`**、**`superscript(5)`**、`strikethrough(6)`。
sub 在 super 前、二者夹在 underline 与 strikethrough 之间。

### 3. `resources/res/values/strings.xml`

```
ui_text__subscript   = "Subscript"   (L1455)
ui_text__superscript = "Superscript" (L1456)
```

## Harmony 现状（Phase 685 之前）

- `RichTextCharacterStyle.subscript`/`superscript` 字段已存在。
- `Canvas2DTextRenderer` 已渲染：`superscript → y -= size*0.35`、
  `subscript → y += size*0.25`，字号 `base*0.75`（L629-633、L700）。
- P684 管线（applyCharStyle/rangeHasCharStyle/pending）只处理单字段
  toggle——无互斥对语义；pending 落地只应用 `=== true` 字段，显式
  FALSE 不会清除兄弟（插入段继承 run 兄弟字段 → 可能出现 sub+super
  同时为 true 的非法态）。

## 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `zyd` 同包 TRUE+FALSE 互斥 | `toggleCharStylePair(field, other)`：启用时 `applyCharStyle(field,true)` + `applyCharStyle(other,false)` |
| 停用只写本字段 FALSE | `on=false` 分支只 `applyCharStyle(field,false)`，不动兄弟 |
| pending 中显式 FALSE | `charStyleHas` 区分"未设置/显式 false"；onChange 按存在字段按值落地 |
| l32 行序 | sub/super 按钮插在 underline 与 strikethrough 之间 |

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/{base,zh_CN}/element/string.json`

## 验证

- `docs/migration/replays/d02-original-sub-superscript.mjs`：19 项静态钉全绿。
