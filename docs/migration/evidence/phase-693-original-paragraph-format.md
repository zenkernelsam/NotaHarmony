# Phase 693 — 原版段落对齐（vse/i5a/r4a）+ 行距（wte/j5a/fg7）Evidence

## 范围

把原版文本格式面板中的段落对齐（左/中/右）与行距（1.0/1.5/2.0）
authoring 移植到 Harmony 文本块编辑覆盖层。两者均为段落级 CRDT 风格
op（`i5a`/`j5a`），Harmony 侧模型字段与渲染层早已就位，本 Phase 只补
authoring 入口。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/cve.java` —— 分发分支

```java
if (nueVar instanceof vse) {
    m(new i5a(((vse) nueVar).a));   // SetAlignment(r4a)
    i(qse.P);
    return;
}
if (nueVar.equals(gue.a)) {         // 打开行距面板
    qse qseVar11 = qse.Q;
    ...
}
if (nueVar instanceof wte) {
    m(new j5a(((wte) nueVar).a));   // SetLineSpacing(float)
    i(qse.Q);
    return;
}
```

### 2. `sources/defpackage/i5a.java` / `j5a.java` / `r4a.java`

- `i5a.toString = "SetAlignment(alignment=...)"`，持 `r4a`。
- `j5a.toString = "SetLineSpacing(spacing=...)"`，持 float。
- `r4a`：`LEFT((byte)1)` / `CENTER((byte)2)` / `RIGHT((byte)3)`。

### 3. `sources/defpackage/fg7.java`

```java
public final class fg7 {
    public final Float a;   // currentSpacing
    public final List b;    // = m18.m0(1.0f, 1.5f, 2.0f)
    // toString: "LineSpacingPopoverState(currentSpacing=..., availableSpacings=...)"
}
```

### 4. `sources/defpackage/ure.java`（TextToolbarState）

`toString` 含 `alignmentState=`（t）、`alignLeftState`（u）/
`alignCenterState`（v）/`alignRightState`（w）、`lineSpacingState`（y）。

### 5. `sources/defpackage/oue.java` —— 工具条回调

```java
case 7:  cveVar.k(new vse(r4a.LEFT));   break;
case 8:  cveVar.k(new vse(r4a.CENTER)); break;
case 9:  cveVar.k(new vse(r4a.RIGHT));  break;
case 10: cveVar.j().f.o();              // = b40.o() 打开链接（浏览器意图）
```

### 6. `sources/defpackage/hse.java` case 0 / case 5

- case 0：`wsi.a(null, fg7.a, fg7.b, i31(18))` —— 行距面板内容，
  `i31` case 18 → `new wte(float)`。
- case 5：`kdi.b(null, r4aVar, i31(17))` —— 对齐分段控件，
  `i31` case 17 → `new vse(r4a)`。

### 7. 字符串（`resources/res/values/strings.xml`）

`ui_text__text_alignment`="Text alignment"、`ui_text__align_left`=
"Align left"、`ui_text__align_center`="Align center"、
`ui_text__align_right`="Align right"、`ui_text__line_spacing`=
"Line spacing"。

## Harmony 现状（Phase 693 之前）

- `RichTextParagraphStyle.alignment?: number` 与 `lineSpacing?: number`
  字段存在；`Canvas2DTextRenderer` 已兑现：`alignment===2` 居中、
  `===3` 右对齐，`lineSpacing` 作行距乘数（undefined/≤0 → 1）。
- 缺口：无 authoring 入口。

## 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `ure.t`（qse.P 面板钮） | `text_alignment` 钮 → `bindMenu` |
| `kdi.b` L/C/R 分段 → `vse(r4a)` | 菜单三项 → `setAlignment(1/2/3)` |
| `ure.y`（qse.Q 面板钮） | `line_spacing` 钮 → `bindMenu` |
| `fg7.b` = {1.0,1.5,2.0} → `wte(f)` | 菜单三项（标签 `1.0/1.5/2.0`）→ `setLineSpacing` |
| `q2c`/`j5a` 段落 op | `draftStyles` 段落级字段直写（沿用 P686 模式） |

语义细节：

- `setAlignment` 显式写 `alignment`（含 1=LEFT）——原版
  `vse(r4a.LEFT)` 也显式写 LEFT 记录，undefined 与 1 渲染等价但
  记录显式化更忠实。
- `setLineSpacing` 写字面浮点（含 1.0）——`j5a(1.0f)` 原样。
- 段落级粒度 = 光标所在段（`paragraphIndexAt(caretOffset)`），与
  `adjustIndentLevel`/`setCodeLanguage` 同一语义边界。
- 按钮激活态：`caretAlignment!==1` / `caretLineSpacing!==1` 高亮
  （`refreshCaretParagraphExtras` 随 caret/seed 刷新）。

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/base/element/string.json`
- `note/src/main/resources/zh_CN/element/string.json`

## 验证

- `docs/migration/replays/d02-original-paragraph-format.mjs`：
  29 项静态钉全绿。
