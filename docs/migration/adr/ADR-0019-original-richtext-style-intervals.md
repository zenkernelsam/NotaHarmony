# ADR-0019：原版 RichText 样式区间操作

- 状态：Accepted
- 日期：2026-08-11
- 关联：D-02、数据库 v39、ADR-0018

## 原版证据

Android Notability 1.0.3 的 `haa` 将 payload 12、13、14 定义为
`MODIFY_STYLE`、`MODIFY_PARAGRAPH_STYLE` 和 `CLEAR_STYLE`；`zq9.me8`、
`zq9.he8`、`zq9.io1` 分别消费字符样式、段落样式和清除操作。样式范围使用
16-byte inline boundary：12-byte `cxc` SeqId location 加 boundary type。
`BEFORE`/`AFTER` 为 0/1，文档起止为 2/3；段落样式的 nullable SeqId 缺席时表示文档首尾。

`e4c` 识别的字符属性为 bold、italic、underline、highlight、font family、font size、
foreground、link、superscript、subscript、strikethrough；段落属性为 indent、alignment、
line spacing、decorator、programming language、writing direction。nullable wrapper 存在但
value 缺席表示单属性清除，`CLEAR_STYLE` 则清除目标范围内此前同类属性。所有样式操作按
unsigned `(timestamp, site)` 排序，较新的操作可以重新增加此前清除的属性。

## 决策

1. 数据库升至 v39，新增 `original_text_style_operation`。每条操作保留 block identity、
   operation identity、边界、paragraph/clear_all 和完整属性 wrapper 状态；外键级联删除。
2. 字符和段落样式分别物化为 code-point offset runs。样式操作本身即使最终结果为空也必须持久化，
   以便后续插入字符按稳定 SeqId 边界继承样式。
3. 样式操作先验证 textField、边界、字符树和现有 snapshot 的一致性；缺 Block、缺边界、跨 Block、
   反向范围或状态分歧整条 DEFERRED，任何写入前不产生部分结果。inbox 外层 SQLite 事务负责操作行、
   snapshot、revision、搜索状态和 APPLIED 状态的原子提交。
4. 最终样式未改变时仍保留操作记录，但不写 snapshot、不推进内容 revision；样式改变时只推进内容
   revision，不清除文本搜索索引。
5. Harmony renderer 在主画布和缩略图共用同一 `Canvas2DTextRenderer`。相同字符样式合并为连续
   `fillText` span，避免逐字符绘制造成 kerning/ZWJ 断裂；字体、颜色、高亮、上下标、下划线、删除线、
   段落缩进/对齐/装饰和行距均从 runs 消费。

## 验证边界

- `d02-richtext-style.mjs` 使用真实 `me8/he8/io1` FlatBuffer 布局，覆盖 v38→v39、字符/段落
  fold、clear 后新样式、nullable 单属性清除、稳定边界后插入、missing 原子门禁、rollback、级联和
  renderer source contract。
- `SyncedOperationInbox.test.ets` 注册真实 12/13/14 fixture，并验证 decoder 与总分发器；
  `NotePackageSpec.test.ets` 覆盖合法 runs、code-point 越界、重叠、错误类型和互斥上下标。
- `RendererStyle.test.ets` 注册离屏字符/段落样式渲染断言。31 个 D-02 replay 全部通过；clean 后
  `note@ohosTest` 与 `note@default` assembleHap 均 BUILD SUCCESSFUL，仅保留既有 warning。

本 ADR 不宣称完整 RichText layout：RTL 排版、复杂字体 shaping、自动尺寸、编辑态 TextArea/选择手柄、
IMAGE/MATH caption、Pencil/Tape/effects、NOTE_BUNDLE 内容和认证同步 transport 仍是后续阶段。
