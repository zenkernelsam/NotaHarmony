# Phase 684 — 原版字符样式（Bold / Italic / Underline / Strikethrough）Evidence

## 范围

把原版文本工具条的四个字符级样式切换（加粗 / 斜体 / 下划线 / 删除线）移植到
Harmony 文本块编辑覆盖层，与 Phase 681/683 的段落级样式共用同一提交管线。

## 原版证据（decompiled_1.0.3）

### 1. `sources/defpackage/cve.java` —— 工具条派单

`cve` 的 `nue` 等值分发把四个工具项映射为 `n(new zyd(...))` 字符样式变更，
按 `br2`（当前字符样式状态）取反：

| 工具项 | 分发行 | zyd 载荷 | 语义 |
|--------|--------|----------|------|
| `xse.a` | ~L123 | `n(new zyd(Boolean.valueOf(!br2.a), null×10, 2046))` | `zyd.a` = **bold** 取反 |
| `vte.a` | ~L127 | `n(new zyd(null, Boolean.valueOf(!br2.b), ..., 2045))` | `zyd.b` = **italic** 取反 |
| `mue.a` | ~L131 | `n(new zyd(null, null, Boolean.valueOf(!br2.c), ..., 2043))` | `zyd.c` = **underline** 取反 |
| `jue.a` | ~L156 | `n(new zyd(null×10, Boolean.valueOf(!br2.d), 1023))` | `zyd.k` = **strikethrough** 取反 |

尾部 int 为字段位掩码（2046/2045/2043/1023），指示本次变更只触及哪个字段，
其余字段以 `null` 表达"保持不变"——即**字段级增量样式变更**。

### 2. `sources/defpackage/zyd.java` —— 字符样式载荷

`zyd` 为 11 字段不可变载荷：

```
Boolean a;   // bold
Boolean b;   // italic
Boolean c;   // underline
eh5     d;   // highlight（色值+开关）
String  e;   // familyName
Float   f;   // fontSize
iu1     g;   // foregroundColor
String  h;   // link
Boolean i;   // superscript
Boolean j;   // subscript
Boolean k;   // strikethrough
```

与 `RichTextCharacterStyle`（`StrokeTypes.ets`）字段 **1:1 对应**：
`bold/italic/underline/highlightColor/familyName/fontSize/foregroundColor/link/
superscript/subscript/strikethrough`。

同文件 `kue.a`/`lue.a` 分支（zyd.i/j 的 FALSE/TRUE 配对）证实 superscript 与
subscript 互斥切换——本期不覆盖，留作后续。

### 3. `sources/defpackage/l32.java` —— 格式行渲染

`l32` 的 `go5.b(...)` 调用渲染格式行条目，含：

- `R.drawable.ui_text__italic__medium` + `R.string.ui_text__italic`
- `R.drawable.ui_text__underline__medium` + `R.string.ui_text__underline`
- `R.drawable.ui_text__strikethrough__medium` + `R.string.ui_text__strikethrough`

### 4. `resources/res/values/strings.xml`

```
ui_text__bold          = "Bold"          (L1392)
ui_text__italic        = "Italic"        (L1408)
ui_text__strikethrough = "Strikethrough" (L1454)
ui_text__underline     = "Underline"     (L1459)
```

## Harmony 现状（Phase 684 之前）

- `RichTextCharacterStyle` 已含全部四字段（`StrokeTypes.ets`）。
- `Canvas2DTextRenderer` 已渲染：`applyFont` 的 `italic`/`bold` 字体 token
  （~L684-688）、`drawDecoration` 的 `underline`/`strikethrough` 装饰线
  （~L641-646）。
- `TextBlockTool.updateText(element, text, characterStyleRuns?,
  paragraphStyleRuns?)` 已接受双 run 数组并要求"同时提供或同时省略"。
- `TextBlockOverlay` 仅跟踪 `caretOffset` + 段落级 `draftStyles`，
  `onCommit(text, paragraphStyleRuns)` 两参——**无字符样式 authoring 通道**。

## 实现映射

| 原版 | Harmony 实现 |
|------|--------------|
| `br2` 当前样式状态 + `!` 取反 | `rangeHasCharStyle` 选区覆盖判定 → 全覆盖则置 false、否则置 true |
| `zyd` 字段级增量（null=保持） | `applyCharStyle` 仅改写指定字段，深拷贝保留 run 内其余字段 |
| 选区应用 | `caretSelectionStart`/`caretOffset` 非折叠区间 → `applyCharStyle` |
| 折叠光标（typing attributes） | `pendingCharStyles`；`onChange` 差分定位插入区间后把 pending 落地为 run |
| run 边界随文本编辑漂移 | `adjustCharRunsForEdit` 公共前后缀差分 → 平移/收缩/丢弃 |
| canonical/diff 稳定 | `normalizeCharRuns` 排序 + 去空段 + 合并相邻同样式 |
| 提交 | `onCommit(text, charRuns, paraRuns)` → `onTextCommit` 三参 → `updateText` 双 run |

## 关键文件

- `note/src/main/ets/ui/components/TextBlockOverlay.ets`
- `note/src/main/ets/ui/editor/NoteCanvasView.ets`
- `note/src/main/resources/{base,zh_CN}/element/string.json`

## 验证

- `docs/migration/replays/d02-original-character-styles.mjs`：34 项静态钉全绿。
- `note@default` / `note@ohosTest` clean 构建成功（见 Phase 684 report）。
