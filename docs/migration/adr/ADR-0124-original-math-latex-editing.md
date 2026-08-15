# ADR-0124: 原版 Math LaTeX 编辑与 MODIFY_BLOCK field 10 出站

## 状态

已采纳，2026-08-12；由 Phase 234 / ADR-0211 于 2026-08-15 补全编辑器 Native 四态与预览。
本文 supersede ADR-0063 中“LaTeX 内容编辑与 MODIFY_BLOCK writer 未完成”的部分；设备像素验收边界保持不变。

## 原版证据

- `dhb` 的单 Math selection menu 分支读取 `u08.R()`，以 block operation ID 和当前 LaTeX 构造
  `x08(Edit)`。
- `v08/y22/z22` 构成固定宽度 Math editor：标题、输入区、Cancel、Done，以及 Empty/Loading/Invalid/Ok
  四态；只有 `owa(Ok)` 允许 Done。
- `n07` 的 Done 回调把当前 draft 与 `z08` 交给异步提交；外层 `u49` 使用
  `feature_note__math_editor_failed` 报告提交失败。
- `td8` field 10 是 nullable Math LaTeX setter；setter field 0 是 UTF-8 string。现有 Harmony reducer 已按
  LWW winner 将该 register 物化回 `MathElement.latex`。

## 决策

- 只有直接选择一个、且 identity 可解码的 Math 时显示 `Edit Math`。Group、多选和混合选择不显示。
- overlay 预填当前 LaTeX；Cancel 不修改任何内存、历史或数据库状态。空白进入 Empty；非法 UTF-8
  round-trip 或超过 1 MiB decoder budget 的 draft 进入 Invalid；其余 draft 先进入 Loading，再由 Native
  公式引擎的完整 bitmap render 决定 Invalid 或 Ok。只有持有当前 Ok preview、且不在提交中的状态允许 Done。
- `encodeOriginalMathLatex()` 写 type-23 的 blocks vector 和 field-10 setter string。普通编辑写 present
  string；空字符串仍允许编码，供 Undo 恢复合法的既有空 register。
- persistence classifier 只接受 identity/order 不变、恰好一个 Math 且只有 `latex` 改变的 snapshot。
  提交在一个 SQLite transaction 内完成 operation identity 分配、reducer、page revision batch、
  upload-immediate operation、canonical snapshot equality 和 persistent-history companion。
- UI 在 durable transaction 成功后才替换画布 Math 并压入 Undo 栈。失败时保留 overlay、draft 和原内存态，
  允许重试或 Cancel；不会留下会在后台意外重试的 dirty save boundary。
- Undo/Redo 的普通与 grouped history 路径复用同一 classifier/writer，因此反向 LaTeX 也生成新的原版
  type-23 operation，而不是退化为本地整页快照。

## 校验边界

Phase 149 已接入可失败关闭的 Native 公式 bitmap/layout engine，Phase 217 已恢复原版框内 fit 与编辑时几何不变，
Phase 234 又把同一引擎接入 280×96、1× 的编辑器预览与 Empty/Loading/Invalid/Ok 状态机。因此 Harmony
不再用 raw LaTeX 或静态字符串门禁冒充语法成功；只有 Native 完整绘制成功才产生 Ok。平台字体 fallback、
hinting、透明边缘、主题颜色以及极端 LaTeX 的像素一致性仍需设备验收。

## 验证

- `d02-local-math-latex-edit.mjs`、`d02-math-editing-consumer.mjs` 与
  `d02-original-math-editor-four-state.mjs` 锁定原版菜单、Native 四态、280×96 预览、Done/失败证据、
  迟到结果丢弃和 Harmony transaction/UI 接线。
- ArkTS fixture 覆盖 field-10 setter round-trip、空字符串 Undo、目标/预算拒绝、单 Math 严格 classifier、
  reverse Undo、混合字段拒绝、四态初值，以及仅 idle Ok 可 Done。
- Phase 147 与 Phase 234 总结分别记录持久化和 Native editor 闭环的全量 replay / 双 HAP 结果；未启动设备或
  Hypium。

## 后续状态

Phase 148 / ADR-0125 已完成新的 Math `CREATE_BLOCK` authoring、空 draft Insert 会话和 viewport-center
放置；Phase 149、217 与 234 已完成 Native 引擎、原版框内 fit/编辑几何和语法级 Invalid/Ok 预览。
因此本文原先隐含的 CREATE writer、公式引擎和编辑器状态边界均已关闭；剩余工作是设备上的像素、输入法、
主题切换和极端公式兼容性验收。
