# Phase 681 — 原版 QUOTE_AND_CODE_BLOCKS（引用/代码块）证据

## 原版证据（decompiled_1.0.3）

### 旗标

- `ac4.java:99`：`QUOTE_AND_CODE_BLOCKS` ordinal 6，`jtb.c` 远端键。
- `jtb.java:5`：`new jtb("androidQuoteAndCodeBlocks")`——远程配置键；
  **出厂 `core_remoteconfig__remote_config_defaults.xml` 缺席**
  （rollout 门控：代码随 1.0.3 发布，服务器分批放量）。
- `ili.java:192`：文本格式工具条可见性 = `lc4.a(ac4.R)`。
- `x90.java:947`：`!lc4.a(ac4.R)` 时读侧 mask——远端关闭即不渲染该样式。

### 段落 decorator 枚举

- `fy2.java:22-23`：`BLOCK_QUOTE((byte) 4)`、`CODE_BLOCK((byte) 5)`——
  与既有 BULLET(1)/NUMBER(2)/CHECK_BOX(3) 同枚举 `fy2`。

### 工具条与分发

- `h32.java:359,369`：格式工具条 `ui_text__block_quote` /
  `ui_text__code_block` 图标行（`ui_text__*_medium` 图标 + 文案）。
- `strings.xml:1391,1395`：`"Block quote"` / `"Code block"`。
- `cve.java:201-217`：菜单动作 `o(fy2.BULLET|NUMBER|CHECK_BOX|BLOCK_QUOTE|
  CODE_BLOCK)`——**段落级单选互斥**。
- `cve.java:420`：`o(fy2)` → `m(new m5a(fy2Var), …)`——写入
  `MODIFY_PARAGRAPH_STYLE` CRDT 操作；`CODE_BLOCK` 额外携
  `k5a(this.W)`（代码语言上下文）。

### 渲染

- `lj3.java:298,853`：`fy2Var3 == fy2.CODE_BLOCK` → `f3 = f2 - 24.0f`
  （≥1）——代码块**缩小字号**渲染；`di3.J` 常量随行距参与。
- `sq4.java:8`：`"monospace"` FontFamily token——代码字族 = monospace。

## Harmony 实现

- `TextBlockOverlay.ets`
  - `draftStyles: Map<段落序号, RichTextParagraphStyle>`——编辑期样式
    载体，`seedParagraphStyles()` 把元素 `paragraphStyleRuns`（字符区间）
    解回段落序号；`paragraphIndexAt(caretOffset)` 光标定位。
  - 底部行新增两枚切换钮：`Block quote`→decorator 4、`Code block`→5；
    再点同项回 NONE（原版单选互斥 + 再点取消的等价物）；
    `caretDecoratorStyle` 驱动激活态底色。
  - `computeParagraphRuns()` 提交时折回字符区间 run；
    `onCommit(text, runs)` 签名扩展。
  - 已登记近似：序号键样式在编辑中插删换行时可能漂移（原版同样按
    段落持样式，方向一致）。
- `TextBlockTool.updateText`：原文本不变即 no-op 短路改为
  `paragraphStyleRuns === undefined` 才短路——样式-only 提交合法。
- `NoteCanvasView.onTextCommit(text, paragraphStyleRuns?)`
  - `stylesDiffer` = authored runs 与编辑前快照 JSON diff。
  - 本地块：`(textChanged || stylesDiffer) && 非 CRDT` → authored runs。
  - CRDT 块文本变更：preview 管线照旧，段落 run 取 authored ?? preview。
  - CRDT 块仅样式变更：元素级 apply（**无本地 MODIFY_PARAGRAPH_STYLE
    编码器**——`cve.o` 在原版写 CRDT op，Harmony 只有 decode/apply 侧，
    见 ADR-0648 限制项）。
- `Canvas2DTextRenderer`：`applyCodeBlockFace` 对 decoratorStyle==5 段落
  整段 `familyName='monospace'`（`sq4` 等价），measureNaturalWidth /
  renderText / linkAtPoint / caretIndexAtPoint 四处同改（度量一致）；
  renderText 行循环内 `fillRect` 浅底带（`fontColor × 0.08`）。
  - 已登记近似：lj3 的 `-24f` 缩字号未移植（单位体系不同，等宽+底带
    已区分代码块）；语言选择器（`k5a` 上下文）未实现。
- 资源：`block_quote`/`code_block`（en "Block quote"/"Code block"；
  zh 引用/代码块）。

## 未覆盖（登记）

- 代码块语言选择（`k5a(this.W)`）与语法高亮；`RichTextParagraphStyle
  .programmingLanguage` 字段已存在，待语言选择面。
- lj3 `-24f` 缩字号精确值；`di3.J` 行距常量。
- CRDT 文本块样式-only 提交不落 op 日志（元素级持久化，CRDT 重物化
  后丢失——见 ADR-0648）。
- 远端 rollout 门控在 Harmony 无条件放开（`canIUse` 无对应 syscap；
  与 ac4.a0 处理一致：能力等价物即门控）。
