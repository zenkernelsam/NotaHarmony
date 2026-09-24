# Phase 686 — 原版段落缩进 ±1（Increase / Decrease Indent）Evidence

## 范围

把原版文本工具条的段落缩进增减（`h5a(±1)`）移植到 Harmony 文本块编辑
覆盖层，复用 Phase 681 的 `draftStyles` 段落键管线。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/cve.java` —— 派单（L242-248）

```java
if (nueVar.equals(ute.a)) {
    m(new h5a(1));    // increase indent
    return;
}
if (nueVar.equals(yte.a)) {
    m(new h5a(-1));   // decrease indent
    return;
}
```

`ute`/`yte` 工具项 → `m(new h5a(±1))` 段落级缩进增量 op（与 `m5a`
段落样式 op 同 `m(...)` 通道）。

### 2. `sources/defpackage/l32.java` —— 行序

格式行 case0/case1 渲染 `ui_text__increase_indent`/`ui_text__decrease_indent`
——**行首两项**，先于 italic(2)。`uz4Var.X(iIntValue & 1, (iIntValue & 3) != 2)`
控制可见/可用态（未解码全部条件，取"常规编辑态可见"语义）。

### 3. `resources/res/values/strings.xml`

```
ui_text__decrease_indent = "Decrease indent" (L1396)
ui_text__increase_indent = "Increase indent" (L1406)
```

## Harmony 现状（Phase 686 之前）

- `RichTextParagraphStyle.indentLevel` 字段存在；`draftStyles` 段落键
  管线承载（P681）。
- `Canvas2DTextRenderer` L770：`Math.max(0, paragraph.indentLevel ?? 0) *
  element.fontSize * 36 / 14` —— 渲染侧按 indentLevel×36pt@14px 缩进。
- `toggleDecoratorStyle` 已在字段拷贝中保留 `indentLevel`。
- 缺口：**无 authoring 入口**——缩进只能读不能写。

## 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `h5a(+1)`/`h5a(-1)` 增量 | `adjustIndentLevel(±1)`：`indentLevel = max(0, (cur ?? 0) + delta)` |
| 段落级 op | `draftStyles.get(paragraphIndexAt(caretOffset))` 光标段落粒度 |
| 行序 increase<decrease<italic | 按钮置 bold 与 italic 之间（l32 序） |
| 钳制 | `Math.max(0, ...)` 与渲染器 `Math.max(0, indentLevel ?? 0)` 一致 |

canonical 细节：level 归 0 且条目无其余字段时 `draftStyles.delete`
（与 toggleDecoratorStyle 的空对象清除同一约定）。

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/resources/{base,zh_CN}/element/string.json`

## 验证

- `docs/migration/replays/d02-original-indent-controls.mjs`：12 项静态钉全绿。
