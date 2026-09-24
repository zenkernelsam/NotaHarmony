# Phase 681 — 原版 QUOTE_AND_CODE_BLOCKS（引用/代码块）移植

## 范围

`ac4` 旗标清扫收尾：`ac4.R = QUOTE_AND_CODE_BLOCKS(6)`（远端键
`androidQuoteAndCodeBlocks`，rollout 门控）是 `ac4` 表中最后一个
未覆盖的本地编辑功能——文本格式工具条的 **Block quote / Code block**
段落级样式切换及其渲染。本期实现编辑面 + 提交管线 + CODE_BLOCK 渲染。

## 原版行为（证据见 phase-681 evidence）

- `h32.java`：格式工具条 `ui_text__block_quote`/`ui_text__code_block`
  图标行；`ili` 以 `lc4.a(ac4.R)` 门控可见性，`x90` 读侧 mask。
- `fy2`：`BLOCK_QUOTE(4)`/`CODE_BLOCK(5)` 段落 decorator 枚举。
- `cve.java`：菜单分发 `o(fy2)` → `m5a` 写 `MODIFY_PARAGRAPH_STYLE`
  CRDT op；段落级单选互斥；CODE_BLOCK 携 `k5a` 语言上下文。
- `lj3.java`：CODE_BLOCK 渲染缩字号 `-24f`；`sq4` monospace 字族。

## Harmony 实现

- `TextBlockOverlay.ets`：底部行新增两枚段落级切换钮（光标段落，
  再点同项取消）；`draftStyles` 段落序号键样式 + 种子/折回
  （`seedParagraphStyles`/`computeParagraphRuns`）；`onCommit` 携
  authored runs。
- `TextBlockTool.updateText`：`runs 未提供`才按 no-op 短路——
  样式-only 提交合法。
- `NoteCanvasView.onTextCommit(text, runs?)`：`stylesDiffer` 驱动
  样式级更新；三分支均携 authored runs；CRDT 仅样式走元素级 apply
  （无本地 style-op 编码器，ADR-0648 限制项）。
- `Canvas2DTextRenderer`：`decoratorStyle==5` 段落 monospace 字族
  （4 个度量/渲染/命中路径同改）+ 整行浅底带。
- 资源：`block_quote`/`code_block`（en/zh）。

## 差异（详见 ADR-0648）

- CRDT 块样式-only 提交不落 op（元素级持久化）；
- lj3 `-24f` 缩字号未移植；语言选择器/语法高亮待后续 Phase；
- rollout 旗标不复制（无条件放开）。

## 验证

- Replay `d02-original-quote-code-blocks.mjs` 32/32；
  4 个既有 fixture 因提交路径结构变化更新断言后全绿；
  全量套件全绿；`note@ohosTest`/`note@default` 双 HAP 构建成功。
- 切换交互为设备验证项（清单补遗）。
