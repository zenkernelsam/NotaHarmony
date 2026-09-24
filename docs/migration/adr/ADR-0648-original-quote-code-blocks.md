# ADR-0648：原版 QUOTE_AND_CODE_BLOCKS 移植（段落样式编辑 + 代码块渲染）

- 状态：已接受
- 阶段：Phase 681

## 背景

原版 `ac4.R = QUOTE_AND_CODE_BLOCKS(6)`（远端键
`androidQuoteAndCodeBlocks`，出厂 defaults 缺席 = rollout 门控）
向文本格式工具条追加两枚段落级 decorator 切换：**Block quote**（`fy2` 4）
与 **Code block**（`fy2` 5）。`cve.o(fy2)` 经 `m5a` 写
`MODIFY_PARAGRAPH_STYLE` CRDT op；`lj3` 渲染端对 `CODE_BLOCK`
缩字号（`f2-24f`）并走 `sq4` monospace 字族。

Harmony 侧此前状况：`RichTextParagraphStyle.decoratorStyle`/
`programmingLanguage` 模型字段与 CRDT **读侧**物化均已存在，
`Canvas2DTextRenderer` 已渲染 1–4 号样式（含 BLOCK_QUOTE 的 `> ` 前缀），
但**无任何段落样式编辑面**，CODE_BLOCK(5) 无渲染路径。

## 决定

1. **编辑面**：`TextBlockOverlay` 底部行新增 Block quote / Code block
   两枚切换钮——光标段落粒度（原版 `o(fy2)` 段落级单选互斥），
   再点同项回 NONE。`draftStyles` 以段落序号为键承载编辑期样式，
   `computeParagraphRuns()` 提交时折回字符区间 run。
2. **提交管线**：`onCommit(text, runs)` 扩展；`onTextCommit` 三分支
   （新建 / 本地既有 / CRDT）统一携 authored runs；`stylesDiffer`
   使**样式-only 提交**（文本未变）成为合法更新；
   `TextBlockTool.updateText` 短路条件改为 `runs 未提供`。
3. **渲染**：`decoratorStyle==5` 段落整段切 `monospace` 字族
   （`sq4` 等价物）+ 整行浅底带（`fontColor × 0.08`）。字族改写
   作用于字形级样式数组，四个度量/渲染/命中路径同改保持一致。
   BLOCK_QUOTE 沿用既有 `> ` 前缀渲染（已覆盖，不重复实现）。
4. **rollout 旗标不复制**：原版远端门控是发布策略而非能力探测；
   Harmony 无条件放开（与 Phase 680 `ac4.a0` 处理一致）。

## 差异 / 限制（登记）

- **CRDT 文本块样式-only 提交不落 op**：原版 `cve.o` 写
  `MODIFY_PARAGRAPH_STYLE` CRDT op，Harmony 只有 decode/apply 侧、
  无本地编码器。样式写元素级并随元素持久化；CRDT 重物化后丢失。
  补编码器（`m5a`/`k5a` FlatBuffer 写侧）登记为后续 Phase 候选。
- **lj3 `-24f` 缩字号未移植**：原版代码块字号缩 24 单位（≥1），
  单位体系不同；以等宽字族+底带区分，视觉已可辨。
- **代码块语言选择（`k5a(this.W)`）未实现**：`programmingLanguage`
  字段保留；语言选择器与语法高亮为后续 Phase 候选。
- **段落序号键样式漂移**：编辑中插删换行后序号样式可能错位
  （原版按段落持样式，方向一致；仅影响同一会话内未提交草稿）。

## 验证

- Replay `d02-original-quote-code-blocks.mjs`：32 断言全绿；
  全量套件全绿；`note@ohosTest`、`note@default` 双 HAP 构建成功。
- 段落样式切换交互属设备验证项，已入真机清单补遗。
